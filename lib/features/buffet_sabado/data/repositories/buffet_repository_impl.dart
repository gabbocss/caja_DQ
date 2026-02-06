import '../../../../core/core.dart';
import '../../domain/entities/buffet_session.dart';
import '../../domain/repositories/buffet_repository.dart';

/// Implementación del repositorio de Buffet
class BuffetRepositoryImpl implements BuffetRepository {
  final DatabaseService _db;
  
  /// Sesiones activas en memoria (podría persistirse en Isar si es necesario)
  final Map<int, BuffetSession> _sesionesActivas = {};

  BuffetRepositoryImpl(this._db);

  @override
  Future<void> iniciarSesion(BuffetSession session) async {
    _sesionesActivas[session.mesaNumero] = session;
    
    // Marcar la mesa como ocupada
    await _db.actualizarEstadoMesa(session.mesaNumero, EstadoMesa.ocupada);
  }

  @override
  Future<BuffetSession?> obtenerSesionActiva(int mesaNumero) async {
    return _sesionesActivas[mesaNumero];
  }

  @override
  Future<void> actualizarSesion(BuffetSession session) async {
    _sesionesActivas[session.mesaNumero] = session;
  }

  @override
  Future<Pedido> finalizarSesion(int mesaNumero) async {
    final session = _sesionesActivas[mesaNumero];
    if (session == null) {
      throw Exception('No hay sesión de buffet activa en la mesa $mesaNumero');
    }

    session.finalizarSesion();

    // Crear un pedido con los detalles del buffet
    final pedido = Pedido.crear(
      mesaNumero: mesaNumero,
      usuarioCamarero: session.camarero,
      numeroComensales: session.totalComensales,
      esBuffet: true,
    );

    // Agregar el buffet como item
    if (session.adultos > 0) {
      pedido.agregarItem(ItemPedido.crear(
        productoId: 0, // ID especial para buffet
        nombreProducto: 'Buffet Adulto',
        precioUnitario: AppConstants.precioBuffet,
        cantidad: session.adultos,
      ));
    }

    if (session.ninos > 0) {
      pedido.agregarItem(ItemPedido.crear(
        productoId: 0,
        nombreProducto: 'Buffet Niño',
        precioUnitario: AppConstants.precioBuffetNinos,
        cantidad: session.ninos,
      ));
    }

    // Agregar los adicionales
    for (final adicional in session.adicionales) {
      pedido.agregarItem(ItemPedido.crear(
        productoId: adicional.productoId,
        nombreProducto: adicional.nombre,
        precioUnitario: adicional.precio,
        cantidad: adicional.cantidad,
      ));
    }

    // Marcar como pagado (el buffet se paga al finalizar)
    pedido.estado = EstadoPedido.servido;
    
    // Guardar el pedido
    await _db.guardarPedido(pedido);

    // Limpiar la sesión
    _sesionesActivas.remove(mesaNumero);

    // Liberar la mesa
    await _db.actualizarEstadoMesa(mesaNumero, EstadoMesa.libre);

    return pedido;
  }

  @override
  Future<List<Producto>> obtenerProductosBuffet() async {
    return await _db.obtenerProductosBuffet();
  }

  @override
  Future<List<Producto>> obtenerProductosAdicionales() async {
    final productos = await _db.obtenerProductos();
    return productos.where((p) => !p.esBuffet && p.activo).toList();
  }

  @override
  bool esDiaDeBuffet() {
    // El buffet es los sábados (weekday == 6)
    return DateTime.now().weekday == DateTime.saturday;
  }

  @override
  Future<List<BuffetSession>> obtenerSesionesActivas() async {
    return _sesionesActivas.values.where((s) => s.estaActiva).toList();
  }
}
