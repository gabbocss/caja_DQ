import 'package:flutter/foundation.dart';

import '../models/reserva.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../prefs/reservas_central_prefs.dart';
import 'reserva_persistence_service.dart';

/// Resultado de una sincronización con el servidor central 24/7.
class ReservaSyncResult {
  final bool exito;
  final int descargadas;
  final String? error;
  final bool usoBackupLocal;

  const ReservaSyncResult({
    required this.exito,
    this.descargadas = 0,
    this.error,
    this.usoBackupLocal = false,
  });
}

/// Descarga reservas del servidor remoto y las persiste en Isar + JSON local.
class ReservaSyncService {
  static final ReservaSyncService instance = ReservaSyncService._();
  ReservaSyncService._();

  final ReservaPersistenceService _persistencia =
      ReservaPersistenceService.instance;

  /// Sincroniza al arrancar la caja (martes por la mañana, etc.).
  Future<ReservaSyncResult> sincronizarAlInicio() async {
    final url = await getReservasCentralUrlEfectiva();
    if (url == null || url.isEmpty) {
      debugPrint(
        'Reservas: sin URL central configurada; se usará backup local si existe.',
      );
      final locales = await _persistencia.obtenerReservasPendientesConFallback();
      return ReservaSyncResult(
        exito: true,
        descargadas: locales.length,
        usoBackupLocal: true,
      );
    }
    return sincronizarDesdeRemoto(url);
  }

  Future<ReservaSyncResult> sincronizarDesdeRemoto(String baseUrl) async {
    try {
      final client = ApiClient(baseUrl);
      if (!await client.verificarApiProgramaCaja()) {
        client.dispose();
        throw Exception(
          'La URL $baseUrl no expone la API de programa_caja (GET /api). '
          'En el servidor 24/7 debe ejecutarse la misma app con LocalServer '
          'y la ruta ${ApiEndpoints.reservas}.',
        );
      }
      final remotas = await client.obtenerReservasPendientes();
      client.dispose();
      await _persistencia.fusionarReservasRemotas(remotas);
      debugPrint('✅ Reservas sincronizadas: ${remotas.length} desde $baseUrl');
      return ReservaSyncResult(exito: true, descargadas: remotas.length);
    } catch (e, st) {
      debugPrint('⚠️ Fallo sync reservas remoto: $e\n$st');
      final locales = await _persistencia.obtenerReservasPendientesConFallback();
      return ReservaSyncResult(
        exito: false,
        descargadas: locales.length,
        error: e.toString(),
        usoBackupLocal: true,
      );
    }
  }
}
