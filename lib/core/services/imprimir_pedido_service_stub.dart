import '../models/models.dart';

/// Stub de impresión (web o cuando no hay impresoras): no hace nada.
class ImprimirPedidoService {
  static final ImprimirPedidoService _instance = ImprimirPedidoService._();
  static ImprimirPedidoService get instance => _instance;

  ImprimirPedidoService._();

  /// No-op en web/stub.
  Future<void> imprimirPedido(Pedido pedido) async {}

  /// No-op en web/stub (impresora buffet).
  Future<void> imprimirPedidoEnImpresora(
    Pedido pedido,
    String host,
    int port,
  ) async {}

  /// No-op en web/stub (ticket cuenta mesa).
  Future<void> imprimirTicketCuentaMesa(
    int mesaNumero,
    List<ItemPedido> items,
    double total,
  ) async {}
}
