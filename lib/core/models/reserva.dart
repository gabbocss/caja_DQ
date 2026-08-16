import 'package:isar/isar.dart';

part 'reserva.g.dart';

/// Estado del ciclo de vida de una reserva.
enum EstadoReserva {
  pendiente,
  sentada,
  cancelada,
  /// Asporto cobrado y entregado (sin mesa).
  cobrada,
}

/// Plato con preparación anticipada (paella, etc.).
@embedded
class ItemReserva {
  late int productoId;
  late String nombreProducto;
  late int cantidad;
  late double precioUnitario;

  ItemReserva();

  ItemReserva.crear({
    required this.productoId,
    required this.nombreProducto,
    required this.cantidad,
    required this.precioUnitario,
  });

  double get subtotal => precioUnitario * cantidad;

  Map<String, dynamic> toJson() => {
        'productoId': productoId,
        'nombreProducto': nombreProducto,
        'cantidad': cantidad,
        'precioUnitario': precioUnitario,
      };

  factory ItemReserva.fromJson(Map<String, dynamic> json) => ItemReserva()
    ..productoId = json['productoId'] as int
    ..nombreProducto = json['nombreProducto'] as String
    ..cantidad = json['cantidad'] as int? ?? 1
    ..precioUnitario = (json['precioUnitario'] as num).toDouble();
}

/// Reserva con comanda anticipada (persistida en Isar y JSON).
@collection
class Reserva {
  Id? id;

  late String nombreCliente;

  /// Define cubiertos al asignar mesa.
  late int numeroPersonas;

  @Index()
  late DateTime fechaHoraLlegada;

  /// Alergias, trona, celíaco, etc.
  late String alergiasNotas;

  @Enumerated(EnumType.name)
  @Index()
  EstadoReserva estado = EstadoReserva.pendiente;

  late List<ItemReserva> itemsReservados;

  /// Mesa asignada al sentar al cliente (null si aún pendiente).
  int? mesaAsignada;

  late DateTime fechaCreacion;
  late DateTime fechaActualizacion;

  Reserva();

  Reserva.crear({
    required this.nombreCliente,
    required this.numeroPersonas,
    required this.fechaHoraLlegada,
    this.alergiasNotas = '',
    this.itemsReservados = const [],
    this.estado = EstadoReserva.pendiente,
    this.mesaAsignada,
  })  : fechaCreacion = DateTime.now(),
        fechaActualizacion = DateTime.now() {
    if (itemsReservados.isEmpty) {
      itemsReservados = [];
    }
  }

  bool get estaPendiente => estado == EstadoReserva.pendiente;

  bool get estaCobrada => estado == EstadoReserva.cobrada;

  double get totalItemsReservados =>
      itemsReservados.fold<double>(0, (s, i) => s + i.subtotal);

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'nombreCliente': nombreCliente,
        'numeroPersonas': numeroPersonas,
        'fechaHoraLlegada': fechaHoraLlegada.toIso8601String(),
        'alergiasNotas': alergiasNotas,
        'estado': estado.name,
        'itemsReservados':
            itemsReservados.map((i) => i.toJson()).toList(),
        'mesaAsignada': mesaAsignada,
        'fechaCreacion': fechaCreacion.toIso8601String(),
        'fechaActualizacion': fechaActualizacion.toIso8601String(),
      };

  factory Reserva.fromJson(Map<String, dynamic> json) {
    final reserva = Reserva()
      ..nombreCliente = json['nombreCliente'] as String
      ..numeroPersonas = json['numeroPersonas'] as int
      ..fechaHoraLlegada =
          DateTime.parse(json['fechaHoraLlegada'] as String)
      ..alergiasNotas = json['alergiasNotas'] as String? ?? ''
      ..estado = EstadoReserva.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => EstadoReserva.pendiente,
      )
      ..itemsReservados = (json['itemsReservados'] as List<dynamic>?)
              ?.map((e) => ItemReserva.fromJson(e as Map<String, dynamic>))
              .toList() ??
          []
      ..mesaAsignada = json['mesaAsignada'] as int?
      ..fechaCreacion = json['fechaCreacion'] != null
          ? DateTime.parse(json['fechaCreacion'] as String)
          : DateTime.now()
      ..fechaActualizacion = json['fechaActualizacion'] != null
          ? DateTime.parse(json['fechaActualizacion'] as String)
          : DateTime.now();

    final rawId = json['id'];
    if (rawId != null) {
      reserva.id = rawId is int ? rawId : int.tryParse(rawId.toString());
    }
    return reserva;
  }
}
