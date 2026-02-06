import 'package:isar/isar.dart';

part 'producto.g.dart';

/// Destinos posibles para un producto al ser pedido (legacy - para compatibilidad)
enum DestinoProducto {
  cocina,
  barra,
}

/// Modelo de Producto para el sistema del restaurante
/// Representa cada item del menú que puede ser ordenado
@collection
class Producto {
  /// Identificador único - Isar lo asignará automáticamente si es null
  Id? id;

  /// Nombre del producto (ej: "Tacos al Pastor", "Refresco")
  @Index()
  late String nombre;

  /// Precio del producto en la moneda local
  late double precio;

  /// Descripción detallada del producto
  String? descripcion;

  /// Ruta de la imagen del producto (puede ser local o URL)
  String? imagen;

  /// Indica si este producto forma parte del buffet del sábado
  @Index()
  late bool esBuffet;

  /// Categoría del producto para organización del menú
  @Index()
  String? categoria;

  /// ID del destino de impresión configurable
  /// Referencia a DestinoImpresion.id
  @Index()
  int? destinoId;

  /// Destino del producto al ser pedido (legacy - mantener por compatibilidad)
  @Index()
  @Enumerated(EnumType.name)
  late DestinoProducto destino;

  /// Indica si el producto está activo/disponible en el menú
  late bool activo;

  /// Indica si el producto está disponible para ordenar (inventario)
  /// Se usa para marcar productos temporalmente agotados
  @Index()
  late bool isAvailable;

  /// Indica si este producto usa control de inventario dinámico
  /// Si es true, el stock se descontará automáticamente al hacer pedidos
  late bool usarInventario;

  /// Stock disponible del producto (solo se usa si usarInventario es true)
  /// Se descuenta automáticamente cuando se realiza un pedido
  late int stockDisponible;

  /// Stock del producto (legacy - mantener por compatibilidad)
  /// Se sincroniza automáticamente con stockDisponible
  int? stock;

  /// Fecha de creación del registro
  late DateTime fechaCreacion;

  /// Fecha de última modificación
  DateTime? fechaModificacion;

  /// Constructor por defecto
  Producto();

  /// Constructor con parámetros nombrados para facilitar la creación
  Producto.crear({
    required this.nombre,
    required this.precio,
    this.descripcion,
    this.imagen,
    this.esBuffet = false,
    this.categoria,
    this.destinoId,
    this.destino = DestinoProducto.cocina,
    this.activo = true,
    this.isAvailable = true,
    this.usarInventario = false,
    this.stockDisponible = 0,
    this.stock, // Legacy - mantener por compatibilidad
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
      'destinoId': destinoId,
      'destino': destino.name,
      'activo': activo,
      'isAvailable': isAvailable,
      'usarInventario': usarInventario,
      'stockDisponible': stockDisponible,
      'stock': stock, // Legacy
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaModificacion': fechaModificacion?.toIso8601String(),
    };
  }

  /// Crea un Producto desde un Map JSON
  factory Producto.fromJson(Map<String, dynamic> json) {
    final producto = Producto()
      ..nombre = json['nombre'] as String
      ..precio = (json['precio'] as num).toDouble()
      ..descripcion = json['descripcion'] as String?
      ..imagen = json['imagen'] as String?
      ..esBuffet = json['esBuffet'] as bool? ?? false
      ..categoria = json['categoria'] as String?
      ..destinoId = json['destinoId'] as int?
      ..destino = DestinoProducto.values.firstWhere(
        (e) => e.name == json['destino'],
        orElse: () => DestinoProducto.cocina,
      )
      ..activo = json['activo'] as bool? ?? true
      ..isAvailable = json['isAvailable'] as bool? ?? true
      ..usarInventario = json['usarInventario'] as bool? ?? false
      ..stockDisponible = json['stockDisponible'] as int? ?? 0
      ..stock = json['stock'] as int? // Legacy
      ..fechaCreacion = json['fechaCreacion'] != null
          ? DateTime.parse(json['fechaCreacion'] as String)
          : DateTime.now()
      ..fechaModificacion = json['fechaModificacion'] != null
          ? DateTime.parse(json['fechaModificacion'] as String)
          : null;

    if (json['id'] != null) {
      producto.id = json['id'] as int;
    }

    return producto;
  }

  @override
  String toString() => 'Producto(id: $id, nombre: $nombre, precio: $precio)';
}
