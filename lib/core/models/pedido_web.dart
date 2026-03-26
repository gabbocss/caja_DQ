/// Versión del modelo Pedido e ItemPedido para compilación Web (sin Isar).
/// Los números se parsean de forma tolerante (int o double desde JSON) para evitar fallos en el runtime JS.

enum EstadoPedido {
  pendiente,
  preparando,
  listo,
  servido,
  cancelado,
  pagado,
}

enum OrigenPedido {
  camarero,
  qr,
  web,
}

class ItemPedido {
  late int productoId;
  late String nombreProducto;
  late double precioUnitario;
  late int cantidad;
  String? notas;
  int? destinoId;
  String? nombreDestino;
  EstadoPedido estadoItem = EstadoPedido.pendiente;
  DateTime? fechaInicioPreparacionItem;
  DateTime? fechaListoItem;
  int orden = 1;

  ItemPedido();

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

  double get subtotal => precioUnitario * cantidad;

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

  factory ItemPedido.fromJson(Map<String, dynamic> json) {
    return ItemPedido()
      ..productoId = _intFromJson(json['productoId'], 0)
      ..nombreProducto = json['nombreProducto'] as String
      ..precioUnitario = (json['precioUnitario'] as num?)?.toDouble() ?? 0.0
      ..cantidad = _intFromJson(json['cantidad'], 1)
      ..notas = json['notas'] as String?
      ..destinoId = _intOrNullFromJson(json['destinoId'])
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
      ..orden = _intFromJson(json['orden'], 1);
  }
}

int _intFromJson(dynamic v, int def) {
  if (v == null) return def;
  if (v is int) return v;
  if (v is num) return v.toInt();
  final parsed = int.tryParse(v.toString());
  return parsed ?? def;
}

int? _intOrNullFromJson(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

class Pedido {
  int? id;
  late int mesaNumero;
  late List<ItemPedido> items;
  late EstadoPedido estado;
  late double total;
  late String usuarioCamarero;
  int? numeroComensales;
  String? notas;
  late bool esBuffet;
  OrigenPedido origen = OrigenPedido.camarero;
  late DateTime fechaCreacion;
  late DateTime fechaActualizacion;
  DateTime? fechaCompletado;
  DateTime? fechaInicioPreparacion;
  DateTime? fechaListo;

  Pedido();

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

  bool get esDeCliente => origen == OrigenPedido.qr || origen == OrigenPedido.web;

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

  void calcularTotal() {
    total = items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  void agregarItem(ItemPedido item) {
    items.add(item);
    calcularTotal();
    fechaActualizacion = DateTime.now();
  }

  void eliminarItem(int index) {
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
      calcularTotal();
      fechaActualizacion = DateTime.now();
    }
  }

  bool get estaActivo =>
      estado != EstadoPedido.cancelado && estado != EstadoPedido.pagado;

  Map<int?, List<ItemPedido>> get itemsPorDestino {
    final Map<int?, List<ItemPedido>> agrupados = {};
    for (final item in items) {
      agrupados.putIfAbsent(item.destinoId, () => []).add(item);
    }
    return agrupados;
  }

  List<ItemPedido> itemsParaDestino(int destinoId) {
    return items.where((item) => item.destinoId == destinoId).toList();
  }

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

  factory Pedido.fromJson(Map<String, dynamic> json) {
    final pedido = Pedido()
      ..mesaNumero = _intFromJson(json['mesaNumero'], 1)
      ..items = (json['items'] as List<dynamic>?)
              ?.map((item) => ItemPedido.fromJson(item as Map<String, dynamic>))
              .toList() ??
          []
      ..estado = EstadoPedido.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => EstadoPedido.pendiente,
      )
      ..total = (json['total'] as num?)?.toDouble() ?? 0
      ..usuarioCamarero = json['usuarioCamarero'] as String? ?? ''
      ..numeroComensales = _intOrNullFromJson(json['numeroComensales'])
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
      pedido.id = _intOrNullFromJson(json['id']);
    }

    return pedido;
  }

  @override
  String toString() =>
      'Pedido(id: $id, mesa: $mesaNumero, estado: ${estado.name}, total: $total)';
}
