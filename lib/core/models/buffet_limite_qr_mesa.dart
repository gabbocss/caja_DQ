import 'package:isar/isar.dart';

part 'buffet_limite_qr_mesa.g.dart';

/// Estado del límite de buffet para pedidos QR por mesa (tipos distintos por ventana + cooldown de envío).
@collection
class BuffetLimiteQrMesa {
  Id? id;

  @Index(unique: true)
  late int mesaNumero;

  /// Índice de ventana de tiempo (según `buffetMinutosVentana` en configuración).
  late int ventanaIdActual;

  /// Ids de producto ya enviados en pedidos QR en la ventana actual (un tipo cuenta una vez).
  late List<int> productosDistintosEnviadosEnVentana;

  /// Último envío de pedido desde cliente QR (cooldown antes del siguiente envío).
  DateTime? fechaUltimoEnvioQr;

  BuffetLimiteQrMesa();
}
