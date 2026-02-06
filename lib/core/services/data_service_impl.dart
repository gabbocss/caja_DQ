// Implementación de DataService para plataformas no-web (Desktop/Mobile)
// Usa DatabaseService con Isar
library;

import '../database/database_service.dart';
import '../models/models.dart';
import '../di/injection_container.dart';
import 'data_service.dart';

/// Obtiene la instancia del servicio para Desktop/Mobile
DataService getDataServiceInstance() {
  if (sl.isRegistered<DatabaseService>()) {
    return LocalDataService(sl<DatabaseService>());
  }
  throw StateError('DataService no disponible. ¿Se inicializaron las dependencias?');
}

/// Implementación del DataService para Desktop/Mobile usando Isar
class LocalDataService implements DataService {
  final DatabaseService _db;

  LocalDataService(this._db);

  @override
  Future<List<Producto>> obtenerProductos() => _db.obtenerProductos();

  @override
  Future<List<Producto>> obtenerProductosBuffet() => _db.obtenerProductosBuffet();

  @override
  Future<int> guardarProducto(Producto producto) => _db.guardarProducto(producto);

  @override
  Future<bool> eliminarProducto(int id) => _db.eliminarProducto(id);

  @override
  Future<List<Mesa>> obtenerMesas() => _db.obtenerMesas();

  @override
  Future<Mesa?> obtenerMesaPorNumero(int numero) => _db.obtenerMesaPorNumero(numero);

  @override
  Future<void> actualizarEstadoMesa(int numero, EstadoMesa estado) =>
      _db.actualizarEstadoMesa(numero, estado);

  @override
  Future<List<Pedido>> obtenerPedidosActivos() => _db.obtenerPedidosActivos();

  @override
  Future<List<Pedido>> obtenerPedidosPorEstado(EstadoPedido estado) =>
      _db.obtenerPedidosPorEstado(estado);

  @override
  Future<List<Pedido>> obtenerPedidosDeMesa(int mesaNumero) =>
      _db.obtenerPedidosDeMesa(mesaNumero);

  @override
  Future<Pedido?> obtenerPedidoActivoDeMesa(int mesaNumero) =>
      _db.obtenerPedidoActivoDeMesa(mesaNumero);

  @override
  Future<int> guardarPedido(Pedido pedido) => _db.guardarPedido(pedido);

  @override
  Future<void> actualizarEstadoPedido(int id, EstadoPedido estado) =>
      _db.actualizarEstadoPedido(id, estado);

  @override
  Stream<List<Pedido>>? watchPedidosActivos() => _db.watchPedidosActivos();

  @override
  Stream<List<Pedido>>? watchPedidosCocina() => _db.watchPedidosCocina();
}
