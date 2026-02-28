import '../../../../core/models/models.dart';

/// Interfaz del repositorio de Cocina
/// 
/// Define las operaciones específicas para la vista de cocina
abstract class CocinaRepository {
  /// Obtiene los pedidos pendientes y en preparación
  Future<List<Pedido>> obtenerPedidosCocina();

  /// Marca un pedido como "en preparación"
  Future<void> iniciarPreparacion(int pedidoId);

  /// Marca un pedido como "listo para servir"
  Future<void> marcarListo(int pedidoId);

  /// Actualiza el estado de un item específico
  Future<void> actualizarEstadoItem(
    int pedidoId, 
    int itemIndex, 
    EstadoPedido nuevoEstado,
  );

  /// Stream de pedidos para actualizaciones en tiempo real
  Stream<List<Pedido>> watchPedidosCocina();

  /// Imprime un ticket de cocina (plato + mesa). En web llama al servidor; en desktop imprime local.
  /// [useBuffetPrinter] Si true y la configuración buffet tiene impresora buffet, imprime allí.
  Future<void> imprimirTicketCocina(
    int mesaNumero,
    String nombreProducto,
    int productoId,
    int cantidad,
    int? destinoId,
    double precioUnitario, {
    bool useBuffetPrinter = false,
  });
}
