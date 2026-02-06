// Modelo base de Mesa (sin dependencia de Isar)
// Usado para serialización JSON y comunicación por API
library;

/// Estados posibles de una mesa
enum EstadoMesa {
  libre,
  ocupada,
  reservada,
  enLimpieza,
}

/// Modelo de Mesa para el sistema del restaurante
/// Representa cada mesa física del establecimiento
class Mesa {
  /// Identificador único
  int? id;

  /// Número visible de la mesa (ej: Mesa 1, Mesa 2)
  int numero;

  /// Estado actual de la mesa
  EstadoMesa estado;

  /// Capacidad máxima de personas en esta mesa
  int capacidad;

  /// Ubicación de la mesa (ej: "Terraza", "Interior", "Privado")
  String? ubicacion;

  /// Notas adicionales sobre la mesa
  String? notas;

  /// Indica si la mesa está activa (no eliminada)
  bool activa;

  /// Fecha de última actualización del estado
  DateTime ultimaActualizacion;

  /// Constructor
  Mesa({
    this.id,
    required this.numero,
    this.estado = EstadoMesa.libre,
    this.capacidad = 4,
    this.ubicacion,
    this.notas,
    this.activa = true,
    DateTime? ultimaActualizacion,
  }) : ultimaActualizacion = ultimaActualizacion ?? DateTime.now();

  /// Constructor nombrado para crear mesas (compatibilidad con código existente)
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
    return Mesa(
      id: json['id'] as int?,
      numero: json['numero'] as int,
      estado: EstadoMesa.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => EstadoMesa.libre,
      ),
      capacidad: json['capacidad'] as int? ?? 4,
      ubicacion: json['ubicacion'] as String?,
      notas: json['notas'] as String?,
      activa: json['activa'] as bool? ?? true,
      ultimaActualizacion: json['ultimaActualizacion'] != null
          ? DateTime.parse(json['ultimaActualizacion'] as String)
          : DateTime.now(),
    );
  }

  @override
  String toString() => 'Mesa(numero: $numero, estado: ${estado.name})';
}
