// Modelo base de Producto (sin dependencia de Isar)
// Usado para serialización JSON y comunicación por API
library;

/// Destinos posibles para un producto al ser pedido
enum DestinoProducto {
  cocina,
  barra,
}

/// Modelo de Producto para el sistema del restaurante
/// Representa cada item del menú que puede ser ordenado
class Producto {
  /// Identificador único
  int? id;

  /// Nombre del producto (ej: "Tacos al Pastor", "Refresco")
  String nombre;

  /// Precio del producto en la moneda local
  double precio;

  /// Descripción detallada del producto
  String? descripcion;

  /// Ruta de la imagen del producto (puede ser local o URL)
  String? imagen;

  /// Indica si este producto forma parte del buffet del sábado
  bool esBuffet;

  /// Categoría del producto para organización del menú
  String? categoria;

  /// Destino del producto al ser pedido (cocina o barra)
  DestinoProducto destino;

  /// Indica si el producto está activo/disponible
  bool activo;

  /// Fecha de creación del registro
  DateTime fechaCreacion;

  /// Fecha de última modificación
  DateTime? fechaModificacion;

  /// Constructor por defecto
  Producto({
    this.id,
    required this.nombre,
    required this.precio,
    this.descripcion,
    this.imagen,
    this.esBuffet = false,
    this.categoria,
    this.destino = DestinoProducto.cocina,
    this.activo = true,
    DateTime? fechaCreacion,
    this.fechaModificacion,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  /// Constructor nombrado para crear productos (compatibilidad con código existente)
  Producto.crear({
    required this.nombre,
    required this.precio,
    this.descripcion,
    this.imagen,
    this.esBuffet = false,
    this.categoria,
    this.destino = DestinoProducto.cocina,
    this.activo = true,
  }) : fechaCreacion = DateTime.now();

  /// Convierte el producto a un Map para serialización JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'precio': precio,
      'descripcion': descripcion,
      'imagen': imagen,
      'esBuffet': esBuffet,
      'categoria': categoria,
      'destino': destino.name,
      'activo': activo,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaModificacion': fechaModificacion?.toIso8601String(),
    };
  }

  /// Crea un Producto desde un Map JSON
  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] as int?,
      nombre: json['nombre'] as String,
      precio: (json['precio'] as num).toDouble(),
      descripcion: json['descripcion'] as String?,
      imagen: json['imagen'] as String?,
      esBuffet: json['esBuffet'] as bool? ?? false,
      categoria: json['categoria'] as String?,
      destino: DestinoProducto.values.firstWhere(
        (e) => e.name == json['destino'],
        orElse: () => DestinoProducto.cocina,
      ),
      activo: json['activo'] as bool? ?? true,
      fechaCreacion: json['fechaCreacion'] != null
          ? DateTime.parse(json['fechaCreacion'] as String)
          : DateTime.now(),
      fechaModificacion: json['fechaModificacion'] != null
          ? DateTime.parse(json['fechaModificacion'] as String)
          : null,
    );
  }

  @override
  String toString() => 'Producto(id: $id, nombre: $nombre, precio: $precio)';
}
