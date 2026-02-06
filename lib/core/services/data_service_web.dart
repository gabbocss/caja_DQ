// Implementación de DataService para Web
// Usa ApiClient para conectarse al servidor
library;

import '../network/api_client.dart';
import '../models/models.dart';
import '../di/injection_container.dart';
import 'data_service.dart';

/// Obtiene la instancia del servicio para Web
DataService getDataServiceInstance() {
  if (sl.isRegistered<ApiClient>()) {
    return WebDataService(sl<ApiClient>());
  }
  throw StateError(
    'ApiClient no disponible. Asegúrate de configurar remoteServerUrl '
    'en initializeDependencies().'
  );
}

/// Implementación del DataService para Web usando ApiClient
class WebDataService implements DataService {
  final ApiClient _api;

  WebDataService(this._api);

  @override
  Future<List<Producto>> obtenerProductos() => _api.obtenerProductos();

  @override
  Future<List<Producto>> obtenerProductosBuffet() => _api.obtenerProductosBuffet();

  @override
  Future<int> guardarProducto(Producto producto) => _api.guardarProducto(producto);

  @override
  Future<bool> eliminarProducto(int id) => _api.eliminarProducto(id);

  @override
  Future<List<Mesa>> obtenerMesas() => _api.obtenerMesas();

  @override
  Future<Mesa?> obtenerMesaPorNumero(int numero) => _api.obtenerMesaPorNumero(numero);

  @override
  Future<void> actualizarEstadoMesa(int numero, EstadoMesa estado) =>
      _api.actualizarEstadoMesa(numero, estado);

  @override
  Future<List<Pedido>> obtenerPedidosActivos() => _api.obtenerPedidosActivos();

  @override
  Future<List<Pedido>> obtenerPedidosPorEstado(EstadoPedido estado) async {
    final pedidos = await _api.obtenerPedidosActivos();
    return pedidos.where((p) => p.estado == estado).toList();
  }

  @override
  Future<List<Pedido>> obtenerPedidosDeMesa(int mesaNumero) =>
      _api.obtenerPedidosDeMesa(mesaNumero);

  @override
  Future<Pedido?> obtenerPedidoActivoDeMesa(int mesaNumero) async {
    final pedidos = await _api.obtenerPedidosDeMesa(mesaNumero);
    try {
      return pedidos.firstWhere((p) => p.estaActivo);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<int> guardarPedido(Pedido pedido) => _api.guardarPedido(pedido);

  @override
  Future<void> actualizarEstadoPedido(int id, EstadoPedido estado) async {
    await _api.actualizarEstadoPedido(id, estado);
  }

  @override
  Stream<List<Pedido>>? watchPedidosActivos() => null;

  @override
  Stream<List<Pedido>>? watchPedidosCocina() => null;
}
