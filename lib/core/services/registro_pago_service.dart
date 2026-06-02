import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Registro de un cobro para el cierre de caja.
class RegistroPago {
  final DateTime fecha;
  final int mesaNumero;
  final String metodo;
  final double importeCobrado;
  final bool esParcial;
  final double? importeRecibido;
  final double? vuelto;
  final double pendienteRestante;

  const RegistroPago({
    required this.fecha,
    required this.mesaNumero,
    required this.metodo,
    required this.importeCobrado,
    required this.esParcial,
    this.importeRecibido,
    this.vuelto,
    this.pendienteRestante = 0,
  });

  Map<String, dynamic> toJson() => {
        'fecha': fecha.toIso8601String(),
        'mesaNumero': mesaNumero,
        'metodo': metodo,
        'importeCobrado': importeCobrado,
        'esParcial': esParcial,
        'importeRecibido': importeRecibido,
        'vuelto': vuelto,
        'pendienteRestante': pendienteRestante,
      };

  factory RegistroPago.fromJson(Map<String, dynamic> json) => RegistroPago(
        fecha: DateTime.parse(json['fecha'] as String),
        mesaNumero: json['mesaNumero'] as int,
        metodo: json['metodo'] as String,
        importeCobrado: (json['importeCobrado'] as num).toDouble(),
        esParcial: json['esParcial'] as bool? ?? false,
        importeRecibido: (json['importeRecibido'] as num?)?.toDouble(),
        vuelto: (json['vuelto'] as num?)?.toDouble(),
        pendienteRestante: (json['pendienteRestante'] as num?)?.toDouble() ?? 0,
      );
}

/// Persiste cobros en JSON para el arqueo / cierre de caja.
class RegistroPagoService {
  static final RegistroPagoService instance = RegistroPagoService._();
  RegistroPagoService._();

  Future<String> _rutaArchivo() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbDir = Directory('${dir.path}/programa_caja_db');
    if (!await dbDir.exists()) await dbDir.create(recursive: true);
    return '${dir.path}/programa_caja_db/registros_pago.json';
  }

  /// Suma cobros de la mesa por método (`efectivo`, `tarjeta`, `otros`).
  /// Si [desde] no es null, solo cuenta pagos de esa sesión en adelante.
  Future<Map<String, double>> totalesPorMetodoEnMesa(
    int mesaNumero, {
    DateTime? desde,
  }) async {
    const metodos = ['efectivo', 'tarjeta', 'otros'];
    final totales = {for (final m in metodos) m: 0.0};
    try {
      final path = await _rutaArchivo();
      final file = File(path);
      if (!await file.exists()) return totales;
      final raw = jsonDecode(await file.readAsString());
      if (raw is! List) return totales;
      for (final e in raw) {
        if (e is! Map<String, dynamic>) continue;
        final registro = RegistroPago.fromJson(e);
        if (registro.mesaNumero != mesaNumero) continue;
        if (desde != null && registro.fecha.isBefore(desde)) continue;
        final metodo = registro.metodo.toLowerCase();
        if (totales.containsKey(metodo)) {
          totales[metodo] = totales[metodo]! + registro.importeCobrado;
        }
      }
    } catch (e) {
      debugPrint('Error leyendo totales por método: $e');
    }
    return totales;
  }

  Future<void> registrar(RegistroPago registro) async {
    try {
      final path = await _rutaArchivo();
      final file = File(path);
      final lista = <RegistroPago>[];
      if (await file.exists()) {
        final raw = jsonDecode(await file.readAsString());
        if (raw is List) {
          for (final e in raw) {
            if (e is Map<String, dynamic>) {
              lista.add(RegistroPago.fromJson(e));
            }
          }
        }
      }
      lista.add(registro);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(lista.map((r) => r.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Error al registrar pago en caja: $e');
    }
  }
}
