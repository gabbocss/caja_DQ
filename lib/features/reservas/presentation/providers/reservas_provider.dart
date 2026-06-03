import 'package:flutter/foundation.dart';

import '../../../../core/core.dart';
import '../../../../core/prefs/reservas_central_prefs.dart';
import '../../../../core/services/reserva_persistence_service.dart';
import '../../../../core/services/reserva_sync_service.dart';
import '../../data/services/reserva_asignacion_service.dart';

/// Estado de la pantalla de reservas pendientes.
class ReservasProvider extends ChangeNotifier {
  final _persistencia = ReservaPersistenceService.instance;
  final _sync = ReservaSyncService.instance;
  final _asignacion = ReservaAsignacionService.instance;

  List<Reserva> _pendientes = [];
  List<Producto> _productos = [];
  List<Mesa> _mesas = [];
  bool _cargando = false;
  bool _sincronizando = false;
  String? _error;
  bool _modoBackup = false;

  List<Reserva> get pendientes => _pendientes;
  List<Producto> get productos => _productos;
  List<Mesa> get mesas => _mesas;
  bool get cargando => _cargando;
  bool get sincronizando => _sincronizando;
  String? get error => _error;
  bool get modoBackup => _modoBackup;

  Future<void> inicializar() async {
    _cargando = true;
    notifyListeners();
    try {
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

  Future<void> sincronizar() async {
    _sincronizando = true;
    _error = null;
    notifyListeners();
    final result = await _sync.sincronizarAlInicio();
    _modoBackup = result.usoBackupLocal;
    if (!result.exito && result.error != null) {
      _error = result.error;
    }
    await _recargarLocal();
    _sincronizando = false;
    notifyListeners();
  }

  Future<void> _recargarLocal() async {
    _pendientes =
        await _persistencia.obtenerReservasPendientesConFallback();
  }

  Future<void> crearReserva({
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
    await _persistencia.guardarReserva(reserva);
    await _publicarRemota(reserva);
    await _recargarLocal();
    notifyListeners();
  }

  Future<void> _publicarRemota(Reserva reserva) async {
    final url = await getReservasCentralUrlEfectiva();
    if (url == null || reserva.id == null) return;
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
    await _asignacion.asignarMesa(reserva: reserva, mesaNumero: mesaNumero);
    _mesas = await DatabaseService.instance.obtenerMesas();
    await _recargarLocal();
    notifyListeners();
  }
}
