import '../../../../core/core.dart';
import '../../domain/repositories/pedidos_repository.dart';

/// Implementación del repositorio de Pedidos
/// 
/// Usa el DatabaseService para operaciones de base de datos local
class PedidosRepositoryImpl implements PedidosRepository {
  final DatabaseService _db;

  PedidosRepositoryImpl(this._db);

  @override
  Future<List<Pedido>> obtenerPedidosActivos() async {
    return await _db.obtenerPedidosActivos();
  }

  @override
  Future<List<Pedido>> obtenerPedidosPorEstado(EstadoPedido estado) async {
    return await _db.obtenerPedidosPorEstado(estado);
  }

  @override
  Future<List<Pedido>> obtenerPedidosDeMesa(int mesaNumero) async {
    return await _db.obtenerPedidosDeMesa(mesaNumero);
  }

  @override
  Future<Pedido?> obtenerPedidoActivoDeMesa(int mesaNumero) async {
    return await _db.obtenerPedidoActivoDeMesa(mesaNumero);
  }

  @override
  Future<Pedido?> obtenerPedidoPorId(int id) async {
    return await _db.isar.pedidos.get(id);
  }

  @override
  Future<int> crearPedido(Pedido pedido) async {
    final id = await _db.guardarPedido(pedido);
    // Actualizar el estado de la mesa a ocupada
    await _db.actualizarEstadoMesa(pedido.mesaNumero, EstadoMesa.ocupada);
    return id;
  }

  @override
  Future<void> actualizarPedido(Pedido pedido) async {
    await _db.guardarPedido(pedido);
  }

  @override
  Future<void> actualizarEstadoPedido(int id, EstadoPedido nuevoEstado) async {
    await _db.actualizarEstadoPedido(id, nuevoEstado);
    
    // Si el pedido se completa o cancela, liberar la mesa
    if (nuevoEstado == EstadoPedido.pagado || 
        nuevoEstado == EstadoPedido.cancelado) {
      final pedido = await obtenerPedidoPorId(id);
      if (pedido != null) {
        // Verificar si hay otros pedidos activos en la mesa
        final otrosPedidos = await obtenerPedidosDeMesa(pedido.mesaNumero);
        final tieneOtrosActivos = otrosPedidos.any(
          (p) => p.id != id && p.estaActivo,
        );
        
        if (!tieneOtrosActivos) {
          await _db.actualizarEstadoMesa(pedido.mesaNumero, EstadoMesa.libre);
        }
      }
    }
  }

  @override
  Future<void> agregarItemAPedido(int pedidoId, ItemPedido item) async {
    final pedido = await obtenerPedidoPorId(pedidoId);
    if (pedido != null) {
      pedido.agregarItem(item);
      await _db.guardarPedido(pedido);
    }
  }

  @override
  Future<void> eliminarItemDePedido(int pedidoId, int itemIndex) async {
    final pedido = await obtenerPedidoPorId(pedidoId);
    if (pedido != null) {
      pedido.eliminarItem(itemIndex);
      await _db.guardarPedido(pedido);
    }
  }

  @override
  Future<void> cancelarPedido(int id) async {
    await actualizarEstadoPedido(id, EstadoPedido.cancelado);
  }

  @override
  Stream<List<Pedido>> watchPedidosActivos() {
    return _db.watchPedidosActivos();
  }
}
