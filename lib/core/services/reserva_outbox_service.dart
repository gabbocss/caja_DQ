import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/reserva.dart';

/// Reserva creada en móvil sin conexión al VPS; se reenvía al recuperar red.
class ReservaOutboxEntry {
  final String localId;
  final Reserva reserva;
  final DateTime creadoEn;
  final String? ultimoError;

  const ReservaOutboxEntry({
    required this.localId,
    required this.reserva,
    required this.creadoEn,
    this.ultimoError,
  });

  Map<String, dynamic> toJson() => {
        'localId': localId,
        'creadoEn': creadoEn.toIso8601String(),
        if (ultimoError != null) 'ultimoError': ultimoError,
        'reserva': reserva.toJson(),
      };

  factory ReservaOutboxEntry.fromJson(Map<String, dynamic> json) {
    return ReservaOutboxEntry(
      localId: json['localId'] as String,
      reserva: Reserva.fromJson(json['reserva'] as Map<String, dynamic>),
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      ultimoError: json['ultimoError'] as String?,
    );
  }
}

/// Cola persistente de reservas pendientes de envío al VPS (Android / sin Isar).
class ReservaOutboxService {
  static final ReservaOutboxService instance = ReservaOutboxService._();
  ReservaOutboxService._();

  static const _archivo = 'reservas_outbox_android.json';
  final _uuid = const Uuid();

  Future<String> _rutaArchivo() async {
    final dir = await getApplicationDocumentsDirectory();
    final carpeta = Directory('${dir.path}/programa_caja_db');
    if (!await carpeta.exists()) {
      await carpeta.create(recursive: true);
    }
    return '${carpeta.path}/$_archivo';
  }

  Future<List<ReservaOutboxEntry>> listar() async {
    try {
      final path = await _rutaArchivo();
      final file = File(path);
      if (!await file.exists()) return [];
      final raw = jsonDecode(await file.readAsString());
      if (raw is! List) return [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(ReservaOutboxEntry.fromJson)
          .toList()
        ..sort((a, b) => a.creadoEn.compareTo(b.creadoEn));
    } catch (e) {
      debugPrint('ReservaOutbox: error leyendo cola: $e');
      return [];
    }
  }

  Future<void> _guardarLista(List<ReservaOutboxEntry> entries) async {
    final path = await _rutaArchivo();
    final payload = entries.map((e) => e.toJson()).toList();
    await File(path).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    debugPrint('ReservaOutbox: ${entries.length} en cola ($path)');
  }

  Future<String> encolar(Reserva reserva, {String? ultimoError}) async {
    final entries = await listar();
    final localId = _uuid.v4();
    entries.add(
      ReservaOutboxEntry(
        localId: localId,
        reserva: reserva,
        creadoEn: DateTime.now(),
        ultimoError: ultimoError,
      ),
    );
    await _guardarLista(entries);
    return localId;
  }

  Future<void> eliminar(String localId) async {
    final entries = await listar();
    entries.removeWhere((e) => e.localId == localId);
    await _guardarLista(entries);
  }

  Future<void> actualizarError(String localId, String error) async {
    final entries = await listar();
    final idx = entries.indexWhere((e) => e.localId == localId);
    if (idx < 0) return;
    final prev = entries[idx];
    entries[idx] = ReservaOutboxEntry(
      localId: prev.localId,
      reserva: prev.reserva,
      creadoEn: prev.creadoEn,
      ultimoError: error,
    );
    await _guardarLista(entries);
  }
}
