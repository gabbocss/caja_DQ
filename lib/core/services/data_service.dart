import '../models/models.dart';

// Importar implementación según plataforma
export 'data_service_stub.dart'
    if (dart.library.io) 'data_service_impl.dart'
    if (dart.library.html) 'data_service_web.dart';

/// Servicio unificado de acceso a datos
/// 
/// Abstrae la diferencia entre acceso local (Isar) y remoto (API)
/// - En Desktop/Mobile: Usa DatabaseService con Isar
/// - En Web: Usa ApiClient para conectarse al servidor
abstract class DataService {
  // ==================== PRODUCTOS ====================

  /// Obtiene todos los productos
  Future<List<Producto>> obtenerProductos();

  /// Obtiene productos del buffet
  Future<List<Producto>> obtenerProductosBuffet();

  /// Guarda un producto
  Future<int> guardarProducto(Producto producto);

  /// Elimina un producto
  Future<bool> eliminarProducto(int id);

  // ==================== MESAS ====================

  /// Obtiene todas las mesas
  Future<List<Mesa>> obtenerMesas();

  /// Obtiene una mesa por número
  Future<Mesa?> obtenerMesaPorNumero(int numero);

  /// Actualiza el estado de una mesa
  Future<void> actualizarEstadoMesa(int numero, EstadoMesa estado);

  // ==================== PEDIDOS ====================

  /// Obtiene pedidos activos
  Future<List<Pedido>> obtenerPedidosActivos();

  /// Obtiene pedidos por estado
  Future<List<Pedido>> obtenerPedidosPorEstado(EstadoPedido estado);

  /// Obtiene pedidos de una mesa
  Future<List<Pedido>> obtenerPedidosDeMesa(int mesaNumero);

  /// Obtiene el pedido activo de una mesa
  Future<Pedido?> obtenerPedidoActivoDeMesa(int mesaNumero);

  /// Guarda un pedido
  Future<int> guardarPedido(Pedido pedido);

  /// Actualiza el estado de un pedido
  Future<void> actualizarEstadoPedido(int id, EstadoPedido estado);

  /// Stream de pedidos activos (solo disponible en desktop)
  Stream<List<Pedido>>? watchPedidosActivos() => null;

  /// Stream de pedidos de cocina (solo disponible en desktop)
  Stream<List<Pedido>>? watchPedidosCocina() => null;
}
