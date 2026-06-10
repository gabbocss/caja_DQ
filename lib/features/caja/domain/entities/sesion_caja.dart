import 'conteo_efectivo.dart';
import 'retiro_caja.dart';

/// Sesión de caja activa o cerrada (un turno entre apertura y cierre).
class SesionCaja {
  final String id;
  final DateTime abiertaEn;
  final ConteoEfectivo? fondoInicial;
  final List<RetiroCaja> retiros;
  final bool cerrada;

  const SesionCaja({
    required this.id,
    required this.abiertaEn,
    this.fondoInicial,
    this.retiros = const [],
    this.cerrada = false,
  });

  bool get tieneFondoInicial =>
      fondoInicial != null && !fondoInicial!.estaVacio;

  double get totalFondoInicial => fondoInicial?.total ?? 0;

  double get totalRetiros =>
      retiros.fold(0.0, (suma, r) => suma + r.importe);

  Map<String, dynamic> toJson() => {
        'id': id,
        'abiertaEn': abiertaEn.toIso8601String(),
        if (fondoInicial != null) 'fondoInicial': fondoInicial!.toJson(),
        'retiros': retiros.map((r) => r.toJson()).toList(),
        'cerrada': cerrada,
      };

  factory SesionCaja.fromJson(Map<String, dynamic> json) => SesionCaja(
        id: json['id'] as String,
        abiertaEn: DateTime.parse(json['abiertaEn'] as String),
        fondoInicial: json['fondoInicial'] != null
            ? ConteoEfectivo.fromJson(
                json['fondoInicial'] as Map<String, dynamic>,
              )
            : null,
        retiros: (json['retiros'] as List<dynamic>? ?? [])
            .map((e) => RetiroCaja.fromJson(e as Map<String, dynamic>))
            .toList(),
        cerrada: json['cerrada'] as bool? ?? false,
      );

  SesionCaja copyWith({
    ConteoEfectivo? fondoInicial,
    List<RetiroCaja>? retiros,
    bool? cerrada,
  }) =>
      SesionCaja(
        id: id,
        abiertaEn: abiertaEn,
        fondoInicial: fondoInicial ?? this.fondoInicial,
        retiros: retiros ?? this.retiros,
        cerrada: cerrada ?? this.cerrada,
      );
}
