/// Zona del local a la que pertenece el producto del catálogo.
enum ZonaListaCompra {
  cocina,
  sala;

  String get etiqueta => this == ZonaListaCompra.sala ? 'Sala' : 'Cocina';

  String get apiValue => name;

  static ZonaListaCompra fromString(String? value) {
    return (value ?? '').toLowerCase() == 'sala'
        ? ZonaListaCompra.sala
        : ZonaListaCompra.cocina;
  }
}

/// Ítem del catálogo de la compra (persistido solo en el VPS).
class ItemListaCompra {
  final int id;
  final String nombre;
  final String cantidad;
  final bool hayQueComprar;
  final bool comprado;
  final int orden;
  final ZonaListaCompra zona;
  /// Súper donde suele comprarse; null = sin asignar.
  final int? supermercadoId;
  /// Enlace ficha Metro (legacy / desktop).
  final String urlMetro;
  /// Enlace ficha C&C (legacy / desktop).
  final String urlCc;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  const ItemListaCompra({
    required this.id,
    required this.nombre,
    this.cantidad = '',
    this.hayQueComprar = false,
    this.comprado = false,
    this.orden = 0,
    this.zona = ZonaListaCompra.cocina,
    this.supermercadoId,
    this.urlMetro = '',
    this.urlCc = '',
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  bool get tieneUrlMetro => urlMetro.trim().isNotEmpty;
  bool get tieneUrlCc => urlCc.trim().isNotEmpty;
  bool get tieneAlgunaUrl => tieneUrlMetro || tieneUrlCc;
  bool get tieneSupermercado => supermercadoId != null && supermercadoId! > 0;

  factory ItemListaCompra.fromJson(Map<String, dynamic> json) {
    final hayQueComprar = json['hayQueComprar'] == true;
    final superRaw = (json['supermercadoId'] as num?)?.toInt();
    // Migración: urlProveedor antiguo → urlMetro.
    final urlMetro = (json['urlMetro'] as String?)?.trim().isNotEmpty == true
        ? (json['urlMetro'] as String).trim()
        : ((json['urlProveedor'] as String?)?.trim() ?? '');
    return ItemListaCompra(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nombre: (json['nombre'] as String?)?.trim() ?? '',
      cantidad: (json['cantidad'] as String?) ?? '',
      hayQueComprar: hayQueComprar,
      comprado: hayQueComprar && json['comprado'] == true,
      orden: (json['orden'] as num?)?.toInt() ?? 0,
      zona: ZonaListaCompra.fromString(json['zona'] as String?),
      supermercadoId: (superRaw != null && superRaw > 0) ? superRaw : null,
      urlMetro: urlMetro,
      urlCc: (json['urlCc'] as String?)?.trim() ?? '',
      fechaCreacion: _parseFecha(json['fechaCreacion']),
      fechaActualizacion: _parseFecha(json['fechaActualizacion']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id > 0) 'id': id,
        'nombre': nombre,
        'cantidad': cantidad,
        'hayQueComprar': hayQueComprar,
        'comprado': comprado,
        'orden': orden,
        'zona': zona.apiValue,
        'supermercadoId': supermercadoId,
        'urlMetro': urlMetro,
        'urlCc': urlCc,
      };

  ItemListaCompra copyWith({
    int? id,
    String? nombre,
    String? cantidad,
    bool? hayQueComprar,
    bool? comprado,
    int? orden,
    ZonaListaCompra? zona,
    int? supermercadoId,
    bool clearSupermercado = false,
    String? urlMetro,
    String? urlCc,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    final hay = hayQueComprar ?? this.hayQueComprar;
    return ItemListaCompra(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      cantidad: cantidad ?? this.cantidad,
      hayQueComprar: hay,
      comprado: hay ? (comprado ?? this.comprado) : false,
      orden: orden ?? this.orden,
      zona: zona ?? this.zona,
      supermercadoId: clearSupermercado
          ? null
          : (supermercadoId ?? this.supermercadoId),
      urlMetro: urlMetro ?? this.urlMetro,
      urlCc: urlCc ?? this.urlCc,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  static DateTime? _parseFecha(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
