import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/registro_pago_service.dart';
import '../domain/entities/caja_resumen_sesion.dart';
import '../domain/entities/cierre_caja.dart';
import '../domain/entities/conteo_efectivo.dart';
import '../domain/entities/retiro_caja.dart';
import '../domain/entities/sesion_caja.dart';

/// Gestión de sesiones de caja, fondo inicial, retiros y cierres.
class CajaService {
  static final CajaService instance = CajaService._();
  CajaService._();

  static const _uuid = Uuid();

  SesionCaja? _sesionEnMemoria;

  /// ID de la sesión activa para etiquetar cobros.
  String? get sesionActivaId =>
      _sesionEnMemoria != null && !_sesionEnMemoria!.cerrada
          ? _sesionEnMemoria!.id
          : null;

  Future<String> _dirDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbDir = Directory('${dir.path}/programa_caja_db');
    if (!await dbDir.exists()) await dbDir.create(recursive: true);
    return dbDir.path;
  }

  Future<String> _rutaSesionActiva() async =>
      '${await _dirDb()}/sesion_caja_activa.json';

  Future<String> _rutaCierres() async =>
      '${await _dirDb()}/cierres_caja.json';

  Future<SesionCaja?> obtenerSesionActiva() async {
    if (_sesionEnMemoria != null && !_sesionEnMemoria!.cerrada) {
      return _sesionEnMemoria;
    }
    try {
      final path = await _rutaSesionActiva();
      final file = File(path);
      if (!await file.exists()) {
        _sesionEnMemoria = null;
        return null;
      }
      final raw = jsonDecode(await file.readAsString());
      if (raw is! Map<String, dynamic>) return null;
      final sesion = SesionCaja.fromJson(raw);
      if (sesion.cerrada) {
        _sesionEnMemoria = null;
        return null;
      }
      _sesionEnMemoria = sesion;
      RegistroPagoService.instance.setSesionCajaActivaId(sesion.id);
      return sesion;
    } catch (e) {
      debugPrint('Error leyendo sesión de caja: $e');
      return null;
    }
  }

  Future<void> _guardarSesionActiva(SesionCaja? sesion) async {
    final path = await _rutaSesionActiva();
    final file = File(path);
    if (sesion == null || sesion.cerrada) {
      _sesionEnMemoria = null;
      RegistroPagoService.instance.setSesionCajaActivaId(null);
      if (await file.exists()) await file.delete();
      return;
    }
    _sesionEnMemoria = sesion;
    RegistroPagoService.instance.setSesionCajaActivaId(sesion.id);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(sesion.toJson()),
    );
  }

  Future<List<CierreCaja>> obtenerHistorialCierres() async {
    try {
      final path = await _rutaCierres();
      final file = File(path);
      if (!await file.exists()) return [];
      final raw = jsonDecode(await file.readAsString());
      if (raw is! List) return [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(CierreCaja.fromJson)
          .toList()
        ..sort((a, b) => b.cerradoEn.compareTo(a.cerradoEn));
    } catch (e) {
      debugPrint('Error leyendo historial de cierres: $e');
      return [];
    }
  }

  Future<void> _guardarCierre(CierreCaja cierre) async {
    final lista = await obtenerHistorialCierres();
    lista.insert(0, cierre);
    final path = await _rutaCierres();
    await File(path).writeAsString(
      const JsonEncoder.withIndent('  ')
          .convert(lista.map((c) => c.toJson()).toList()),
    );
  }

  /// Abre una sesión nueva con el fondo inicial contado.
  Future<SesionCaja> abrirSesionConFondo(ConteoEfectivo fondo) async {
    final activa = await obtenerSesionActiva();
    if (activa != null) {
      throw StateError(
        'Ya hay una sesión de caja abierta. Ciérrala antes de abrir otra.',
      );
    }
    final sesion = SesionCaja(
      id: _uuid.v4(),
      abiertaEn: DateTime.now(),
      fondoInicial: fondo,
    );
    await _guardarSesionActiva(sesion);
    await RegistroPagoService.instance.asignarPagosHuerfanosASesion(sesion.id);
    return sesion;
  }

  /// Actualiza el fondo de la sesión activa (si aún no se ha cerrado).
  Future<SesionCaja> actualizarFondoInicial(ConteoEfectivo fondo) async {
    final activa = await obtenerSesionActiva();
    if (activa == null) {
      return abrirSesionConFondo(fondo);
    }
    final actualizada = activa.copyWith(fondoInicial: fondo);
    await _guardarSesionActiva(actualizada);
    return actualizada;
  }

  Future<SesionCaja> registrarRetiro({
    required double importe,
    required String motivo,
  }) async {
    final activa = await obtenerSesionActiva();
    if (activa == null) {
      throw StateError(
        'No hay sesión de caja abierta. Añade la caja del día primero.',
      );
    }
    if (importe <= 0) {
      throw ArgumentError('El importe del retiro debe ser mayor que cero.');
    }
    final retiro = RetiroCaja(
      id: _uuid.v4(),
      fecha: DateTime.now(),
      importe: importe,
      motivo: motivo.trim(),
    );
    final actualizada = activa.copyWith(
      retiros: [...activa.retiros, retiro],
    );
    await _guardarSesionActiva(actualizada);
    return actualizada;
  }

  /// Totales de cobros en efectivo y otros de la sesión activa.
  Future<({double efectivo, double otros})> totalesCobrosSesion(
    String sesionId,
  ) async {
    final totales =
        await RegistroPagoService.instance.totalesPorMetodoEnSesion(sesionId);
    return (
      efectivo: totales['efectivo'] ?? 0,
      otros: totales['otros'] ?? 0,
    );
  }

  /// Calcula el total esperado en caja para la sesión activa.
  Future<double> calcularTotalEsperado(SesionCaja sesion) async {
    final cobros = await totalesCobrosSesion(sesion.id);
    return sesion.totalFondoInicial +
        cobros.efectivo +
        cobros.otros -
        sesion.totalRetiros;
  }

  /// Resumen para mostrar antes del cierre.
  Future<CajaResumenSesion> obtenerResumenSesion() async {
    final sesion = await obtenerSesionActiva();
    if (sesion == null) {
      return const CajaResumenSesion(
        tieneSesion: false,
        tieneFondo: false,
        fondoInicial: 0,
        totalEfectivo: 0,
        totalOtros: 0,
        totalRetiros: 0,
        totalEsperado: 0,
        retiros: [],
      );
    }
    final cobros = await totalesCobrosSesion(sesion.id);
    final esperado = sesion.totalFondoInicial +
        cobros.efectivo +
        cobros.otros -
        sesion.totalRetiros;
    return CajaResumenSesion(
      tieneSesion: true,
      tieneFondo: sesion.tieneFondoInicial,
      fondoInicial: sesion.totalFondoInicial,
      totalEfectivo: cobros.efectivo,
      totalOtros: cobros.otros,
      totalRetiros: sesion.totalRetiros,
      totalEsperado: esperado,
      retiros: sesion.retiros,
      sesion: sesion,
    );
  }

  /// Cierra la sesión activa, guarda el histórico y deja lista una nueva apertura.
  Future<CierreCaja> cerrarSesion({
    required ConteoEfectivo conteoFisico,
    required bool cuadra,
  }) async {
    final sesion = await obtenerSesionActiva();
    if (sesion == null) {
      throw StateError('No hay sesión de caja abierta para cerrar.');
    }

    final cobros = await totalesCobrosSesion(sesion.id);
    final totalEsperado = sesion.totalFondoInicial +
        cobros.efectivo +
        cobros.otros -
        sesion.totalRetiros;
    final fisico = conteoFisico.total;
    final diferencia = fisico - totalEsperado;

    final cierre = CierreCaja(
      id: _uuid.v4(),
      sesionId: sesion.id,
      cerradoEn: DateTime.now(),
      fondoInicial: sesion.totalFondoInicial,
      totalEfectivo: cobros.efectivo,
      totalOtros: cobros.otros,
      totalRetiros: sesion.totalRetiros,
      totalEsperado: totalEsperado,
      conteoFisico: fisico,
      diferencia: diferencia,
      cuadra: cuadra,
      detalleConteoFisico: conteoFisico,
    );

    await _guardarCierre(cierre);
    await RegistroPagoService.instance.archivarPagosSesion(sesion.id);
    await _guardarSesionActiva(null);
    return cierre;
  }
}
