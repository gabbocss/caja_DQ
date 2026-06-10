import 'conteo_efectivo.dart';

/// Registro histórico de un cierre de caja.
class CierreCaja {
  final String id;
  final String sesionId;
  final DateTime cerradoEn;
  final double fondoInicial;
  final double totalEfectivo;
  final double totalOtros;
  final double totalRetiros;
  final double totalEsperado;
  final double conteoFisico;
  final double diferencia;
  final bool cuadra;
  final ConteoEfectivo? detalleConteoFisico;

  const CierreCaja({
    required this.id,
    required this.sesionId,
    required this.cerradoEn,
    required this.fondoInicial,
    required this.totalEfectivo,
    required this.totalOtros,
    required this.totalRetiros,
    required this.totalEsperado,
    required this.conteoFisico,
    required this.diferencia,
    required this.cuadra,
    this.detalleConteoFisico,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sesionId': sesionId,
        'cerradoEn': cerradoEn.toIso8601String(),
        'fondoInicial': fondoInicial,
        'totalEfectivo': totalEfectivo,
        'totalOtros': totalOtros,
        'totalRetiros': totalRetiros,
        'totalEsperado': totalEsperado,
        'conteoFisico': conteoFisico,
        'diferencia': diferencia,
        'cuadra': cuadra,
        if (detalleConteoFisico != null)
          'detalleConteoFisico': detalleConteoFisico!.toJson(),
      };

  factory CierreCaja.fromJson(Map<String, dynamic> json) => CierreCaja(
        id: json['id'] as String,
        sesionId: json['sesionId'] as String,
        cerradoEn: DateTime.parse(json['cerradoEn'] as String),
        fondoInicial: (json['fondoInicial'] as num).toDouble(),
        totalEfectivo: (json['totalEfectivo'] as num).toDouble(),
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
      );
}
