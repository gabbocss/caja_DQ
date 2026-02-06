import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../../core/core.dart';
import '../../domain/repositories/pedidos_repository.dart';
import '../../data/repositories/pedidos_repository_impl.dart';

/// Provider para manejar el estado de Pedidos
///
/// Proporciona acceso reactivo a los pedidos y operaciones CRUD
class PedidosProvider extends ChangeNotifier {
  final PedidosRepository _repository;

  List<Pedido> _pedidos = [];
  List<Producto> _productos = [];
  bool _cargando = false;
  String? _error;
  StreamSubscription? _pedidosSubscription;
  StreamSubscription? _productosSubscription;

  /// Lista actual de pedidos activos
  List<Pedido> get pedidos => _pedidos;

  /// Lista de productos disponibles
  List<Producto> get productos => _productos;

  /// Indica si hay una operación en progreso
  bool get cargando => _cargando;

  /// Mensaje de error (null si no hay error)
  String? get error => _error;

  /// Constructor que inicializa con el repositorio
  PedidosProvider({PedidosRepository? repository})
      : _repository = repository ??
          PedidosRepositoryImpl(DatabaseService.instance) {
    _iniciarEscucha();
    _iniciarEscuchaProductos();
  }

  /// Inicia la escucha de cambios en los pedidos
  void _iniciarEscucha() {
    _pedidosSubscription?.cancel();
    _pedidosSubscription = _repository.watchPedidosActivos().listen(
      (pedidos) {
        _pedidos = pedidos;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  /// Inicia la escucha de cambios en los productos (tiempo real)
  void _iniciarEscuchaProductos() {
    _productosSubscription?.cancel();
    if (kIsWeb && sl.isRegistered<ApiClient>()) {
      _cargarProductos();
      return;
    }
    try {
      final db = DatabaseService.instance;
      _productosSubscription = db.watchProductos().listen(
        (productos) {
          _productos = productos;
          _error = null;
          notifyListeners();
          debugPrint('🔄 Productos actualizados: ${productos.length} productos');
        },
        onError: (e) {
          debugPrint('Error en stream de productos: $e');
          _error = e.toString();
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Error al iniciar escucha de productos: $e');
      _cargarProductos();
    }
  }

  /// Carga los productos disponibles (fallback o Web desde API)
  Future<void> _cargarProductos() async {
    if (kIsWeb && sl.isRegistered<ApiClient>()) {
      try {
        _productos = await sl<ApiClient>().obtenerProductos();
        _error = null;
        notifyListeners();
      } catch (e) {
        debugPrint('Error cargando productos (Web): $e');
        _error = e.toString();
        notifyListeners();
      }
      return;
    }
    try {
      final db = DatabaseService.instance;
      _productos = await db.obtenerProductos();
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando productos: $e');
    }
  }

  /// Recarga la lista de pedidos y productos
  Future<void> recargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _pedidos = await _repository.obtenerPedidosActivos();
      await _cargarProductos();
    } catch (e) {
      _error = e.toString();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Crea un nuevo pedido
  Future<int?> crearPedido({
    required int mesaNumero,
    required String camarero,
    int? comensales,
    List<ItemPedido>? items,
    bool esBuffet = false,
  }) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final pedidoExistente = await _repository.obtenerPedidoActivoDeMesa(mesaNumero);
      if (pedidoExistente != null) {
        _error = 'La mesa $mesaNumero ya tiene un pedido activo';
        _cargando = false;
        notifyListeners();
        return null;
      }

      final pedido = Pedido.crear(
        mesaNumero: mesaNumero,
        usuarioCamarero: camarero,
        numeroComensales: comensales,
        esBuffet: esBuffet,
      );

      if (items != null) {
        for (final item in items) {
          pedido.agregarItem(item);
        }
      }

      final id = await _repository.crearPedido(pedido);
      return id;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Agrega un item a un pedido existente
  Future<bool> agregarItem(int pedidoId, ItemPedido item) async {
    try {
      await _repository.agregarItemAPedido(pedidoId, item);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Elimina un item de un pedido
  Future<bool> eliminarItem(int pedidoId, int itemIndex) async {
    try {
      await _repository.eliminarItemDePedido(pedidoId, itemIndex);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Actualiza el estado de un pedido
  Future<bool> actualizarEstado(int pedidoId, EstadoPedido nuevoEstado) async {
    try {
      await _repository.actualizarEstadoPedido(pedidoId, nuevoEstado);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Obtiene pedidos por mesa
  Future<List<Pedido>> obtenerPedidosDeMesa(int mesaNumero) async {
    return await _repository.obtenerPedidosDeMesa(mesaNumero);
  }

  @override
  void dispose() {
    _pedidosSubscription?.cancel();
    _productosSubscription?.cancel();
    super.dispose();
  }
}
