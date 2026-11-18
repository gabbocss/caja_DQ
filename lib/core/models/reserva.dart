import 'package:isar_community/isar.dart';

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

  /// Comensales: cubiertos (fuera de buffet) o menús buffet al asignar mesa.
  late int numeroPersonas;

  @Index()
  late DateTime fechaHoraLlegada;

  /// Alergias, trona, celíaco, etc.
  late String alergiasNotas;

  /// Teléfono opcional (ficha cliente). zz* al final para no reordenar IDs Isar.
  @Name('zzTelefono')
  String telefono = '';

  /// Id de cliente en PostgreSQL (solo si hay teléfono).
  @Name('zzClienteId')
  int? clienteId;

  /// Si true, toJson incluye `telefono` aunque esté vacío (para borrarlo en VPS).
  @ignore
  bool sincronizarTelefono = false;

  @Enumerated(EnumType.name)
  @Index()
  EstadoReserva estado = EstadoReserva.pendiente;

  late List<ItemReserva> itemsReservados;

  /// Mesa asignada al sentar al cliente (null si aún pendiente).
  int? mesaAsignada;

  late DateTime fechaCreacion;
  late DateTime fechaActualizacion;

  /// Campo legacy del VPS (ya no se usa para sync; se ignora en Isar).
  @ignore
  DateTime? sincronizadaEnCajaAt;

  Reserva();

  Reserva.crear({
    required this.nombreCliente,
    required this.numeroPersonas,
    required this.fechaHoraLlegada,
    this.alergiasNotas = '',
    this.telefono = '',
    this.clienteId,
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

  /// Compatibilidad con esquema Isar generado (campo legacy; no usar en UI).
  bool get sincronizadaEnCaja => sincronizadaEnCajaAt != null;

  double get totalItemsReservados =>
      itemsReservados.fold<double>(0, (s, i) => s + i.subtotal);

  /// Instante UTC correcto a partir de la hora de pared del dispositivo.
  static String _fechaHaciaApi(DateTime dt) {
    final local = dt.isUtc ? dt.toLocal() : dt;
    return local.toUtc().toIso8601String();
  }

  /// Siempre hora local del dispositivo para UI / franjas.
  static DateTime _fechaDesdeApi(String raw) {
    return DateTime.parse(raw).toLocal();
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'nombreCliente': nombreCliente,
        'numeroPersonas': numeroPersonas,
        'fechaHoraLlegada': _fechaHaciaApi(fechaHoraLlegada),
        'alergiasNotas': alergiasNotas,
        // Solo si hay número o el formulario pidió sincronizar (evitar borrar en VPS).
        if (sincronizarTelefono || telefono.trim().isNotEmpty)
          'telefono': telefono.trim(),
        if (clienteId != null) 'clienteId': clienteId,
        'estado': estado.name,
        'itemsReservados':
            itemsReservados.map((i) => i.toJson()).toList(),
        'mesaAsignada': mesaAsignada,
        'fechaCreacion': _fechaHaciaApi(fechaCreacion),
        'fechaActualizacion': _fechaHaciaApi(fechaActualizacion),
      };

  factory Reserva.fromJson(Map<String, dynamic> json) {
    final reserva = Reserva()
      ..nombreCliente = json['nombreCliente'] as String
      ..numeroPersonas = json['numeroPersonas'] as int
      ..fechaHoraLlegada =
          _fechaDesdeApi(json['fechaHoraLlegada'] as String)
      ..alergiasNotas = json['alergiasNotas'] as String? ?? ''
      ..telefono = json['telefono'] as String? ?? ''
      ..clienteId = json['clienteId'] as int?
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
          ? _fechaDesdeApi(json['fechaCreacion'] as String)
          : DateTime.now()
      ..fechaActualizacion = json['fechaActualizacion'] != null
          ? _fechaDesdeApi(json['fechaActualizacion'] as String)
          : DateTime.now();

    final syncAt = json['sincronizadaEnCajaAt'];
    if (syncAt != null) {
      reserva.sincronizadaEnCajaAt =
          _fechaDesdeApi(syncAt as String);
    }

    final rawId = json['id'];
    if (rawId != null) {
      reserva.id = rawId is int ? rawId : int.tryParse(rawId.toString());
    }
    return reserva;
  }
}
