/// Supermercado del catálogo (VPS). Más adelante los productos podrán
/// referenciar [id] con un campo supermercadoId.
class Supermercado {
  final int id;
  final String nombre;
  final int orden;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  const Supermercado({
    required this.id,
    required this.nombre,
    this.orden = 0,
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  factory Supermercado.fromJson(Map<String, dynamic> json) {
    return Supermercado(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nombre: (json['nombre'] as String?)?.trim() ?? '',
      orden: (json['orden'] as num?)?.toInt() ?? 0,
      fechaCreacion: _parseFecha(json['fechaCreacion']),
      fechaActualizacion: _parseFecha(json['fechaActualizacion']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id > 0) 'id': id,
        'nombre': nombre,
        'orden': orden,
      };

  Supermercado copyWith({
    int? id,
    String? nombre,
    int? orden,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return Supermercado(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      orden: orden ?? this.orden,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  static DateTime? _parseFecha(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
