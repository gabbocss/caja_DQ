/// Stub de DatabaseService para compilación Web.
/// La app web (cocina) solo usa la API; no tiene base de datos local.

import '../models/models.dart';

Never _unsupported() =>
    throw UnsupportedError('DatabaseService no disponible en web');

/// Stub: mismo nombre que el servicio real para que el DI y el resto del código compilen.
class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();

  DatabaseService._();

  dynamic get isar => _unsupported();
  bool get isInitialized => false;

  Future<void> initialize() async {}

  Future<void> close() async {}
  Future<void> clearAll() async => _unsupported();

  Future<List<Producto>> obtenerProductos() async => _unsupported();
  Future<List<Producto>> obtenerProductosPorCategoria(String categoria) async =>
      _unsupported();
  Future<List<Producto>> obtenerProductosBuffet() async => _unsupported();
  Future<int> guardarProducto(Producto producto) async => _unsupported();
  Future<bool> eliminarProducto(int id) async => _unsupported();

  Future<List<Mesa>> obtenerMesas() async => _unsupported();
  Future<String> getQrTokenForMesa(int numeroMesa) async => _unsupported();
  Future<int?> getMesaNumeroPorQrToken(String token) async => _unsupported();
  Future<void> regenerarQrTokens() async => _unsupported();
  Future<List<Mesa>> obtenerMesasPorEstado(EstadoMesa estado) async =>
      _unsupported();
  Future<Mesa?> obtenerMesaPorNumero(int numero) async => _unsupported();
  Future<void> actualizarEstadoMesa(int numero, EstadoMesa nuevoEstado) async =>
      _unsupported();
  Future<void> liberarMesa(int numeroMesa, {bool isBuffetClose = false}) async =>
      _unsupported();
  Future<int> guardarMesa(Mesa mesa) async => _unsupported();

  Future<List<Pedido>> obtenerPedidosActivos() async => _unsupported();
  Future<List<Pedido>> obtenerPedidosPorEstado(EstadoPedido estado) async =>
      _unsupported();
  Future<List<Pedido>> obtenerPedidosEntreFechas(DateTime desde, DateTime hasta) async =>
      _unsupported();
  Future<List<Pedido>> obtenerPedidosDeMesa(int mesaNumero) async =>
      _unsupported();
  Future<Pedido?> obtenerPedidoActivoDeMesa(int mesaNumero) async =>
      _unsupported();
  Future<List<Pedido>> obtenerCuentaMesa(int mesaNumero) async =>
      _unsupported();
  Future<List<int>> obtenerMesasConCuentaAbierta() async => _unsupported();
  Future<int> guardarPedido(Pedido pedido) async => _unsupported();
  Future<void> actualizarEstadoPedido(int id, EstadoPedido nuevoEstado) async =>
      _unsupported();
  Stream<List<Pedido>> watchPedidosActivos() => _unsupported();
  Stream<List<Pedido>> watchPedidosCocina() => _unsupported();

  Future<List<DestinoImpresion>> obtenerDestinos() async => _unsupported();
  Future<List<DestinoImpresion>> obtenerDestinosActivos() async =>
      _unsupported();
  Future<DestinoImpresion?> obtenerDestinoPorId(int id) async => _unsupported();
  Future<DestinoImpresion?> obtenerDestinoPorNombre(String nombre) async =>
      _unsupported();
  Future<int> guardarDestino(DestinoImpresion destino) async => _unsupported();
  Future<bool> eliminarDestino(int id) async => _unsupported();
  Stream<List<DestinoImpresion>> watchDestinos() => _unsupported();

  Future<List<Categoria>> obtenerCategorias() async => _unsupported();
  Future<int> guardarCategoria(Categoria categoria) async => _unsupported();
  Future<bool> eliminarCategoria(int id) async => _unsupported();
  Future<void> renombrarCategoria(int id, String nuevoNombre) async =>
      _unsupported();
  Future<int> contarProductosPorCategoria(String nombreCategoria) async =>
      _unsupported();

  Future<List<Pedido>> obtenerPedidosPorDestino(int destinoId) async =>
      _unsupported();
  Stream<List<Pedido>> watchPedidosPorDestino(int destinoId) => _unsupported();
  Future<void> actualizarEstadoItem(
          int pedidoId, int itemIndex, EstadoPedido nuevoEstado) async =>
      _unsupported();

  Future<Producto?> obtenerProductoPorId(int id) async => _unsupported();
  Future<List<int>> verificarDisponibilidad(List<int> productosIds) async =>
      _unsupported();
  Future<void> actualizarDisponibilidad(int id, bool disponible) async =>
      _unsupported();
  Future<void> actualizarStock(int id, int nuevoStock) async => _unsupported();
  Future<bool> decrementarStock(int id, int cantidad) async => _unsupported();
  Stream<List<Producto>> watchProductos() => _unsupported();

  Future<ConfiguracionBuffet?> obtenerConfiguracionBuffetActiva() async =>
      _unsupported();
  Future<List<ConfiguracionBuffet>> obtenerConfiguracionesBuffet() async =>
      _unsupported();
  Future<int> guardarConfiguracionBuffet(ConfiguracionBuffet config) async =>
      _unsupported();
  Future<bool> eliminarConfiguracionBuffet(int id) async => _unsupported();
  Future<bool> esHorarioBuffet() async => _unsupported();
  Future<double?> obtenerPrecioBuffet(int edad) async => _unsupported();
  Future<void> inicializarConfiguracionBuffetDefecto() async => _unsupported();
}
