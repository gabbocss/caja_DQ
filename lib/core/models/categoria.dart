import 'package:isar/isar.dart';

part 'categoria.g.dart';

/// Modelo de Categoría de producto (menú)
/// Permite gestionar categorías desde Configuración > Base de Datos
@collection
class Categoria {
  /// Identificador único
  Id? id;

  /// Nombre de la categoría (ej: "Tacos", "Bebidas")
  late String nombre;

  /// Orden de visualización
  late int orden;

  /// Constructor por defecto
  Categoria();

  /// Constructor con parámetros
  Categoria.crear({
    required this.nombre,
    this.orden = 0,
  });

  /// Convierte a Map para serialización JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'orden': orden,
      };

  /// Crea Categoria desde Map JSON
  factory Categoria.fromJson(Map<String, dynamic> json) {
    final c = Categoria()..nombre = json['nombre'] as String;
    c.orden = json['orden'] as int? ?? 0;
    if (json['id'] != null) c.id = json['id'] as int;
    return c;
  }

  @override
  String toString() => 'Categoria(id: $id, nombre: $nombre, orden: $orden)';
}
