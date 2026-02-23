/// Versión del modelo Mesa para compilación Web (sin Isar).

enum EstadoMesa {
  libre,
  ocupada,
  reservada,
  enLimpieza,
}

class Mesa {
  int? id;
  late int numero;
  late EstadoMesa estado;
  late int capacidad;
  String? ubicacion;
  String? notas;
  late bool activa;
  late DateTime ultimaActualizacion;

  Mesa();

  Mesa.crear({
    required this.numero,
    this.estado = EstadoMesa.libre,
    this.capacidad = 4,
    this.ubicacion,
    this.notas,
    this.activa = true,
  }) : ultimaActualizacion = DateTime.now();

  bool get estaDisponible => estado == EstadoMesa.libre;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero': numero,
      'estado': estado.name,
      'capacidad': capacidad,
      'ubicacion': ubicacion,
      'notas': notas,
      'activa': activa,
      'ultimaActualizacion': ultimaActualizacion.toIso8601String(),
    };
  }

  factory Mesa.fromJson(Map<String, dynamic> json) {
    final mesa = Mesa()
      ..numero = json['numero'] as int
      ..estado = EstadoMesa.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => EstadoMesa.libre,
      )
      ..capacidad = json['capacidad'] as int? ?? 4
      ..ubicacion = json['ubicacion'] as String?
      ..notas = json['notas'] as String?
      ..activa = json['activa'] as bool? ?? true
      ..ultimaActualizacion = json['ultimaActualizacion'] != null
          ? DateTime.parse(json['ultimaActualizacion'] as String)
          : DateTime.now();

    if (json['id'] != null) {
      mesa.id = (json['id'] as num).toInt();
    }

    return mesa;
  }

  @override
  String toString() => 'Mesa(numero: $numero, estado: ${estado.name})';
}
