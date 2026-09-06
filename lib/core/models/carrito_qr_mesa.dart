import 'package:isar_community/isar.dart';

part 'carrito_qr_mesa.g.dart';

/// Ítem de carrito para pedidos desde cliente QR (buffet).
@embedded
class ItemCarritoQr {
  late int productoId;
  late String nombreProducto;
  late double precioUnitario;
  late int cantidad;
  int? destinoId;
  String? nombreDestino;

  ItemCarritoQr();

  ItemCarritoQr.crear({
    required this.productoId,
    required this.nombreProducto,
    required this.precioUnitario,
    required this.cantidad,
    this.destinoId,
    this.nombreDestino,
  });

  Map<String, dynamic> toJson() => {
        'productoId': productoId,
        'nombreProducto': nombreProducto,
        'precioUnitario': precioUnitario,
        'cantidad': cantidad,
        'destinoId': destinoId,
        'nombreDestino': nombreDestino,
      };
}

/// Carrito comunitario por mesa para clientes QR.
/// Persistente en Isar: sobrevive refrescos de la web y reinicios del servidor.
@collection
class CarritoQrMesa {
  Id? id;

  @Index(unique: true)
  late int mesaNumero;

  late List<ItemCarritoQr> items;

  late DateTime fechaActualizacion;

  CarritoQrMesa();
}

