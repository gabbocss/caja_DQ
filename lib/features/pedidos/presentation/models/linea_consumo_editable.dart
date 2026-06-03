import '../../../../core/models/pedido.dart';

/// Línea editable de la cuenta abierta (referencia a un ítem dentro de un pedido).
class LineaConsumoEditable {
  final int? pedidoId;
  final int itemIndex;
  final int productoId;
  final String nombreProducto;
  final int? destinoId;
  final int cantidadOriginal;
  final double precioOriginal;

  int cantidad;
  double precioUnitario;

  LineaConsumoEditable({
    required this.pedidoId,
    required this.itemIndex,
    required this.productoId,
    required this.nombreProducto,
    required this.destinoId,
    required this.cantidadOriginal,
    required this.precioOriginal,
    required this.cantidad,
    required this.precioUnitario,
  });

  double get subtotal => precioUnitario * cantidad;

  int get cantidadEliminada {
    final diff = cantidadOriginal - cantidad;
    return diff > 0 ? diff : 0;
  }

  int get cantidadAnadida {
    final diff = cantidad - cantidadOriginal;
    return diff > 0 ? diff : 0;
  }

  bool get huboCambioCantidad => cantidad != cantidadOriginal;
  bool get huboCambioPrecio => (precioUnitario - precioOriginal).abs() > 0.001;
  bool get huboCambio => huboCambioCantidad || huboCambioPrecio;

  static List<LineaConsumoEditable> desdePedidos(List<Pedido> pedidos) {
    final lineas = <LineaConsumoEditable>[];
    for (final pedido in pedidos) {
      for (var i = 0; i < pedido.items.length; i++) {
        final item = pedido.items[i];
        lineas.add(
          LineaConsumoEditable(
            pedidoId: pedido.id,
            itemIndex: i,
            productoId: item.productoId,
            nombreProducto: item.nombreProducto,
            destinoId: item.destinoId,
            cantidadOriginal: item.cantidad,
            precioOriginal: item.precioUnitario,
            cantidad: item.cantidad,
            precioUnitario: item.precioUnitario,
          ),
        );
      }
    }
    return lineas;
  }
}
