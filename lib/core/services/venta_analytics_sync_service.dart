import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/pedido.dart';
import '../network/api_client.dart';
import '../prefs/horarios_reservas_prefs.dart';
import '../prefs/reservas_central_prefs.dart';

/// Payload de una venta cerrada para el VPS (fase 3).
class VentaAnalyticsPayload {
  final String idempotencyKey;
  final DateTime fechaCierre;
  final String servicio;
  final String origen;
  final int? clienteId;
  final int? reservaId;
  final int? mesaNumero;
  final int? comensales;
  final int? duracionMinutos;
  final double total;
  final bool esBuffet;
  final List<Map<String, dynamic>> items;

  const VentaAnalyticsPayload({
    required this.idempotencyKey,
    required this.fechaCierre,
    required this.servicio,
    required this.origen,
    required this.total,
    required this.esBuffet,
    required this.items,
    this.clienteId,
    this.reservaId,
    this.mesaNumero,
    this.comensales,
    this.duracionMinutos,
  });

  Map<String, dynamic> toJson() => {
        'idempotencyKey': idempotencyKey,
        'fechaCierre': fechaCierre.toIso8601String(),
        'servicio': servicio,
        'origen': origen,
        if (clienteId != null) 'clienteId': clienteId,
        if (reservaId != null) 'reservaId': reservaId,
        if (mesaNumero != null) 'mesaNumero': mesaNumero,
        if (comensales != null) 'comensales': comensales,
        if (duracionMinutos != null) 'duracionMinutos': duracionMinutos,
        'total': total,
        'esBuffet': esBuffet,
        'items': items,
      };

  factory VentaAnalyticsPayload.fromJson(Map<String, dynamic> json) {
    return VentaAnalyticsPayload(
      idempotencyKey: json['idempotencyKey'] as String,
      fechaCierre: DateTime.parse(json['fechaCierre'] as String),
      servicio: json['servicio'] as String? ?? 'otro',
      origen: json['origen'] as String? ?? 'walkin',
      clienteId: json['clienteId'] as int?,
      reservaId: json['reservaId'] as int?,
      mesaNumero: json['mesaNumero'] as int?,
      comensales: json['comensales'] as int?,
      duracionMinutos: json['duracionMinutos'] as int?,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      esBuffet: json['esBuffet'] as bool? ?? false,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
    );
  }
}

/// Envía cierres de mesa/asporto al VPS; cola local si no hay red.
class VentaAnalyticsSyncService {
  static final VentaAnalyticsSyncService instance =
      VentaAnalyticsSyncService._();
  VentaAnalyticsSyncService._();

  static const _archivo = 'ventas_analytics_outbox.json';
  final _uuid = const Uuid();
  bool _flushEnCurso = false;

  Future<String> _rutaArchivo() async {
    final dir = await getApplicationDocumentsDirectory();
    final carpeta = Directory('${dir.path}/programa_caja_db');
    if (!await carpeta.exists()) {
      await carpeta.create(recursive: true);
    }
    return '${carpeta.path}/$_archivo';
  }

  Future<List<VentaAnalyticsPayload>> _leerCola() async {
    try {
      final file = File(await _rutaArchivo());
      if (!await file.exists()) return [];
      final raw = jsonDecode(await file.readAsString());
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((e) => VentaAnalyticsPayload.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList();
    } catch (e) {
      debugPrint('VentaAnalytics: error leyendo cola: $e');
      return [];
    }
  }

  Future<void> _guardarCola(List<VentaAnalyticsPayload> cola) async {
    final file = File(await _rutaArchivo());
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(
        cola.map((e) => e.toJson()).toList(),
      ),
    );
  }

  Future<void> _encolar(VentaAnalyticsPayload payload) async {
    final cola = await _leerCola();
    if (cola.any((e) => e.idempotencyKey == payload.idempotencyKey)) return;
    cola.add(payload);
    await _guardarCola(cola);
  }

  /// Clasifica comida/cena según horarios de reservas.
  Future<String> _servicioPara(DateTime cuando) async {
    final h = await getHorariosReservas();
    final minutos = cuando.hour * 60 + cuando.minute;
    bool enRango(int inicio, int fin) {
      if (inicio <= fin) return minutos >= inicio && minutos <= fin;
      return minutos >= inicio || minutos <= fin;
    }

    if (enRango(h.comidaInicioMin, h.comidaFinMin)) return 'comida';
    if (enRango(h.cenaInicioMin, h.cenaFinMin)) return 'cena';
    if (minutos < h.cenaInicioMin) return 'comida';
    return 'cena';
  }

  /// Agrega pedidos abiertos de una mesa en una sola venta y la envía/encola.
  Future<void> registrarCierreMesa({
    required List<Pedido> pedidos,
    required int mesaNumero,
    bool esBuffetClose = false,
  }) async {
    if (pedidos.isEmpty) return;

    final ahora = DateTime.now();
    final itemsAgg = <String, Map<String, dynamic>>{};
    var total = 0.0;
    var comensales = 0;
    DateTime? inicio;
    int? reservaId;
    int? clienteId;
    var esBuffet = esBuffetClose;
    var origen = 'walkin';
    var tieneQr = false;
    var tieneWeb = false;

    for (final p in pedidos) {
      total += p.total;
      if (p.numeroComensales != null && p.numeroComensales! > comensales) {
        comensales = p.numeroComensales!;
      }
      if (inicio == null || p.fechaCreacion.isBefore(inicio)) {
        inicio = p.fechaCreacion;
      }
      reservaId ??= p.reservaId;
      clienteId ??= p.clienteId;
      if (p.esBuffet) esBuffet = true;
      if (p.origen == OrigenPedido.qr) tieneQr = true;
      if (p.origen == OrigenPedido.web) tieneWeb = true;
      for (final it in p.items) {
        final key =
            '${it.productoId}|${it.nombreProducto}|${it.precioUnitario}';
        final prev = itemsAgg[key];
        if (prev == null) {
          itemsAgg[key] = {
            'productoId': it.productoId,
            'nombreProducto': it.nombreProducto,
            'cantidad': it.cantidad,
            'precioUnitario': it.precioUnitario,
          };
        } else {
          prev['cantidad'] = (prev['cantidad'] as int) + it.cantidad;
        }
      }
    }

    if (reservaId != null) {
      origen = 'reserva';
    } else if (tieneQr) {
      origen = 'qr';
    } else if (tieneWeb) {
      origen = 'web';
    }

    final duracion = inicio == null
        ? null
        : ahora.difference(inicio).inMinutes.clamp(0, 24 * 60);

    final payload = VentaAnalyticsPayload(
      idempotencyKey: _uuid.v4(),
      fechaCierre: ahora,
      servicio: await _servicioPara(ahora),
      origen: origen,
      clienteId: clienteId,
      reservaId: reservaId,
      mesaNumero: mesaNumero,
      comensales: comensales > 0 ? comensales : null,
      duracionMinutos: duracion,
      total: total,
      esBuffet: esBuffet,
      items: itemsAgg.values.toList(),
    );

    await _enviarOEncolar(payload);
  }

  Future<void> registrarAsporto({
    required Pedido pedido,
  }) async {
    final ahora = pedido.fechaCompletado ?? DateTime.now();
    final payload = VentaAnalyticsPayload(
      idempotencyKey: _uuid.v4(),
      fechaCierre: ahora,
      servicio: await _servicioPara(ahora),
      origen: 'asporto',
      clienteId: pedido.clienteId,
      reservaId: pedido.reservaId,
      mesaNumero: 0,
      comensales: 0,
      duracionMinutos: 0,
      total: pedido.total,
      esBuffet: false,
      items: pedido.items
          .map(
            (it) => {
              'productoId': it.productoId,
              'nombreProducto': it.nombreProducto,
              'cantidad': it.cantidad,
              'precioUnitario': it.precioUnitario,
            },
          )
          .toList(),
    );
    await _enviarOEncolar(payload);
  }

  Future<void> _enviarOEncolar(VentaAnalyticsPayload payload) async {
    final ok = await _intentarEnviar(payload);
    if (!ok) {
      await _encolar(payload);
      debugPrint(
        'VentaAnalytics: encolada ${payload.idempotencyKey} '
        '(sin VPS o error de red)',
      );
    }
    unawaited(flushCola());
  }

  Future<bool> _intentarEnviar(VentaAnalyticsPayload payload) async {
    final url = await getReservasCentralUrlEfectiva();
    if (url == null || url.isEmpty) return false;
    final client = ApiClient(url);
    try {
      if (!await client.verificarApiProgramaCaja()) return false;
      await client.enviarVentaAnalytics(payload.toJson());
      return true;
    } catch (e) {
      debugPrint('VentaAnalytics: fallo envío: $e');
      return false;
    } finally {
      client.dispose();
    }
  }

  /// Reenvía la cola pendiente (llamar al arrancar caja o tras cobros).
  Future<void> flushCola() async {
    if (_flushEnCurso) return;
    _flushEnCurso = true;
    try {
      final cola = await _leerCola();
      if (cola.isEmpty) return;
      final restantes = <VentaAnalyticsPayload>[];
      for (final p in cola) {
        final ok = await _intentarEnviar(p);
        if (!ok) restantes.add(p);
      }
      await _guardarCola(restantes);
    } finally {
      _flushEnCurso = false;
    }
  }
}
