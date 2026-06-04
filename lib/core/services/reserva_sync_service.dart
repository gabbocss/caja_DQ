import 'package:flutter/foundation.dart';

import '../database/database_service.dart';
import '../models/reserva.dart';
import '../network/api_client.dart';
import '../prefs/reservas_central_prefs.dart';
import 'reserva_persistence_service.dart';

/// Resultado de una sincronización con el servidor central 24/7.
class ReservaSyncResult {
  final bool exito;
  final int descargadas;
  final int productosSubidos;
  final String? error;
  final bool usoBackupLocal;

  const ReservaSyncResult({
    required this.exito,
    this.descargadas = 0,
    this.productosSubidos = 0,
    this.error,
    this.usoBackupLocal = false,
  });
}

/// Descarga reservas del servidor remoto y sube el catálogo desde la caja (Isar).
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

  /// Solo descarga reservas del VPS (sin subir catálogo). Para entrar en Reservas en caja.
  Future<ReservaSyncResult> sincronizarSoloReservasAlInicio() async {
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
    try {
      final remotas = await descargarSoloReservasDesdeRemoto(url);
      return ReservaSyncResult(
        exito: true,
        descargadas: remotas.length,
      );
    } catch (e, st) {
      debugPrint('⚠️ Fallo sync solo reservas: $e\n$st');
      final locales = await _persistencia.obtenerReservasPendientesConFallback();
      return ReservaSyncResult(
        exito: false,
        descargadas: locales.length,
        error: e.toString(),
        usoBackupLocal: true,
      );
    }
  }

  /// Sube el catálogo de Isar al VPS usando la URL configurada.
  Future<int> subirCatalogoAlVpsDesdePrefs() async {
    final url = await getReservasCentralUrlEfectiva();
    if (url == null || url.isEmpty) {
      throw Exception(
        'Configura la URL del servidor central de reservas (VPS).',
      );
    }
    final n = await subirCatalogoProductosAlVps(url);
    debugPrint('✅ Catálogo subido al VPS: $n productos');
    return n;
  }

  /// Sube todos los productos de Isar al VPS y descarga reservas pendientes.
  Future<ReservaSyncResult> sincronizarDesdeRemoto(String baseUrl) async {
    var productosSubidos = 0;
    String? errorCatalogo;

    try {
      final client = ApiClient(baseUrl);
      if (!await client.verificarApiProgramaCaja()) {
        client.dispose();
        throw Exception(
          'La URL $baseUrl no expone la API de programa_caja (GET /api). '
          'Debe incluir endpoints reservas y productos.',
        );
      }

      try {
        productosSubidos = await subirCatalogoProductosAlVps(baseUrl, client: client);
        debugPrint('✅ Catálogo subido al VPS: $productosSubidos productos');
      } catch (e, st) {
        errorCatalogo = 'Catálogo: $e';
        debugPrint('⚠️ Fallo subida catálogo al VPS: $e\n$st');
      }

      final remotas = await client.obtenerReservasPendientes();
      client.dispose();
      await _persistencia.fusionarReservasRemotas(remotas);
      debugPrint('✅ Reservas sincronizadas: ${remotas.length} desde $baseUrl');

      if (errorCatalogo != null) {
        return ReservaSyncResult(
          exito: false,
          descargadas: remotas.length,
          productosSubidos: productosSubidos,
          error: errorCatalogo,
          usoBackupLocal: false,
        );
      }
      return ReservaSyncResult(
        exito: true,
        descargadas: remotas.length,
        productosSubidos: productosSubidos,
      );
    } catch (e, st) {
      debugPrint('⚠️ Fallo sync reservas remoto: $e\n$st');
      final locales = await _persistencia.obtenerReservasPendientesConFallback();
      return ReservaSyncResult(
        exito: false,
        descargadas: locales.length,
        productosSubidos: productosSubidos,
        error: errorCatalogo ?? e.toString(),
        usoBackupLocal: true,
      );
    }
  }

  /// Solo descarga reservas del VPS, fusiona en Isar y devuelve la lista remota.
  Future<List<Reserva>> descargarSoloReservasDesdeRemoto(String baseUrl) async {
    final client = ApiClient(baseUrl);
    try {
      if (!await client.verificarApiProgramaCaja()) {
        throw Exception(
          'La URL $baseUrl no expone la API de reservas (GET /api).',
        );
      }
      final remotas = await client.obtenerReservasPendientes();
      await _persistencia.fusionarReservasRemotas(remotas);
      debugPrint('✅ Reservas VPS (pull): ${remotas.length} desde $baseUrl');
      return remotas;
    } catch (e, st) {
      debugPrint('⚠️ Fallo pull reservas VPS: $e\n$st');
      rethrow;
    } finally {
      client.dispose();
    }
  }

  /// Lee productos de Isar y los publica en el servidor central (POST /api/productos).
  Future<int> subirCatalogoProductosAlVps(
    String baseUrl, {
    ApiClient? client,
  }) async {
    final productos = await DatabaseService.instance.obtenerProductos();
    final ownClient = client ?? ApiClient(baseUrl);
    final disposeOwn = client == null;
    try {
      return await ownClient.subirCatalogoProductos(productos);
    } finally {
      if (disposeOwn) ownClient.dispose();
    }
  }
}
