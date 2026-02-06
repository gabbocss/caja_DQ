import '../../../../core/core.dart';
import '../../domain/repositories/cocina_repository.dart';

/// Implementación del repositorio de Cocina
class CocinaRepositoryImpl implements CocinaRepository {
  final DatabaseService _db;

  CocinaRepositoryImpl(this._db);

  @override
  Future<List<Pedido>> obtenerPedidosCocina() async {
    final pendientes = await _db.obtenerPedidosPorEstado(EstadoPedido.pendiente);
    final preparando = await _db.obtenerPedidosPorEstado(EstadoPedido.preparando);
    
    // Combinar y ordenar por fecha de creación (más antiguos primero)
    final todos = [...pendientes, ...preparando];
    todos.sort((a, b) => a.fechaCreacion.compareTo(b.fechaCreacion));
    
    return todos;
  }

  @override
  Future<void> iniciarPreparacion(int pedidoId) async {
    await _db.actualizarEstadoPedido(pedidoId, EstadoPedido.preparando);
  }

  @override
  Future<void> marcarListo(int pedidoId) async {
    await _db.actualizarEstadoPedido(pedidoId, EstadoPedido.listo);
  }

  @override
  Future<void> actualizarEstadoItem(
    int pedidoId,
    int itemIndex,
    EstadoPedido nuevoEstado,
  ) async {
    final pedido = await _db.isar.pedidos.get(pedidoId);
    if (pedido != null && itemIndex < pedido.items.length) {
      pedido.items[itemIndex].estadoItem = nuevoEstado;
      pedido.fechaActualizacion = DateTime.now();
      
      // Verificar si todos los items están listos
      final todosListos = pedido.items.every(
        (item) => item.estadoItem == EstadoPedido.listo,
      );
      
      if (todosListos) {
        pedido.estado = EstadoPedido.listo;
      } else if (pedido.items.any((item) => 
          item.estadoItem == EstadoPedido.preparando)) {
        pedido.estado = EstadoPedido.preparando;
      }
      
      await _db.guardarPedido(pedido);
    }
  }

  @override
  Stream<List<Pedido>> watchPedidosCocina() {
    return _db.watchPedidosCocina();
  }
}
