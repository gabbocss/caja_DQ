import 'dart:async';

import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../database/database_service_web.dart'
    if (dart.library.io) '../database/database_service.dart';
import '../di/injection_container.dart' show isServer, sl;
import '../models/reserva.dart';
import '../prefs/reservas_central_prefs.dart';
import '../utils/platform_utils.dart';
import 'lista_paellas_auto_service.dart';
import 'reserva_sync_service.dart';

/// Polling del VPS de reservas en la caja (Windows/Linux).
///
/// Corre cada [AppConstants.reservasVpsPollingSeconds] con la app abierta,
/// en cualquier pestaña y también en segundo plano (no se pausa al minimizar).
class ReservaVpsPollingService extends ChangeNotifier {
  static final ReservaVpsPollingService instance =
      ReservaVpsPollingService._();
  ReservaVpsPollingService._();

  Timer? _timer;
  bool _activo = false;
  bool _tickEnCurso = false;

  List<Reserva> _reservasEnServidor = [];
  String? _ultimoError;
  DateTime? _ultimaOk;

  bool get estaActivo => _activo;
  List<Reserva> get reservasEnServidor =>
      List.unmodifiable(_reservasEnServidor);
  String? get ultimoError => _ultimoError;
  DateTime? get ultimaActualizacionOk => _ultimaOk;

  /// Arranca el timer en la instancia caja (idempotente).
  void iniciarEnCaja() {
    if (kIsWeb || PlatformUtils.isMobile || !PlatformUtils.shouldActAsServer) {
      return;
    }
    if (!isServer) return;
    if (_activo) return;

    _activo = true;
    debugPrint(
      'ReservaVpsPolling: activo cada ${AppConstants.reservasVpsPollingSeconds}s '
      '(incluye segundo plano)',
    );
    _timer = Timer.periodic(
      Duration(seconds: AppConstants.reservasVpsPollingSeconds),
      (_) => _tick(),
    );
    unawaited(_tick());
  }

  void detener() {
    _timer?.cancel();
    _timer = null;
    _activo = false;
  }

  /// Fuerza un ciclo (p. ej. tras guardar la URL del VPS en configuración).
  Future<void> refrescarAhora() => _tick();

  Future<void> _tick() async {
    if (_tickEnCurso) return;
    if (!sl.isRegistered<DatabaseService>()) return;

    _tickEnCurso = true;
    try {
      final url = await getReservasCentralUrlEfectiva();
      if (url == null || url.isEmpty) {
        _ultimoError = 'Sin URL del servidor central de reservas';
        notifyListeners();
        return;
      }

      final remotas =
          await ReservaSyncService.instance.descargarSoloReservasDesdeRemoto(url);
      _reservasEnServidor = remotas;
      _ultimoError = null;
      _ultimaOk = DateTime.now();
      notifyListeners();
      // Tras sync OK: lista paellas 1h antes (con catch-up si se encendió tarde).
      unawaited(ListaPaellasAutoService.instance.evaluarTrasSync());
    } catch (e, st) {
      _ultimoError = e.toString();
      debugPrint('ReservaVpsPolling: $e\n$st');
      notifyListeners();
    } finally {
      _tickEnCurso = false;
    }
  }
}
