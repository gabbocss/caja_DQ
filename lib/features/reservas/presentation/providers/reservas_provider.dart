import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/core.dart';
import '../../../../core/prefs/reservas_central_prefs.dart';
import '../../../../core/services/reserva_carta_cache_service.dart';
import '../../../../core/services/reserva_outbox_service.dart';
import '../../../../core/services/reserva_persistence_service.dart';
import '../../../../core/services/reserva_sync_service.dart';
import '../../data/services/reserva_asignacion_service.dart';
import '../../data/services/reserva_cobro_asporto_service.dart';

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
  final _cartaCache = ReservaCartaCacheService.instance;

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

  DateTime _diaAgenda = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  List<Reserva> _reservasDelDia = [];

  DateTime get diaAgenda => _diaAgenda;
  List<Reserva> get reservasDelDia => _reservasDelDia;

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
      await _sincronizarSoloReservasCaja();
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
    _pendientesServidor = [];
    notifyListeners();
    try {
      await getReservasCentralUrl();
      await _actualizarColaLocal();
      _productos = await _cartaCache.cargar();
      await _actualizarPendientesServidor();
      _actualizarAvisoCartaAndroid();
    } catch (e) {
      _error = e.toString();
      await _actualizarColaLocal();
      _productos = await _cartaCache.cargar();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  void _actualizarAvisoCartaAndroid() {
    if (_colaEnvio.isNotEmpty) {
      _error =
          '${_colaEnvio.length} reserva(s) pendientes de envío. Pulsa sync para reenviar.';
      return;
    }
    if (_productos.isEmpty) {
      _error = 'Pulsa sync para cargar la carta de platos desde el VPS.';
      return;
    }
    _error = null;
  }

  Future<void> _cargarProductosDesdeVpsYCachear() async {
    final client = await _clienteVps();
    try {
      if (!await client.verificarApiProgramaCaja()) {
        throw Exception(
          'El VPS no expone la API esperada (reservas y productos en GET /api).',
        );
      }
      final productos = await client.obtenerProductos();
      await _cartaCache.guardar(productos);
      _productos = productos;
    } finally {
      client.dispose();
    }
  }

  /// Al abrir Reservas en caja: solo pull de reservas (el catálogo se sube desde Productos).
  Future<void> _sincronizarSoloReservasCaja() async {
    _sincronizando = true;
    _error = null;
    notifyListeners();
    final result = await _sync.sincronizarSoloReservasAlInicio();
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
        await _cargarProductosDesdeVpsYCachear();
      } catch (e) {
        debugPrint('Reserva Android sync carta: $e');
        if (_productos.isEmpty) {
          _productos = await _cartaCache.cargar();
        }
        _error = 'No se pudo actualizar la carta: $e';
      }

      final enviados = await _intentarReenviarCola();
      await _actualizarColaLocal();
      await _actualizarPendientesServidor();

      if (enviados > 0 && _colaEnvio.isEmpty) {
        _error = null;
      } else if (_colaEnvio.isNotEmpty) {
        _error =
            '${_colaEnvio.length} reserva(s) siguen pendientes de envío al VPS.';
      } else if (_productos.isEmpty) {
        _actualizarAvisoCartaAndroid();
      } else {
        _error = null;
      }
    } catch (e) {
      _error = e.toString();
      await _actualizarColaLocal();
    } finally {
      _sincronizando = false;
      notifyListeners();
    }
  }

  Future<void> _actualizarColaLocal() async {
    _colaEnvio = await _outbox.listar();
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
    if (!_esAndroidNube) {
      await _recargarAgendaDelDia();
    }
  }

  Future<void> _recargarAgendaDelDia() async {
    _reservasDelDia = await _persistencia.obtenerReservasDelDia(_diaAgenda);
  }

  Future<void> irDiaAnteriorAgenda() async {
    _diaAgenda = _diaAgenda.subtract(const Duration(days: 1));
    await _recargarAgendaDelDia();
    notifyListeners();
  }

  Future<void> irDiaSiguienteAgenda() async {
    _diaAgenda = _diaAgenda.add(const Duration(days: 1));
    await _recargarAgendaDelDia();
    notifyListeners();
  }

  Future<void> establecerDiaAgenda(DateTime dia) async {
    _diaAgenda = DateTime(dia.year, dia.month, dia.day);
    await _recargarAgendaDelDia();
    notifyListeners();
  }

  Future<void> actualizarReserva({
    required int id,
    required String nombreCliente,
    required int numeroPersonas,
    required DateTime fechaHoraLlegada,
    required String alergiasNotas,
    required List<ItemReserva> itemsReservados,
  }) async {
    if (_esAndroidNube) {
      await _actualizarReservaAndroidNube(
        id: id,
        nombreCliente: nombreCliente,
        numeroPersonas: numeroPersonas,
        fechaHoraLlegada: fechaHoraLlegada,
        alergiasNotas: alergiasNotas,
        itemsReservados: itemsReservados,
      );
      return;
    }
    final existente = await _persistencia.obtenerPorId(id);
    if (existente == null) {
      throw StateError('Reserva no encontrada');
    }
    existente
      ..nombreCliente = nombreCliente.trim()
      ..numeroPersonas = numeroPersonas
      ..fechaHoraLlegada = fechaHoraLlegada
      ..alergiasNotas = alergiasNotas.trim()
      ..itemsReservados = List<ItemReserva>.from(itemsReservados)
      ..fechaActualizacion = DateTime.now();
    await _persistencia.guardarReserva(existente);
    await _publicarRemota(existente);
    await _recargarLocal();
    notifyListeners();
  }

  /// Actualiza una reserva pendiente en el VPS (app Android).
  Future<void> _actualizarReservaAndroidNube({
    required int id,
    required String nombreCliente,
    required int numeroPersonas,
    required DateTime fechaHoraLlegada,
    required String alergiasNotas,
    required List<ItemReserva> itemsReservados,
  }) async {
    if (id <= 0) {
      throw StateError(
        'Esa reserva aún no está en el VPS. Envíala primero o edítala cuando tenga id.',
      );
    }
    Reserva? existente = _pendientesServidor
        .where((r) => r.id == id)
        .firstOrNull;
    if (existente == null) {
      await _actualizarPendientesServidor();
      existente = _pendientesServidor.where((r) => r.id == id).firstOrNull;
    }
    if (existente == null) {
      throw StateError('Reserva no encontrada en el servidor');
    }
    if (!existente.estaPendiente) {
      throw StateError('Solo se pueden editar reservas pendientes');
    }

    final actualizada = Reserva.fromJson(existente.toJson())
      ..nombreCliente = nombreCliente.trim()
      ..numeroPersonas = numeroPersonas
      ..fechaHoraLlegada = fechaHoraLlegada
      ..alergiasNotas = alergiasNotas.trim()
      ..itemsReservados = List<ItemReserva>.from(itemsReservados)
      ..fechaActualizacion = DateTime.now();

    final client = await _clienteVps();
    try {
      if (!await client.verificarApiProgramaCaja()) {
        throw Exception('No se pudo contactar con la API de reservas en el VPS');
      }
      await client.guardarReserva(actualizada);
    } finally {
      client.dispose();
    }
    await _actualizarPendientesServidor();
    notifyListeners();
  }

  /// Cancela la reserva (estado cancelada; no se borra del histórico).
  Future<void> eliminarReserva(int id) async {
    if (_esAndroidNube) {
      await _eliminarReservaAndroidNube(id);
      return;
    }
    final existente = await _persistencia.obtenerPorId(id);
    if (existente == null) {
      throw StateError('Reserva no encontrada');
    }
    existente
      ..estado = EstadoReserva.cancelada
      ..fechaActualizacion = DateTime.now();
    await _persistencia.guardarReserva(existente);

    final url = await getReservasCentralUrlEfectiva();
    if (url != null && url.isNotEmpty) {
      try {
        final client = ApiClient(url);
        if (await client.verificarApiProgramaCaja()) {
          await client.actualizarEstadoReserva(
            id: id,
            estado: EstadoReserva.cancelada,
          );
        }
        client.dispose();
      } catch (e) {
        debugPrint('Reserva cancelada en local; VPS no actualizado: $e');
      }
    }
    await _recargarLocal();
    notifyListeners();
  }

  /// Cancela la reserva en el VPS (app Android).
  Future<void> _eliminarReservaAndroidNube(int id) async {
    if (id <= 0) {
      throw StateError('No se puede cancelar una reserva que aún no está en el VPS');
    }
    final client = await _clienteVps();
    try {
      if (!await client.verificarApiProgramaCaja()) {
        throw Exception('No se pudo contactar con la API de reservas en el VPS');
      }
      await client.actualizarEstadoReserva(
        id: id,
        estado: EstadoReserva.cancelada,
      );
    } finally {
      client.dispose();
    }
    await _actualizarPendientesServidor();
    notifyListeners();
  }

  /// Reactiva una reserva cancelada (vuelve a pendiente).
  Future<void> reactivarReserva(int id) async {
    if (_esAndroidNube) {
      await _reactivarReservaAndroidNube(id);
      return;
    }
    final existente = await _persistencia.obtenerPorId(id);
    if (existente == null) {
      throw StateError('Reserva no encontrada');
    }
    if (existente.estado != EstadoReserva.cancelada) {
      throw StateError('Solo se pueden reactivar reservas canceladas');
    }
    existente
      ..estado = EstadoReserva.pendiente
      ..mesaAsignada = null
      ..fechaActualizacion = DateTime.now();
    await _persistencia.guardarReserva(existente);

    final url = await getReservasCentralUrlEfectiva();
    if (url != null && url.isNotEmpty) {
      try {
        final client = ApiClient(url);
        if (await client.verificarApiProgramaCaja()) {
          await client.actualizarEstadoReserva(
            id: id,
            estado: EstadoReserva.pendiente,
          );
        }
        client.dispose();
      } catch (e) {
        debugPrint('Reserva reactivada en local; VPS no actualizado: $e');
      }
    }
    await _recargarLocal();
    notifyListeners();
  }

  Future<void> _reactivarReservaAndroidNube(int id) async {
    if (id <= 0) {
      throw StateError('No se puede reactivar una reserva que aún no está en el VPS');
    }
    final client = await _clienteVps();
    try {
      if (!await client.verificarApiProgramaCaja()) {
        throw Exception('No se pudo contactar con la API de reservas en el VPS');
      }
      await client.actualizarEstadoReserva(
        id: id,
        estado: EstadoReserva.pendiente,
      );
    } finally {
      client.dispose();
    }
    await _actualizarPendientesServidor();
    notifyListeners();
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
        _pendientesServidor = _esAndroidNube
            ? await client.obtenerReservasEditables()
            : await client.obtenerReservasPendientes();
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
      await _actualizarColaLocal();
      _actualizarAvisoCartaAndroid();
      notifyListeners();
      return CrearReservaResultado.enviadaAlVps;
    } catch (e) {
      await _outbox.encolar(reserva, ultimoError: e.toString());
      await _actualizarColaLocal();
      _actualizarAvisoCartaAndroid();
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
    if (reserva.estado == EstadoReserva.cancelada || !reserva.estaPendiente) {
      throw StateError('No se puede asignar mesa a una reserva cancelada');
    }
    await _asignacion.asignarMesa(reserva: reserva, mesaNumero: mesaNumero);
    _mesas = await DatabaseService.instance.obtenerMesas();
    await _recargarLocal();
    notifyListeners();
  }

  /// Cobra un asporto pendiente (registro caja + ticket + estado cobrada).
  Future<void> cobrarAsporto({
    required Reserva reserva,
    required String metodo,
    double? importeRecibido,
  }) async {
    if (_esAndroidNube) {
      throw StateError(
        'Cobrar asporto solo está disponible en la caja de escritorio.',
      );
    }
    await ReservaCobroAsportoService.instance.cobrar(
      reserva: reserva,
      metodo: metodo,
      importeRecibido: importeRecibido,
    );
    await _recargarLocal();
    notifyListeners();
  }
}
