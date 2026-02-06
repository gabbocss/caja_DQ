import '../../../../core/constants/app_constants.dart';

/// Representa una sesión de buffet para una mesa
/// 
/// Gestiona los comensales y productos adicionales del buffet
class BuffetSession {
  /// Número de mesa
  final int mesaNumero;

  /// Cantidad de adultos
  int adultos;

  /// Cantidad de niños (precio reducido)
  int ninos;

  /// Lista de IDs de bebidas adicionales consumidas (no incluidas en buffet)
  List<ItemAdicionalBuffet> adicionales;

  /// Hora de inicio de la sesión
  final DateTime horaInicio;

  /// Hora de fin de la sesión (null si está activa)
  DateTime? horaFin;

  /// Nombre del camarero que atiende
  final String camarero;

  BuffetSession({
    required this.mesaNumero,
    required this.camarero,
    this.adultos = 0,
    this.ninos = 0,
    List<ItemAdicionalBuffet>? adicionales,
  })  : adicionales = adicionales ?? [],
        horaInicio = DateTime.now();

  /// Total de comensales
  int get totalComensales => adultos + ninos;

  /// Costo del buffet (sin adicionales)
  double get costoBuffet =>
      (adultos * AppConstants.precioBuffet) +
      (ninos * AppConstants.precioBuffetNinos);

  /// Costo de los adicionales
  double get costoAdicionales =>
      adicionales.fold(0.0, (sum, item) => sum + item.precio * item.cantidad);

  /// Total a pagar
  double get total => costoBuffet + costoAdicionales;

  /// Verifica si la sesión está activa
  bool get estaActiva => horaFin == null;

  /// Duración de la sesión
  Duration get duracion => 
      (horaFin ?? DateTime.now()).difference(horaInicio);

  /// Agrega un item adicional
  void agregarAdicional(ItemAdicionalBuffet item) {
    final existente = adicionales.indexWhere(
      (a) => a.productoId == item.productoId,
    );
    if (existente >= 0) {
      adicionales[existente].cantidad += item.cantidad;
    } else {
      adicionales.add(item);
    }
  }

  /// Finaliza la sesión
  void finalizarSesion() {
    horaFin = DateTime.now();
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'mesaNumero': mesaNumero,
      'adultos': adultos,
      'ninos': ninos,
      'adicionales': adicionales.map((a) => a.toJson()).toList(),
      'horaInicio': horaInicio.toIso8601String(),
      'horaFin': horaFin?.toIso8601String(),
      'camarero': camarero,
      'costoBuffet': costoBuffet,
      'costoAdicionales': costoAdicionales,
      'total': total,
    };
  }

  /// Crea desde JSON
  factory BuffetSession.fromJson(Map<String, dynamic> json) {
    final session = BuffetSession(
      mesaNumero: json['mesaNumero'] as int,
      camarero: json['camarero'] as String,
      adultos: json['adultos'] as int? ?? 0,
      ninos: json['ninos'] as int? ?? 0,
      adicionales: (json['adicionales'] as List<dynamic>?)
          ?.map((a) => ItemAdicionalBuffet.fromJson(a as Map<String, dynamic>))
          .toList(),
    );

    if (json['horaFin'] != null) {
      session.horaFin = DateTime.parse(json['horaFin'] as String);
    }

    return session;
  }
}

/// Item adicional consumido durante el buffet
/// (bebidas o productos no incluidos)
class ItemAdicionalBuffet {
  final int productoId;
  final String nombre;
  final double precio;
  int cantidad;

  ItemAdicionalBuffet({
    required this.productoId,
    required this.nombre,
    required this.precio,
    this.cantidad = 1,
  });

  double get subtotal => precio * cantidad;

  Map<String, dynamic> toJson() {
    return {
      'productoId': productoId,
      'nombre': nombre,
      'precio': precio,
      'cantidad': cantidad,
    };
  }

  factory ItemAdicionalBuffet.fromJson(Map<String, dynamic> json) {
    return ItemAdicionalBuffet(
      productoId: json['productoId'] as int,
      nombre: json['nombre'] as String,
      precio: (json['precio'] as num).toDouble(),
      cantidad: json['cantidad'] as int? ?? 1,
    );
  }
}
