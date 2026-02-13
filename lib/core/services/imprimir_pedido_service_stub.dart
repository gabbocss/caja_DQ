import '../models/models.dart';

/// Stub de impresión (web o cuando no hay impresoras): no hace nada.
class ImprimirPedidoService {
  static final ImprimirPedidoService _instance = ImprimirPedidoService._();
  static ImprimirPedidoService get instance => _instance;

  ImprimirPedidoService._();

  /// No-op en web/stub.
  Future<void> imprimirPedido(Pedido pedido) async {}
}
