import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../database/database_service.dart';
import '../models/reserva.dart';

/// Persistencia de reservas: Isar (principal) + espejo JSON (fallback offline).
class ReservaPersistenceService {
  static final ReservaPersistenceService instance =
      ReservaPersistenceService._();
  ReservaPersistenceService._();

  static const _nombreBackup = 'reservas_backup.json';

  DatabaseService get _db => DatabaseService.instance;

  /// ~/Documentos/programa_caja_db/reservas_backup.json en Linux/desktop.
  Future<String> rutaBackup() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbDir = Directory('${dir.path}/programa_caja_db');
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    return '${dbDir.path}/$_nombreBackup';
  }

  Future<void> guardarReserva(Reserva reserva) async {
    reserva.fechaActualizacion = DateTime.now();
    if (_db.isInitialized) {
      reserva.id = await _db.guardarReserva(reserva);
    }
    await _refrescarBackupJson();
  }

  Future<Reserva?> obtenerPorId(int id) async {
    if (_db.isInitialized) {
      return _db.obtenerReservaPorId(id);
    }
    for (final r in await leerDesdeBackupJson()) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Pendientes con degradación a JSON si Isar no está disponible.
  Future<List<Reserva>> obtenerReservasPendientesConFallback() async {
    try {
      if (_db.isInitialized) {
        return await _db.obtenerReservasPendientes();
      }
    } catch (e, st) {
      debugPrint('Isar reservas no disponible, usando backup JSON: $e\n$st');
    }
    return (await leerDesdeBackupJson())
        .where((r) => r.estado == EstadoReserva.pendiente)
        .toList()
      ..sort((a, b) => a.fechaHoraLlegada.compareTo(b.fechaHoraLlegada));
  }

  Future<List<Reserva>> obtenerReservasPendientes() async {
    if (_db.isInitialized) {
      return _db.obtenerReservasPendientes();
    }
    return obtenerReservasPendientesConFallback();
  }

  Future<List<Reserva>> obtenerReservasDelDia(DateTime dia) async {
    if (_db.isInitialized) {
      return _db.obtenerReservasDelDia(dia);
    }
    final inicio = DateTime(dia.year, dia.month, dia.day);
    final fin = inicio.add(const Duration(days: 1));
    return (await leerDesdeBackupJson())
        .where(
          (r) =>
              !r.fechaHoraLlegada.isBefore(inicio) &&
              r.fechaHoraLlegada.isBefore(fin),
        )
        .toList()
      ..sort((a, b) => a.fechaHoraLlegada.compareTo(b.fechaHoraLlegada));
  }

  Future<bool> eliminarReserva(int id) async {
    var ok = false;
    if (_db.isInitialized) {
      ok = await _db.eliminarReserva(id);
    }
    await _refrescarBackupJson();
    return ok;
  }

  /// Inserta/actualiza reservas del VPS sin borrar el histórico local (sentadas, canceladas, etc.).
  Future<void> fusionarReservasRemotas(List<Reserva> remotas) async {
    if (_db.isInitialized) {
      await _db.fusionarReservasRemotas(remotas);
    } else {
      await escribirBackupJson(remotas);
      return;
    }
    await _refrescarBackupJson();
  }

  Future<void> _refrescarBackupJson() async {
    if (!_db.isInitialized) return;
    final todas = await _db.obtenerTodasReservas();
    await escribirBackupJson(todas);
  }

  Future<void> escribirBackupJson(List<Reserva> reservas) async {
    try {
      final path = await rutaBackup();
      final payload = reservas.map((r) => r.toJson()).toList();
      await File(path).writeAsString(
        const JsonEncoder.withIndent('  ').convert(payload),
      );
      debugPrint('Backup reservas: ${reservas.length} en $path');
    } catch (e) {
      debugPrint('Error escribiendo backup reservas: $e');
    }
  }

  Future<List<Reserva>> leerDesdeBackupJson() async {
    try {
      final path = await rutaBackup();
      final file = File(path);
      if (!await file.exists()) return [];
      final raw = jsonDecode(await file.readAsString());
      if (raw is! List) return [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(Reserva.fromJson)
          .toList();
    } catch (e) {
      debugPrint('Error leyendo backup reservas: $e');
      return [];
    }
  }
}
