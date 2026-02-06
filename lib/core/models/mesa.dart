import 'package:isar/isar.dart';

part 'mesa.g.dart';

/// Estados posibles de una mesa
enum EstadoMesa {
  libre,
  ocupada,
  reservada,
  enLimpieza,
}

/// Modelo de Mesa para el sistema del restaurante
/// Representa cada mesa física del establecimiento
@collection
class Mesa {
  /// Identificador único - Isar lo asignará automáticamente si es null
  /// Usamos int? para compatibilidad con Web (evita números grandes de JS)
  Id? id;

  /// Número visible de la mesa (ej: Mesa 1, Mesa 2)
  @Index(unique: true)
  late int numero;

  /// Estado actual de la mesa
  @Enumerated(EnumType.name)
  late EstadoMesa estado;

  /// Capacidad máxima de personas en esta mesa
  late int capacidad;

  /// Ubicación de la mesa (ej: "Terraza", "Interior", "Privado")
  String? ubicacion;

  /// Notas adicionales sobre la mesa
  String? notas;

  /// Indica si la mesa está activa (no eliminada)
  late bool activa;

  /// Fecha de última actualización del estado
  late DateTime ultimaActualizacion;

  /// Constructor por defecto
  Mesa();

  /// Constructor con parámetros nombrados
  Mesa.crear({
    required this.numero,
    this.estado = EstadoMesa.libre,
    this.capacidad = 4,
    this.ubicacion,
    this.notas,
    this.activa = true,
  }) : ultimaActualizacion = DateTime.now();

  /// Verifica si la mesa está disponible para nuevos clientes
  bool get estaDisponible => estado == EstadoMesa.libre;

  /// Convierte la mesa a un Map para serialización JSON
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

  /// Crea una Mesa desde un Map JSON
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
      mesa.id = json['id'] as int;
    }

    return mesa;
  }

  @override
  String toString() => 'Mesa(numero: $numero, estado: ${estado.name})';
}
