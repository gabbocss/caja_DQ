/// Versión del modelo Producto para compilación Web (sin Isar).
/// Misma API que producto.dart; evita literales enteros no representables en JS.

/// Destinos posibles para un producto al ser pedido (legacy - para compatibilidad)
enum DestinoProducto {
  cocina,
  barra,
}

/// Modelo de Producto para el sistema del restaurante (Web)
class Producto {
  int? id;
  late String nombre;
  late double precio;
  String? descripcion;
  String? imagen;
  List<String> alergenos = [];
  late bool esBuffet;
  String? categoria;
  int? destinoId;
  late DestinoProducto destino;
  late bool activo;
  late bool isAvailable;
  late bool usarInventario;
  late int stockDisponible;
  int? stock;
  late DateTime fechaCreacion;
  DateTime? fechaModificacion;

  Producto();

  Producto.crear({
    required this.nombre,
    required this.precio,
    this.descripcion,
    this.imagen,
    List<String>? alergenos,
    this.esBuffet = false,
    this.categoria,
    this.destinoId,
    this.destino = DestinoProducto.cocina,
    this.activo = true,
    this.isAvailable = true,
    this.usarInventario = false,
    this.stockDisponible = 0,
    this.stock,
  }) : alergenos = alergenos ?? [],
       fechaCreacion = DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'precio': precio,
      'descripcion': descripcion,
      'imagen': imagen,
      'alergenos': alergenos,
      'esBuffet': esBuffet,
      'categoria': categoria,
      'destinoId': destinoId,
      'destino': destino.name,
      'activo': activo,
      'isAvailable': isAvailable,
      'usarInventario': usarInventario,
      'stockDisponible': stockDisponible,
      'stock': stock,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaModificacion': fechaModificacion?.toIso8601String(),
    };
  }

  factory Producto.fromJson(Map<String, dynamic> json) {
    final producto = Producto()
      ..nombre = json['nombre'] as String
      ..precio = (json['precio'] as num).toDouble()
      ..descripcion = json['descripcion'] as String?
      ..imagen = json['imagen'] as String?
      ..alergenos = (json['alergenos'] as List<dynamic>?)?.map((e) => e as String).toList() ?? []
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
      ..stock = json['stock'] as int?
      ..fechaCreacion = json['fechaCreacion'] != null
          ? DateTime.parse(json['fechaCreacion'] as String)
          : DateTime.now()
      ..fechaModificacion = json['fechaModificacion'] != null
          ? DateTime.parse(json['fechaModificacion'] as String)
          : null;

    if (json['id'] != null) {
      producto.id = (json['id'] as num).toInt();
    }

    return producto;
  }

  @override
  String toString() => 'Producto(id: $id, nombre: $nombre, precio: $precio)';
}
