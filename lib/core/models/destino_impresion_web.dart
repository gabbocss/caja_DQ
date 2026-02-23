/// Versión del modelo DestinoImpresion para compilación Web (sin Isar).

enum TipoDestino {
  pantalla,
  impresora,
  ambos,
}

class DestinoImpresion {
  int? id;
  late String nombre;
  String? descripcion;
  late String icono;
  late String color;
  late TipoDestino tipo;
  String? nombreImpresora;
  String? direccionImpresora;
  int? puertoImpresora;
  late bool activo;
  late int orden;
  late DateTime fechaCreacion;

  DestinoImpresion();

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
      destino.id = (json['id'] as num).toInt();
    }

    return destino;
  }

  @override
  String toString() => 'DestinoImpresion(id: $id, nombre: $nombre)';
}
