/// Dinero retirado de la caja durante una sesión.
class RetiroCaja {
  final String id;
  final DateTime fecha;
  final double importe;
  final String motivo;

  const RetiroCaja({
    required this.id,
    required this.fecha,
    required this.importe,
    required this.motivo,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fecha': fecha.toIso8601String(),
        'importe': importe,
        'motivo': motivo,
      };

  factory RetiroCaja.fromJson(Map<String, dynamic> json) => RetiroCaja(
        id: json['id'] as String,
        fecha: DateTime.parse(json['fecha'] as String),
        importe: (json['importe'] as num).toDouble(),
        motivo: json['motivo'] as String? ?? '',
      );
}
