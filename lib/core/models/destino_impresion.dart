import 'package:isar/isar.dart';

part 'destino_impresion.g.dart';

/// Tipo de destino para la impresión/visualización
enum TipoDestino {
  pantalla,   // Muestra en pantalla (cocina, barra, etc.)
  impresora,  // Imprime en impresora física
  ambos,      // Pantalla + impresora
}

/// Modelo de Destino de Impresión configurable
/// 
/// Permite definir diferentes puntos donde se envían los productos:
/// - Cocina principal
/// - Barra de bebidas
/// - Cocina secundaria
/// - Impresoras específicas
@collection
class DestinoImpresion {
  /// Identificador único
  Id? id;

  /// Nombre del destino (ej: "Cocina Principal", "Barra")
  @Index(unique: true)
  late String nombre;

  /// Descripción del destino
  String? descripcion;

  /// Icono para mostrar en la UI (nombre del icono de Material)
  late String icono;

  /// Color en formato hex (ej: "#E94560")
  late String color;

  /// Tipo de destino (pantalla, impresora o ambos)
  @Enumerated(EnumType.name)
  late TipoDestino tipo;

  /// Nombre de la impresora física (si aplica)
  String? nombreImpresora;

  /// IP o dirección de la impresora de red (si aplica)
  String? direccionImpresora;

  /// Puerto de la impresora (default: 9100 para impresoras de red)
  int? puertoImpresora;

  /// Indica si el destino está activo
  late bool activo;

  /// Orden de visualización
  late int orden;

  /// Fecha de creación
  late DateTime fechaCreacion;

  /// Constructor por defecto
  DestinoImpresion();

  /// Constructor con parámetros
  DestinoImpresion.crear({
    required this.nombre,
    this.descripcion,
    this.icono = 'restaurant',
    this.color = '#E94560',
    this.tipo = TipoDestino.pantalla,
    this.nombreImpresora,
    this.direccionImpresora,
    this.puertoImpresora,
    this.activo = true,
    this.orden = 0,
  }) : fechaCreacion = DateTime.now();

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'icono': icono,
      'color': color,
      'tipo': tipo.name,
      'nombreImpresora': nombreImpresora,
      'direccionImpresora': direccionImpresora,
      'puertoImpresora': puertoImpresora,
      'activo': activo,
      'orden': orden,
      'fechaCreacion': fechaCreacion.toIso8601String(),
    };
  }

  /// Crea desde JSON
  factory DestinoImpresion.fromJson(Map<String, dynamic> json) {
    final destino = DestinoImpresion()
      ..nombre = json['nombre'] as String
      ..descripcion = json['descripcion'] as String?
      ..icono = json['icono'] as String? ?? 'restaurant'
      ..color = json['color'] as String? ?? '#E94560'
      ..tipo = TipoDestino.values.firstWhere(
        (e) => e.name == json['tipo'],
        orElse: () => TipoDestino.pantalla,
      )
      ..nombreImpresora = json['nombreImpresora'] as String?
      ..direccionImpresora = json['direccionImpresora'] as String?
      ..puertoImpresora = json['puertoImpresora'] as int?
      ..activo = json['activo'] as bool? ?? true
      ..orden = json['orden'] as int? ?? 0
      ..fechaCreacion = json['fechaCreacion'] != null
          ? DateTime.parse(json['fechaCreacion'] as String)
          : DateTime.now();

    if (json['id'] != null) {
      destino.id = json['id'] as int;
    }

    return destino;
  }

  @override
  String toString() => 'DestinoImpresion(id: $id, nombre: $nombre)';
}
