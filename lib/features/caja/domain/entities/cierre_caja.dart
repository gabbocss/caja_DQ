import 'conteo_efectivo.dart';
import 'movimiento_caja.dart';

/// Registro histórico de un cierre de caja.
class CierreCaja {
  final String id;
  final String sesionId;
  final DateTime cerradoEn;
  final DateTime? abiertaEn;
  final double fondoInicial;
  final double totalEfectivo;
  final double totalTarjeta;
  final double totalOtros;
  final double totalRetiros;
  final double totalEsperado;
  final double conteoFisico;
  final double diferencia;
  final bool cuadra;
  final ConteoEfectivo? detalleConteoFisico;
  /// Log completo de movimientos del día (apertura, cobros, retiros, cierre).
  final List<MovimientoCaja> movimientos;

  const CierreCaja({
    required this.id,
    required this.sesionId,
    required this.cerradoEn,
    this.abiertaEn,
    required this.fondoInicial,
    required this.totalEfectivo,
    this.totalTarjeta = 0,
    required this.totalOtros,
    required this.totalRetiros,
    required this.totalEsperado,
    required this.conteoFisico,
    required this.diferencia,
    required this.cuadra,
    this.detalleConteoFisico,
    this.movimientos = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sesionId': sesionId,
        'cerradoEn': cerradoEn.toIso8601String(),
        if (abiertaEn != null) 'abiertaEn': abiertaEn!.toIso8601String(),
        'fondoInicial': fondoInicial,
        'totalEfectivo': totalEfectivo,
        'totalTarjeta': totalTarjeta,
        'totalOtros': totalOtros,
        'totalRetiros': totalRetiros,
        'totalEsperado': totalEsperado,
        'conteoFisico': conteoFisico,
        'diferencia': diferencia,
        'cuadra': cuadra,
        if (detalleConteoFisico != null)
          'detalleConteoFisico': detalleConteoFisico!.toJson(),
        if (movimientos.isNotEmpty)
          'movimientos': movimientos.map((m) => m.toJson()).toList(),
      };

  factory CierreCaja.fromJson(Map<String, dynamic> json) => CierreCaja(
        id: json['id'] as String,
        sesionId: json['sesionId'] as String,
        cerradoEn: DateTime.parse(json['cerradoEn'] as String),
        abiertaEn: json['abiertaEn'] != null
            ? DateTime.parse(json['abiertaEn'] as String)
            : null,
        fondoInicial: (json['fondoInicial'] as num).toDouble(),
        totalEfectivo: (json['totalEfectivo'] as num).toDouble(),
        totalTarjeta: (json['totalTarjeta'] as num?)?.toDouble() ?? 0,
        totalOtros: (json['totalOtros'] as num).toDouble(),
        totalRetiros: (json['totalRetiros'] as num).toDouble(),
        totalEsperado: (json['totalEsperado'] as num).toDouble(),
        conteoFisico: (json['conteoFisico'] as num).toDouble(),
        diferencia: (json['diferencia'] as num).toDouble(),
        cuadra: json['cuadra'] as bool? ?? false,
        detalleConteoFisico: json['detalleConteoFisico'] != null
            ? ConteoEfectivo.fromJson(
                json['detalleConteoFisico'] as Map<String, dynamic>,
              )
            : null,
        movimientos: (json['movimientos'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(MovimientoCaja.fromJson)
            .toList(),
      );
}
