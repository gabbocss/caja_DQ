import 'unidad_medida.dart';

/// Ítem del catálogo de la compra (persistido solo en el VPS).
class ItemListaCompra {
  final int id;
  final String nombre;
  final String cantidad;
  final bool hayQueComprar;
  final bool comprado;
  final int orden;
  final UnidadBase unidadBase;
  final double? contenidoCantidad;
  final ContenidoUnidad contenidoUnidad;
  /// Envases/unidades mínimas que sueles comprar de este producto.
  final int cantidadMinima;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  const ItemListaCompra({
    required this.id,
    required this.nombre,
    this.cantidad = '',
    this.hayQueComprar = false,
    this.comprado = false,
    this.orden = 0,
    this.unidadBase = UnidadBase.unidad,
    this.contenidoCantidad,
    this.contenidoUnidad = ContenidoUnidad.ud,
    this.cantidadMinima = 1,
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  factory ItemListaCompra.fromJson(Map<String, dynamic> json) {
    final hayQueComprar = json['hayQueComprar'] == true;
    final unidadBase = UnidadBase.fromString(json['unidadBase'] as String?);
    final contenidoRaw = json['contenidoCantidad'];
    final minRaw = (json['cantidadMinima'] as num?)?.toInt();
    return ItemListaCompra(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nombre: (json['nombre'] as String?)?.trim() ?? '',
      cantidad: (json['cantidad'] as String?) ?? '',
      hayQueComprar: hayQueComprar,
      comprado: hayQueComprar && json['comprado'] == true,
      orden: (json['orden'] as num?)?.toInt() ?? 0,
      unidadBase: unidadBase,
      contenidoCantidad: contenidoRaw == null
          ? null
          : (contenidoRaw as num?)?.toDouble(),
      contenidoUnidad: ContenidoUnidad.fromString(
        json['contenidoUnidad'] as String?,
        unidadBase,
      ),
      cantidadMinima: (minRaw != null && minRaw >= 1) ? minRaw : 1,
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
        'unidadBase': unidadBase.apiValue,
        'contenidoCantidad': contenidoCantidad,
        'contenidoUnidad': contenidoUnidad.name,
        'cantidadMinima': cantidadMinima,
      };

  ItemListaCompra copyWith({
    int? id,
    String? nombre,
    String? cantidad,
    bool? hayQueComprar,
    bool? comprado,
    int? orden,
    UnidadBase? unidadBase,
    double? contenidoCantidad,
    bool clearContenido = false,
    ContenidoUnidad? contenidoUnidad,
    int? cantidadMinima,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    final hay = hayQueComprar ?? this.hayQueComprar;
    final base = unidadBase ?? this.unidadBase;
    final min = cantidadMinima ?? this.cantidadMinima;
    return ItemListaCompra(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      cantidad: cantidad ?? this.cantidad,
      hayQueComprar: hay,
      comprado: hay ? (comprado ?? this.comprado) : false,
      orden: orden ?? this.orden,
      unidadBase: base,
      contenidoCantidad:
          clearContenido ? null : (contenidoCantidad ?? this.contenidoCantidad),
      contenidoUnidad: contenidoUnidad ??
          ContenidoUnidad.fromString(this.contenidoUnidad.name, base),
      cantidadMinima: min < 1 ? 1 : min,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  static DateTime? _parseFecha(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
