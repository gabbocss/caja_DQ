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

  @override
  Future<void> imprimirTicketCocina(
    int mesaNumero,
    String nombreProducto,
    int productoId,
    int cantidad,
    int? destinoId,
    double precioUnitario, {
    bool useBuffetPrinter = false,
  }) async {
    final item = ItemPedido.crear(
      productoId: productoId,
      nombreProducto: nombreProducto,
      precioUnitario: precioUnitario,
      cantidad: cantidad,
      destinoId: destinoId,
    );
    final pedido = Pedido.crear(
      mesaNumero: mesaNumero,
      usuarioCamarero: 'Buffet',
      items: [item],
    );
    pedido.fechaCreacion = DateTime.now();
    pedido.fechaActualizacion = DateTime.now();

    if (useBuffetPrinter) {
      final configBuffet =
          await _db.obtenerConfiguracionBuffetActiva();
      if (configBuffet != null && configBuffet.tieneImpresoraBuffet) {
        final host = configBuffet.impresoraBuffetIp!.trim();
        final port = configBuffet.impresoraBuffetPuerto ?? 9100;
        await ImprimirPedidoService.instance.imprimirPedidoEnImpresora(
          pedido,
          host,
          port,
        );
        return;
      }
    }
    await ImprimirPedidoService.instance.imprimirPedido(pedido);
  }
}
