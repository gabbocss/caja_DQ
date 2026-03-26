import 'package:isar/isar.dart';

part 'pedido.g.dart';

/// Estados posibles de un pedido
enum EstadoPedido {
  pendiente,
  preparando,
  listo,
  servido,
  cancelado,
  pagado,
}

/// Origen del pedido
enum OrigenPedido {
  camarero, // Pedido tomado por un camarero
  qr,       // Pedido hecho por el cliente vía QR
  web,      // Pedido desde la web
}

/// Modelo embebido para representar un item dentro del pedido
@embedded
class ItemPedido {
  /// ID del producto referenciado
  late int productoId;

  /// Nombre del producto (cacheado para historial)
  late String nombreProducto;

  /// Precio unitario al momento del pedido
  late double precioUnitario;

  /// Cantidad de este producto en el pedido
  late int cantidad;

  /// Notas especiales para este item (ej: "sin cebolla")
  String? notas;

  /// ID del destino de impresión (cocina, barra, etc.)
  int? destinoId;

  /// Nombre del destino (cacheado para visualización)
  String? nombreDestino;

  /// Estado individual del item
  @Enumerated(EnumType.name)
  EstadoPedido estadoItem = EstadoPedido.pendiente;

  /// Momento en que cocina empezó este plato (estado → preparando).
  DateTime? fechaInicioPreparacionItem;
  /// Momento en que cocina marcó este plato como hecho (estado → listo).
  DateTime? fechaListoItem;

  /// Orden del plato: 1 = 1º, 2 = 2º, etc.
  int orden = 1;

  /// Constructor por defecto requerido por Isar
  ItemPedido();

  /// Constructor con parámetros
  ItemPedido.crear({
    required this.productoId,
    required this.nombreProducto,
    required this.precioUnitario,
    this.cantidad = 1,
    this.notas,
    this.destinoId,
    this.nombreDestino,
    this.estadoItem = EstadoPedido.pendiente,
    this.orden = 1,
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
      'destinoId': destinoId,
      'nombreDestino': nombreDestino,
      'estadoItem': estadoItem.name,
      'fechaInicioPreparacionItem': fechaInicioPreparacionItem?.toIso8601String(),
      'fechaListoItem': fechaListoItem?.toIso8601String(),
      'orden': orden,
    };
  }

  /// Crea desde JSON
  factory ItemPedido.fromJson(Map<String, dynamic> json) {
    return ItemPedido()
      ..productoId = json['productoId'] as int
      ..nombreProducto = json['nombreProducto'] as String
      ..precioUnitario = (json['precioUnitario'] as num).toDouble()
      ..cantidad = json['cantidad'] as int? ?? 1
      ..notas = json['notas'] as String?
      ..destinoId = json['destinoId'] as int?
      ..nombreDestino = json['nombreDestino'] as String?
      ..estadoItem = EstadoPedido.values.firstWhere(
        (e) => e.name == json['estadoItem'],
        orElse: () => EstadoPedido.pendiente,
      )
      ..fechaInicioPreparacionItem = json['fechaInicioPreparacionItem'] != null
          ? DateTime.tryParse(json['fechaInicioPreparacionItem'] as String)
          : null
      ..fechaListoItem = json['fechaListoItem'] != null
          ? DateTime.tryParse(json['fechaListoItem'] as String)
          : null
      ..orden = json['orden'] as int? ?? 1;
  }
}

/// Modelo de Pedido para el sistema del restaurante
/// Representa una comanda/orden de un cliente
@collection
class Pedido {
  /// Identificador único - Isar lo asignará automáticamente si es null
  Id? id;

  /// Número de la mesa asociada a este pedido
  @Index()
  late int mesaNumero;

  /// Lista de items/productos en el pedido
  late List<ItemPedido> items;

  /// Estado general del pedido
  @Index()
  @Enumerated(EnumType.name)
  late EstadoPedido estado;

  /// Total calculado del pedido
  late double total;

  /// Identificador o nombre del camarero/mesero
  @Index()
  late String usuarioCamarero;

  /// Número de comensales en la mesa
  int? numeroComensales;

  /// Notas generales del pedido
  String? notas;

  /// Indica si es un pedido de buffet
  late bool esBuffet;

  /// Origen del pedido (camarero, QR, web)
  @Enumerated(EnumType.name)
  OrigenPedido origen = OrigenPedido.camarero;

  /// Fecha y hora de creación del pedido
  @Index()
  late DateTime fechaCreacion;

  /// Fecha y hora de última actualización
  late DateTime fechaActualizacion;

  /// Fecha y hora cuando el pedido fue completado/pagado
  DateTime? fechaCompletado;

  /// Fecha en que cocina pulsó "Empezar" (estado → preparando). Para estadísticas de tiempo.
  DateTime? fechaInicioPreparacion;

  /// Fecha en que cocina marcó "Listo". Para estadísticas de tiempo.
  DateTime? fechaListo;

  /// Constructor por defecto
  Pedido();

  /// Constructor con parámetros nombrados
  Pedido.crear({
    required this.mesaNumero,
    required this.usuarioCamarero,
    this.items = const [],
    this.estado = EstadoPedido.pendiente,
    this.numeroComensales,
    this.notas,
    this.esBuffet = false,
    this.origen = OrigenPedido.camarero,
  })  : total = 0,
        fechaCreacion = DateTime.now(),
        fechaActualizacion = DateTime.now() {
    if (items.isEmpty) {
      items = [];
    }
  }

  /// Verifica si el pedido viene de un cliente (QR/web)
  @ignore
  bool get esDeCliente => origen == OrigenPedido.qr || origen == OrigenPedido.web;

  /// Obtiene etiqueta para mostrar en cocina
  @ignore
  String get etiquetaOrigen {
    switch (origen) {
      case OrigenPedido.qr:
        return 'PEDIDO QR';
      case OrigenPedido.web:
        return 'PEDIDO WEB';
      case OrigenPedido.camarero:
        return '';
    }
  }

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
  @ignore
  bool get estaActivo =>
      estado != EstadoPedido.cancelado && estado != EstadoPedido.pagado;

  /// Obtiene los items agrupados por destino
  @ignore
  Map<int?, List<ItemPedido>> get itemsPorDestino {
    final Map<int?, List<ItemPedido>> agrupados = {};
    for (final item in items) {
      agrupados.putIfAbsent(item.destinoId, () => []).add(item);
    }
    return agrupados;
  }

  /// Obtiene los items de un destino específico
  List<ItemPedido> itemsParaDestino(int destinoId) {
    return items.where((item) => item.destinoId == destinoId).toList();
  }

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
      'origen': origen.name,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaActualizacion': fechaActualizacion.toIso8601String(),
      'fechaCompletado': fechaCompletado?.toIso8601String(),
      'fechaInicioPreparacion': fechaInicioPreparacion?.toIso8601String(),
      'fechaListo': fechaListo?.toIso8601String(),
    };
  }

  /// Crea un Pedido desde un Map JSON
  factory Pedido.fromJson(Map<String, dynamic> json) {
    final pedido = Pedido()
      ..mesaNumero = json['mesaNumero'] as int
      ..items = (json['items'] as List<dynamic>?)
              ?.map((item) => ItemPedido.fromJson(item as Map<String, dynamic>))
              .toList() ??
          []
      ..estado = EstadoPedido.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => EstadoPedido.pendiente,
      )
      ..total = (json['total'] as num?)?.toDouble() ?? 0
      ..usuarioCamarero = json['usuarioCamarero'] as String
      ..numeroComensales = json['numeroComensales'] as int?
      ..notas = json['notas'] as String?
      ..esBuffet = json['esBuffet'] as bool? ?? false
      ..origen = OrigenPedido.values.firstWhere(
        (e) => e.name == json['origen'],
        orElse: () => OrigenPedido.camarero,
      )
      ..fechaCreacion = json['fechaCreacion'] != null
          ? DateTime.parse(json['fechaCreacion'] as String)
          : DateTime.now()
      ..fechaActualizacion = json['fechaActualizacion'] != null
          ? DateTime.parse(json['fechaActualizacion'] as String)
          : DateTime.now()
      ..fechaCompletado = json['fechaCompletado'] != null
          ? DateTime.parse(json['fechaCompletado'] as String)
          : null
      ..fechaInicioPreparacion = json['fechaInicioPreparacion'] != null
          ? DateTime.parse(json['fechaInicioPreparacion'] as String)
          : null
      ..fechaListo = json['fechaListo'] != null
          ? DateTime.parse(json['fechaListo'] as String)
          : null;

    if (json['id'] != null) {
      final v = json['id'];
      pedido.id = (v is int) ? v : int.tryParse(v.toString());
    }

    return pedido;
  }

  @override
  String toString() =>
      'Pedido(id: $id, mesa: $mesaNumero, estado: ${estado.name}, total: $total)';
}
