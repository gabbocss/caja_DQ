import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/core.dart';
import '../../../../core/prefs/reservas_central_prefs.dart';
import '../../../../core/services/reserva_outbox_service.dart';
import '../../../../core/services/reserva_persistence_service.dart';
import '../../../../core/services/reserva_sync_service.dart';
import '../../data/services/reserva_asignacion_service.dart';

/// Resultado al crear una reserva en móvil (VPS o cola offline).
enum CrearReservaResultado {
  enviadaAlVps,
  guardadaParaEnvio,
}

/// Estado de la pantalla de reservas pendientes.
class ReservasProvider extends ChangeNotifier {
  final _persistencia = ReservaPersistenceService.instance;
  final _sync = ReservaSyncService.instance;
  final _asignacion = ReservaAsignacionService.instance;
  final _outbox = ReservaOutboxService.instance;

  List<Reserva> _pendientesLocales = [];
  List<Reserva> _pendientesServidor = [];
  List<ReservaOutboxEntry> _colaEnvio = [];
  List<Producto> _productos = [];
  List<Mesa> _mesas = [];
  bool _cargando = false;
  bool _sincronizando = false;
  String? _error;
  bool _modoBackup = false;

  /// Reservas en el teléfono aún no enviadas al VPS (cola offline).
  List<Reserva> get pendientesPorEnviar =>
      _colaEnvio.map(_reservaParaVistaDesdeCola).toList();

  /// Pendientes en el servidor central (GET /api/reservas).
  List<Reserva> get reservasEnServidor => _pendientesServidor;

  /// Pendientes en la caja local (solo escritorio / Isar).
  List<Reserva> get pendientesCaja => _pendientesLocales;

  int get colaEnvioCount => _colaEnvio.length;
  int get reservasEnServidorCount => _pendientesServidor.length;

  bool pendienteDeEnvio(Reserva r) => r.id != null && r.id! < 0;

  List<Producto> get productos => _productos;
  List<Mesa> get mesas => _mesas;
  bool get cargando => _cargando;
  bool get sincronizando => _sincronizando;
  String? get error => _error;
  bool get modoBackup => _modoBackup;

  bool get _esAndroidNube => PlatformUtils.isAndroid;
  bool _pollingVinculado = false;

  Reserva _reservaParaVistaDesdeCola(ReservaOutboxEntry e) {
    final json = e.reserva.toJson();
    json.remove('id');
    final r = Reserva.fromJson(json);
    r.id = -e.localId.hashCode;
    return r;
  }

  Future<String> _urlVpsOError() async {
    final url = await getReservasCentralUrl();
    if (url == null || url.isEmpty) {
      throw StateError(
        'Configura la URL del servidor central de reservas en la pestaña Servidor.',
      );
    }
    return url;
  }

  Future<ApiClient> _clienteVps() async {
    return ApiClient(await _urlVpsOError());
  }

  Future<void> inicializar() async {
    if (_esAndroidNube) {
      await _inicializarAndroidNube();
      return;
    }

    _cargando = true;
    notifyListeners();
    try {
      _vincularPollingCaja();
      final db = DatabaseService.instance;
      _productos = await db.obtenerProductos();
      _mesas = await db.obtenerMesas();
      await sincronizar();
    } catch (e) {
      _error = e.toString();
      await _recargarLocal();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> _inicializarAndroidNube() async {
    _cargando = true;
    _modoBackup = false;
    _error = null;
    _mesas = [];
    notifyListeners();
    try {
      await getReservasCentralUrl();
      _colaEnvio = await _outbox.listar();
      try {
        await _cargarProductosDesdeVps();
      } catch (e) {
        _error =
            'Sin conexión al VPS para la carta. Las reservas en cola se enviarán al reconectar.';
        debugPrint('Reservas Android: carta VPS: $e');
      }
      await _refrescarPendientesAndroid(intentarReenvio: true);
    } catch (e) {
      _error = e.toString();
      _colaEnvio = await _outbox.listar();
      _pendientesServidor = [];
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> _cargarProductosDesdeVps() async {
    final client = await _clienteVps();
    try {
      if (!await client.verificarApiProgramaCaja()) {
        throw Exception(
          'El VPS no expone la API esperada (reservas y productos en GET /api).',
        );
      }
      _productos = await client.obtenerProductos();
    } finally {
      client.dispose();
    }
  }

  Future<void> sincronizar() async {
    if (_esAndroidNube) {
      await _sincronizarAndroidNube();
      return;
    }

    _sincronizando = true;
    _error = null;
    notifyListeners();
    final result = await _sync.sincronizarAlInicio();
    _modoBackup = result.usoBackupLocal;
    if (!result.exito && result.error != null) {
      _error = result.error;
    }
    await _recargarLocal();
    if (ReservaVpsPollingService.instance.estaActivo) {
      await ReservaVpsPollingService.instance.refrescarAhora();
    } else {
      await _actualizarPendientesServidor();
    }
    _sincronizando = false;
    notifyListeners();
  }

  Future<void> _sincronizarAndroidNube() async {
    _sincronizando = true;
    _error = null;
    notifyListeners();
    try {
      try {
        await _cargarProductosDesdeVps();
      } catch (e) {
        debugPrint('Reservas Android sync carta: $e');
      }
      await _refrescarPendientesAndroid(intentarReenvio: true);
    } catch (e) {
      _error = e.toString();
      _colaEnvio = await _outbox.listar();
    } finally {
      _sincronizando = false;
      notifyListeners();
    }
  }

  /// Reenvía cola, actualiza lista local y descarga pendientes del VPS.
  Future<void> _refrescarPendientesAndroid({required bool intentarReenvio}) async {
    _colaEnvio = await _outbox.listar();

    if (intentarReenvio && _colaEnvio.isNotEmpty) {
      await _intentarReenviarCola();
      _colaEnvio = await _outbox.listar();
    }

    try {
      final client = await _clienteVps();
      try {
        if (await client.verificarApiProgramaCaja()) {
          _pendientesServidor = await client.obtenerReservasPendientes();
          if (_colaEnvio.isEmpty) _error = null;
        }
      } finally {
        client.dispose();
      }
    } catch (e) {
      debugPrint('Reservas Android: listar VPS: $e');
      _pendientesServidor = [];
      if (_colaEnvio.isNotEmpty) {
        _error = _colaEnvio.isNotEmpty
            ? '${_colaEnvio.length} reserva(s) esperan conexión al VPS.'
            : e.toString();
      }
    }
  }

  Future<int> _intentarReenviarCola() async {
    var enviados = 0;
    ApiClient? client;
    try {
      client = await _clienteVps();
      if (!await client.verificarApiProgramaCaja()) return 0;

      for (final entry in await _outbox.listar()) {
        try {
          await client.guardarReserva(entry.reserva);
          await _outbox.eliminar(entry.localId);
          enviados++;
          debugPrint('ReservaOutbox: enviada ${entry.localId}');
        } catch (e) {
          await _outbox.actualizarError(entry.localId, e.toString());
          debugPrint('ReservaOutbox: fallo reenvío ${entry.localId}: $e');
        }
      }
    } catch (e) {
      debugPrint('ReservaOutbox: sin VPS para reenvío: $e');
    } finally {
      client?.dispose();
    }
    return enviados;
  }

  Future<void> _recargarLocal() async {
    _pendientesLocales =
        await _persistencia.obtenerReservasPendientesConFallback();
  }

  void _vincularPollingCaja() {
    if (_esAndroidNube || _pollingVinculado) return;
    ReservaVpsPollingService.instance.addListener(_onActualizacionPollingVps);
    _pollingVinculado = true;
    unawaited(_aplicarDatosPollingVps());
  }

  void desmontar() {
    if (!_pollingVinculado) return;
    ReservaVpsPollingService.instance.removeListener(_onActualizacionPollingVps);
    _pollingVinculado = false;
  }

  void _onActualizacionPollingVps() {
    unawaited(_aplicarDatosPollingVps());
  }

  Future<void> _aplicarDatosPollingVps() async {
    if (_esAndroidNube) return;
    _pendientesServidor = List.from(
      ReservaVpsPollingService.instance.reservasEnServidor,
    );
    await _recargarLocal();
    notifyListeners();
  }

  Future<void> _actualizarPendientesServidor() async {
    if (!_esAndroidNube && ReservaVpsPollingService.instance.estaActivo) {
      _pendientesServidor = List.from(
        ReservaVpsPollingService.instance.reservasEnServidor,
      );
      return;
    }
    final url = await getReservasCentralUrlEfectiva();
    if (url == null || url.isEmpty) {
      _pendientesServidor = [];
      return;
    }
    ApiClient? client;
    try {
      client = ApiClient(url);
      if (await client.verificarApiProgramaCaja()) {
        _pendientesServidor = await client.obtenerReservasPendientes();
      }
    } catch (e) {
      debugPrint('Reservas: listar pendientes en servidor: $e');
    } finally {
      client?.dispose();
    }
  }

  Future<CrearReservaResultado> crearReserva({
    required String nombreCliente,
    required int numeroPersonas,
    required DateTime fechaHoraLlegada,
    required String alergiasNotas,
    required List<ItemReserva> itemsReservados,
  }) async {
    if (_esAndroidNube) {
      return _crearReservaAndroidNube(
        nombreCliente: nombreCliente,
        numeroPersonas: numeroPersonas,
        fechaHoraLlegada: fechaHoraLlegada,
        alergiasNotas: alergiasNotas,
        itemsReservados: itemsReservados,
      );
    }

    final reserva = Reserva.crear(
      nombreCliente: nombreCliente.trim(),
      numeroPersonas: numeroPersonas,
      fechaHoraLlegada: fechaHoraLlegada,
      alergiasNotas: alergiasNotas.trim(),
      itemsReservados: itemsReservados,
    );
    await _persistencia.guardarReserva(reserva);
    await _publicarRemota(reserva);
    await _recargarLocal();
    notifyListeners();
    return CrearReservaResultado.enviadaAlVps;
  }

  Future<CrearReservaResultado> _crearReservaAndroidNube({
    required String nombreCliente,
    required int numeroPersonas,
    required DateTime fechaHoraLlegada,
    required String alergiasNotas,
    required List<ItemReserva> itemsReservados,
  }) async {
    final reserva = Reserva.crear(
      nombreCliente: nombreCliente.trim(),
      numeroPersonas: numeroPersonas,
      fechaHoraLlegada: fechaHoraLlegada,
      alergiasNotas: alergiasNotas.trim(),
      itemsReservados: itemsReservados,
    );

    try {
      final client = await _clienteVps();
      try {
        if (!await client.verificarApiProgramaCaja()) {
          throw Exception('No se pudo contactar con la API de reservas en el VPS');
        }
        await client.guardarReserva(reserva);
      } finally {
        client.dispose();
      }
      await _refrescarPendientesAndroid(intentarReenvio: false);
      notifyListeners();
      return CrearReservaResultado.enviadaAlVps;
    } catch (e) {
      await _outbox.encolar(reserva, ultimoError: e.toString());
      await _refrescarPendientesAndroid(intentarReenvio: false);
      notifyListeners();
      return CrearReservaResultado.guardadaParaEnvio;
    }
  }

  Future<void> _publicarRemota(Reserva reserva) async {
    final url = await getReservasCentralUrlEfectiva();
    if (url == null) return;
    try {
      final client = ApiClient(url);
      await client.guardarReserva(reserva);
      client.dispose();
    } catch (e) {
      debugPrint('Reserva guardada localmente; remoto no disponible: $e');
    }
  }

  Future<void> asignarMesa({
    required Reserva reserva,
    required int mesaNumero,
  }) async {
    if (_esAndroidNube) {
      throw StateError(
        'Asignar mesa a una reserva solo está disponible en la caja de escritorio.',
      );
    }
    await _asignacion.asignarMesa(reserva: reserva, mesaNumero: mesaNumero);
    _mesas = await DatabaseService.instance.obtenerMesas();
    await _recargarLocal();
    notifyListeners();
  }
}
