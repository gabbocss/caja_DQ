import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Registro de un cobro para el cierre de caja (histórico / arqueo).
class RegistroPago {
  final DateTime fecha;
  final int mesaNumero;
  final String metodo;
  final double importeCobrado;
  final bool esParcial;
  final double? importeRecibido;
  final double? vuelto;
  final double pendienteRestante;
  /// `true` cuando la mesa se liberó o la cuenta se cerró.
  final bool cerrado;
  /// Sesión de caja a la que pertenece el cobro.
  final String? sesionCajaId;
  /// `true` cuando el cobro ya se incluyó en un cierre de caja.
  final bool archivadoCaja;

  const RegistroPago({
    required this.fecha,
    required this.mesaNumero,
    required this.metodo,
    required this.importeCobrado,
    required this.esParcial,
    this.importeRecibido,
    this.vuelto,
    this.pendienteRestante = 0,
    this.cerrado = false,
    this.sesionCajaId,
    this.archivadoCaja = false,
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
        if (cerrado) 'cerrado': cerrado,
        if (sesionCajaId != null) 'sesionCajaId': sesionCajaId,
        if (archivadoCaja) 'archivadoCaja': archivadoCaja,
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
        cerrado: json['cerrado'] as bool? ?? false,
        sesionCajaId: json['sesionCajaId'] as String?,
        archivadoCaja: json['archivadoCaja'] as bool? ?? false,
      );

  RegistroPago copyWith({
    bool? cerrado,
    String? sesionCajaId,
    bool? archivadoCaja,
  }) =>
      RegistroPago(
        fecha: fecha,
        mesaNumero: mesaNumero,
        metodo: metodo,
        importeCobrado: importeCobrado,
        esParcial: esParcial,
        importeRecibido: importeRecibido,
        vuelto: vuelto,
        pendienteRestante: pendienteRestante,
        cerrado: cerrado ?? this.cerrado,
        sesionCajaId: sesionCajaId ?? this.sesionCajaId,
        archivadoCaja: archivadoCaja ?? this.archivadoCaja,
      );
}

/// Persiste cobros en JSON para arqueo. El saldo vivo de la sesión está en Isar
/// ([Pedido.dineroCobradoAcumulado]), no se recalcula leyendo este archivo.
class RegistroPagoService {
  static final RegistroPagoService instance = RegistroPagoService._();
  RegistroPagoService._();

  String? _sesionCajaActivaId;

  /// Vincula cobros nuevos a la sesión de caja activa (llamado desde [CajaService]).
  void setSesionCajaActivaId(String? sesionId) {
    _sesionCajaActivaId = sesionId;
  }

  Future<String> _rutaArchivo() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbDir = Directory('${dir.path}/programa_caja_db');
    if (!await dbDir.exists()) await dbDir.create(recursive: true);
    return '${dir.path}/programa_caja_db/registros_pago.json';
  }

  Future<List<RegistroPago>> _leerTodos() async {
    try {
      final path = await _rutaArchivo();
      final file = File(path);
      if (!await file.exists()) return [];
      final raw = jsonDecode(await file.readAsString());
      if (raw is! List) return [];
      final lista = <RegistroPago>[];
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          lista.add(RegistroPago.fromJson(e));
        }
      }
      return lista;
    } catch (e) {
      debugPrint('Error leyendo registros de pago: $e');
      return [];
    }
  }

  Future<void> _guardarTodos(List<RegistroPago> lista) async {
    final path = await _rutaArchivo();
    await File(path).writeAsString(
      const JsonEncoder.withIndent('  ')
          .convert(lista.map((r) => r.toJson()).toList()),
    );
  }

  /// Marca como cerrados los cobros activos de la mesa (al liberar o cerrar cuenta).
  Future<void> archivarPagosMesa(int mesaNumero) async {
    try {
      final lista = await _leerTodos();
      var huboCambios = false;
      for (var i = 0; i < lista.length; i++) {
        final r = lista[i];
        if (r.mesaNumero == mesaNumero && !r.cerrado) {
          lista[i] = r.copyWith(cerrado: true);
          huboCambios = true;
        }
      }
      if (huboCambios) await _guardarTodos(lista);
    } catch (e) {
      debugPrint('Error archivando pagos de mesa $mesaNumero: $e');
    }
  }

  /// Desglose por método solo para UI/arqueo (cobros no archivados de la mesa).
  Future<Map<String, double>> totalesPorMetodoEnMesa(int mesaNumero) async {
    const metodos = ['efectivo', 'tarjeta', 'otros'];
    final totales = {for (final m in metodos) m: 0.0};
    try {
      final lista = await _leerTodos();
      for (final registro in lista) {
        if (registro.mesaNumero != mesaNumero || registro.cerrado) continue;
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

  /// Totales por método de cobros de una sesión de caja (no archivados).
  Future<Map<String, double>> totalesPorMetodoEnSesion(String sesionId) async {
    const metodos = ['efectivo', 'tarjeta', 'otros'];
    final totales = {for (final m in metodos) m: 0.0};
    try {
      final lista = await _leerTodos();
      for (final registro in lista) {
        if (registro.archivadoCaja) continue;
        if (registro.sesionCajaId != sesionId) continue;
        final metodo = registro.metodo.toLowerCase();
        if (totales.containsKey(metodo)) {
          totales[metodo] = totales[metodo]! + registro.importeCobrado;
        }
      }
    } catch (e) {
      debugPrint('Error leyendo totales por sesión de caja: $e');
    }
    return totales;
  }

  /// Asigna a la sesión los cobros sin sesión que aún no están archivados.
  Future<void> asignarPagosHuerfanosASesion(String sesionId) async {
    try {
      final lista = await _leerTodos();
      var huboCambios = false;
      for (var i = 0; i < lista.length; i++) {
        final r = lista[i];
        if (!r.archivadoCaja && r.sesionCajaId == null) {
          lista[i] = r.copyWith(sesionCajaId: sesionId);
          huboCambios = true;
        }
      }
      if (huboCambios) await _guardarTodos(lista);
    } catch (e) {
      debugPrint('Error asignando pagos huérfanos a sesión $sesionId: $e');
    }
  }

  /// Marca como archivados los cobros de una sesión tras el cierre de caja.
  Future<void> archivarPagosSesion(String sesionId) async {
    try {
      final lista = await _leerTodos();
      var huboCambios = false;
      for (var i = 0; i < lista.length; i++) {
        final r = lista[i];
        if (r.sesionCajaId == sesionId && !r.archivadoCaja) {
          lista[i] = r.copyWith(archivadoCaja: true);
          huboCambios = true;
        }
      }
      if (huboCambios) await _guardarTodos(lista);
    } catch (e) {
      debugPrint('Error archivando pagos de sesión $sesionId: $e');
    }
  }

  Future<void> registrar(RegistroPago registro) async {
    try {
      final conSesion = registro.sesionCajaId != null
          ? registro
          : registro.copyWith(sesionCajaId: _sesionCajaActivaId);
      final lista = await _leerTodos();
      lista.add(conSesion);
      await _guardarTodos(lista);
    } catch (e) {
      debugPrint('Error al registrar pago en caja: $e');
    }
  }
}
