/// Contribución de una mesa a una línea de producción buffet (snapshot para impresión).
/// Incluye [pedidoId] e [itemIndex] para poder marcar el ítem como listo en el servidor al hacer "Hecho".
/// [keyEnLineasCerradas] es la clave que se añadió a _itemKeysEnLineasCerradas (índice en lista filtrada).
class ContribucionBuffet {
  final int pedidoId;
  final int itemIndex;
  /// Clave usada en _itemKeysEnLineasCerradas (pedidoId_indexFiltrado) para poder quitarla al hacer Hecho.
  final String keyEnLineasCerradas;
  final int mesaNumero;
  final int cantidad;
  final String nombreProducto;
  final int productoId;
  final int? destinoId;
  final double precioUnitario;
  final DateTime fechaCreacion;

  const ContribucionBuffet({
    required this.pedidoId,
    required this.itemIndex,
    required this.keyEnLineasCerradas,
    required this.mesaNumero,
    required this.cantidad,
    required this.nombreProducto,
    required this.productoId,
    this.destinoId,
    required this.precioUnitario,
    required this.fechaCreacion,
  });

  String get key => '${pedidoId}_$itemIndex';
}

/// Estado de una línea cerrada en modo buffet.
enum EstadoLineaBuffet {
  enPreparacion,
  listo,
}

/// Línea de producción cerrada (congelada) en modo buffet.
/// Al pulsar "Empezar" se crea esta línea con un snapshot de las contribuciones.
class LineaBuffetCerrada {
  final String id;
  final int productoId;
  final String nombreProducto;
  int cantidadTotal;
  final List<ContribucionBuffet> contribuciones;
  EstadoLineaBuffet estado;

  LineaBuffetCerrada({
    required this.id,
    required this.productoId,
    required this.nombreProducto,
    required this.cantidadTotal,
    required this.contribuciones,
    this.estado = EstadoLineaBuffet.enPreparacion,
  });
}

/// Contribución a una línea abierta (antes de congelar). Incluye referencia al pedido/item.
class ContribucionAbierta {
  final int pedidoId;
  final int itemIndex;
  final int mesaNumero;
  final int cantidad;
  final DateTime fechaCreacion;

  const ContribucionAbierta({
    required this.pedidoId,
    required this.itemIndex,
    required this.mesaNumero,
    required this.cantidad,
    required this.fechaCreacion,
  });

  String get key => '${pedidoId}_$itemIndex';
}

/// Línea abierta (agregación actual de un plato). Los nuevos pedidos se suman aquí hasta "Empezar".
class LineaBuffetAbierta {
  final int productoId;
  final String nombreProducto;
  final int cantidadTotal;
  final List<ContribucionAbierta> contribuciones;

  const LineaBuffetAbierta({
    required this.productoId,
    required this.nombreProducto,
    required this.cantidadTotal,
    required this.contribuciones,
  });
}
