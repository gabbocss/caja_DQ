// Modelo base de Pedido (sin dependencia de Isar)
// Usado para serialización JSON y comunicación por API
library;

/// Estados posibles de un pedido
enum EstadoPedido {
  pendiente,
  preparando,
  listo,
  servido,
  cancelado,
  pagado,
}

/// Modelo para representar un item dentro del pedido
class ItemPedido {
  /// ID del producto referenciado
  int productoId;

  /// Nombre del producto (cacheado para historial)
  String nombreProducto;

  /// Precio unitario al momento del pedido
  double precioUnitario;

  /// Cantidad de este producto en el pedido
  int cantidad;

  /// Notas especiales para este item (ej: "sin cebolla")
  String? notas;

  /// Estado individual del item
  EstadoPedido estadoItem;

  /// Constructor
  ItemPedido({
    required this.productoId,
    required this.nombreProducto,
    required this.precioUnitario,
    this.cantidad = 1,
    this.notas,
    this.estadoItem = EstadoPedido.pendiente,
  });

  /// Constructor nombrado para crear items (compatibilidad con código existente)
  ItemPedido.crear({
    required this.productoId,
    required this.nombreProducto,
    required this.precioUnitario,
    this.cantidad = 1,
    this.notas,
    this.estadoItem = EstadoPedido.pendiente,
  });

  /// Calcula el subtotal de este item
  double get subtotal => precioUnitario * cantidad;

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'productoId': productoId,
      'nombreProducto': nombreProducto,
      'precioUnitario': precioUnitario,
      'cantidad': cantidad,
      'notas': notas,
      'estadoItem': estadoItem.name,
    };
  }

  /// Crea desde JSON
  factory ItemPedido.fromJson(Map<String, dynamic> json) {
    return ItemPedido(
      productoId: json['productoId'] as int,
      nombreProducto: json['nombreProducto'] as String,
      precioUnitario: (json['precioUnitario'] as num).toDouble(),
      cantidad: json['cantidad'] as int? ?? 1,
      notas: json['notas'] as String?,
      estadoItem: EstadoPedido.values.firstWhere(
        (e) => e.name == json['estadoItem'],
        orElse: () => EstadoPedido.pendiente,
      ),
    );
  }
}

/// Modelo de Pedido para el sistema del restaurante
/// Representa una comanda/orden de un cliente
class Pedido {
  /// Identificador único
  int? id;

  /// Número de la mesa asociada a este pedido
  int mesaNumero;

  /// Lista de items/productos en el pedido
  List<ItemPedido> items;

  /// Estado general del pedido
  EstadoPedido estado;

  /// Total calculado del pedido
  double total;

  /// Identificador o nombre del camarero/mesero
  String usuarioCamarero;

  /// Número de comensales en la mesa
  int? numeroComensales;

  /// Notas generales del pedido
  String? notas;

  /// Indica si es un pedido de buffet
  bool esBuffet;

  /// Fecha y hora de creación del pedido
  DateTime fechaCreacion;

  /// Fecha y hora de última actualización
  DateTime fechaActualizacion;

  /// Fecha y hora cuando el pedido fue completado/pagado
  DateTime? fechaCompletado;

  /// Constructor
  Pedido({
    this.id,
    required this.mesaNumero,
    required this.usuarioCamarero,
    List<ItemPedido>? items,
    this.estado = EstadoPedido.pendiente,
    this.total = 0,
    this.numeroComensales,
    this.notas,
    this.esBuffet = false,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    this.fechaCompletado,
  })  : items = items ?? [],
        fechaCreacion = fechaCreacion ?? DateTime.now(),
        fechaActualizacion = fechaActualizacion ?? DateTime.now();

  /// Constructor nombrado para crear pedidos (compatibilidad con código existente)
  Pedido.crear({
    required this.mesaNumero,
    required this.usuarioCamarero,
    List<ItemPedido>? items,
    this.estado = EstadoPedido.pendiente,
    this.numeroComensales,
    this.notas,
    this.esBuffet = false,
  })  : total = 0,
        items = items ?? [],
        fechaCreacion = DateTime.now(),
        fechaActualizacion = DateTime.now();

  /// Recalcula el total del pedido basándose en los items
  void calcularTotal() {
    total = items.fold(0, (sum, item) => sum + item.subtotal);
  }

  /// Agrega un item al pedido y recalcula el total
  void agregarItem(ItemPedido item) {
    items.add(item);
    calcularTotal();
    fechaActualizacion = DateTime.now();
  }

  /// Elimina un item del pedido por índice
  void eliminarItem(int index) {
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
      calcularTotal();
      fechaActualizacion = DateTime.now();
    }
  }

  /// Verifica si el pedido está activo (no cancelado ni pagado)
  bool get estaActivo =>
      estado != EstadoPedido.cancelado && estado != EstadoPedido.pagado;

  /// Convierte el pedido a un Map para serialización JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mesaNumero': mesaNumero,
      'items': items.map((item) => item.toJson()).toList(),
      'estado': estado.name,
      'total': total,
      'usuarioCamarero': usuarioCamarero,
      'numeroComensales': numeroComensales,
      'notas': notas,
      'esBuffet': esBuffet,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaActualizacion': fechaActualizacion.toIso8601String(),
      'fechaCompletado': fechaCompletado?.toIso8601String(),
    };
  }

  /// Crea un Pedido desde un Map JSON
  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      id: json['id'] as int?,
      mesaNumero: json['mesaNumero'] as int,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => ItemPedido.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      estado: EstadoPedido.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => EstadoPedido.pendiente,
      ),
      total: (json['total'] as num?)?.toDouble() ?? 0,
      usuarioCamarero: json['usuarioCamarero'] as String,
      numeroComensales: json['numeroComensales'] as int?,
      notas: json['notas'] as String?,
      esBuffet: json['esBuffet'] as bool? ?? false,
      fechaCreacion: json['fechaCreacion'] != null
          ? DateTime.parse(json['fechaCreacion'] as String)
          : DateTime.now(),
      fechaActualizacion: json['fechaActualizacion'] != null
          ? DateTime.parse(json['fechaActualizacion'] as String)
          : DateTime.now(),
      fechaCompletado: json['fechaCompletado'] != null
          ? DateTime.parse(json['fechaCompletado'] as String)
          : null,
    );
  }

  @override
  String toString() =>
      'Pedido(id: $id, mesa: $mesaNumero, estado: ${estado.name}, total: $total)';
}
