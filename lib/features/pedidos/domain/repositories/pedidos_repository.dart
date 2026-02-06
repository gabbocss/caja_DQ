import '../../../../core/models/models.dart';

/// Interfaz del repositorio de Pedidos
/// 
/// Define el contrato para las operaciones de pedidos
/// que deben ser implementadas por la capa de datos.
abstract class PedidosRepository {
  /// Obtiene todos los pedidos activos
  Future<List<Pedido>> obtenerPedidosActivos();

  /// Obtiene pedidos por estado específico
  Future<List<Pedido>> obtenerPedidosPorEstado(EstadoPedido estado);

  /// Obtiene todos los pedidos de una mesa
  Future<List<Pedido>> obtenerPedidosDeMesa(int mesaNumero);

  /// Obtiene el pedido activo de una mesa (si existe)
  Future<Pedido?> obtenerPedidoActivoDeMesa(int mesaNumero);

  /// Obtiene un pedido por su ID
  Future<Pedido?> obtenerPedidoPorId(int id);

  /// Crea un nuevo pedido
  Future<int> crearPedido(Pedido pedido);

  /// Actualiza un pedido existente
  Future<void> actualizarPedido(Pedido pedido);

  /// Actualiza el estado de un pedido
  Future<void> actualizarEstadoPedido(int id, EstadoPedido nuevoEstado);

  /// Agrega un item a un pedido existente
  Future<void> agregarItemAPedido(int pedidoId, ItemPedido item);

  /// Elimina un item de un pedido
  Future<void> eliminarItemDePedido(int pedidoId, int itemIndex);

  /// Cancela un pedido
  Future<void> cancelarPedido(int id);

  /// Stream de pedidos activos para actualizaciones en tiempo real
  Stream<List<Pedido>> watchPedidosActivos();
}
