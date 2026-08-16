import '../models/models.dart';

/// Stub de impresión (web o cuando no hay impresoras): no hace nada.
class ImprimirPedidoService {
  static final ImprimirPedidoService _instance = ImprimirPedidoService._();
  static ImprimirPedidoService get instance => _instance;

  ImprimirPedidoService._();

  /// No-op en web/stub.
  Future<void> imprimirPedido(
    Pedido pedido, {
    String? horaLlegada,
    String? notasReserva,
    String? etiquetaCabecera,
  }) async {}

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
    double total, {
    String? etiquetaCabecera,
  }) async {}

  /// No-op en web/stub (aviso eliminación cocina).
  Future<void> imprimirEliminacionCocina({
    required int mesaNumero,
    required String nombrePlato,
    required int cantidadEliminada,
    int? destinoId,
  }) async {}

  /// No-op en web/stub (ticket pago parcial).
  Future<void> imprimirTicketPagoParcial({
    required int mesaNumero,
    required List<ItemPedido> items,
    required double totalCuenta,
    required double importePagado,
    required double totalRestante,
    required String metodoPagoEtiqueta,
  }) async {}

  /// No-op en web/stub (ticket reserva cocina).
  Future<void> imprimirTicketReservaCocina({
    required int mesaNumero,
    required Reserva reserva,
    String? etiquetaCabecera,
  }) async {}

  /// No-op en web/stub (lista paellas).
  Future<void> imprimirListaPaellas(List<String> lineas) async {}
}
