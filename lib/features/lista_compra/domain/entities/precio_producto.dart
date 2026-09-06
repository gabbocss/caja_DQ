import 'unidad_medida.dart';

/// Precio de un producto en un supermercado (último guardado).
class PrecioProducto {
  final int id;
  final int productoId;
  final int supermercadoId;
  final double precioEnvase;
  final double contenidoCantidad;
  final ContenidoUnidad contenidoUnidad;
  final UnidadBase unidadBase;
  final double precioPorBase;
  final DateTime? fecha;

  const PrecioProducto({
    required this.id,
    required this.productoId,
    required this.supermercadoId,
    required this.precioEnvase,
    required this.contenidoCantidad,
    required this.contenidoUnidad,
    required this.unidadBase,
    required this.precioPorBase,
    this.fecha,
  });

  factory PrecioProducto.fromJson(Map<String, dynamic> json) {
    final unidadBase = UnidadBase.fromString(json['unidadBase'] as String?);
    return PrecioProducto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      productoId: (json['productoId'] as num?)?.toInt() ?? 0,
      supermercadoId: (json['supermercadoId'] as num?)?.toInt() ?? 0,
      precioEnvase: (json['precioEnvase'] as num?)?.toDouble() ?? 0,
      contenidoCantidad: (json['contenidoCantidad'] as num?)?.toDouble() ?? 0,
      contenidoUnidad: ContenidoUnidad.fromString(
        json['contenidoUnidad'] as String?,
        unidadBase,
      ),
      unidadBase: unidadBase,
      precioPorBase: (json['precioPorBase'] as num?)?.toDouble() ?? 0,
      fecha: json['fecha'] != null
          ? DateTime.tryParse(json['fecha'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id > 0) 'id': id,
        'productoId': productoId,
        'supermercadoId': supermercadoId,
        'precioEnvase': precioEnvase,
        'contenidoCantidad': contenidoCantidad,
        'contenidoUnidad': contenidoUnidad.name,
        'unidadBase': unidadBase.apiValue,
      };
}
