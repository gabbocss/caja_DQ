import 'package:flutter/foundation.dart';

import '../../../../core/core.dart';
import '../pages/pedidos_page.dart';

/// Estado de apertura de una mesa (cubiertos o buffet)
class AperturaMesa {
  final int cubiertos;
  final int adultosBuffet;
  final int ninosBuffet;

  const AperturaMesa({
    this.cubiertos = 0,
    this.adultosBuffet = 0,
    this.ninosBuffet = 0,
  });

  bool get tieneApertura => cubiertos > 0 || adultosBuffet > 0 || ninosBuffet > 0;
}

/// Provider para el flujo móvil: Mesas → Categorías → Platos
/// Mantiene carrito y apertura por mesa; envía pedidos vía DB o API según plataforma
class PedidosMobileProvider extends ChangeNotifier {
  List<Mesa> _mesas = [];
  Set<int> _mesasConCuentaAbierta = {};
  final Map<int, List<ItemCarrito>> _carritoByMesa = {};
  final Map<int, AperturaMesa> _aperturaByMesa = {};
  final Map<int, List<Pedido>> _cuentaByMesa = {};
  List<DestinoImpresion> _destinos = [];
  bool _enviando = false;
  String? _error;

  List<Mesa> get mesas => _mesas;
  Set<int> get mesasConCuentaAbierta => _mesasConCuentaAbierta;
  List<DestinoImpresion> get destinos => _destinos;
  bool get enviando => _enviando;
  String? get error => _error;

  List<ItemCarrito> carritoMesa(int numeroMesa) =>
      _carritoByMesa[numeroMesa] ?? [];

  AperturaMesa aperturaMesa(int numeroMesa) =>
      _aperturaByMesa[numeroMesa] ?? const AperturaMesa();

  List<Pedido> cuentaMesa(int numeroMesa) =>
      _cuentaByMesa[numeroMesa] ?? [];

  /// Carga lista de mesas (desde DB o API)
  Future<void> loadMesas() async {
    try {
      if (sl.isRegistered<ApiClient>()) {
        _mesas = await sl<ApiClient>().obtenerMesas();
      } else {
        _mesas = await DatabaseService.instance.obtenerMesas();
      }
      await loadMesasConCuentaAbierta();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Mesas con al menos un pedido no pagado
  Future<void> loadMesasConCuentaAbierta() async {
    try {
      if (sl.isRegistered<ApiClient>()) {
        final list = await sl<ApiClient>().obtenerMesasConCuentaAbierta();
        _mesasConCuentaAbierta = list.toSet();
      } else {
        final list = await DatabaseService.instance.obtenerMesasConCuentaAbierta();
        _mesasConCuentaAbierta = list.toSet();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loadMesasConCuentaAbierta: $e');
    }
  }

  /// Cuenta (pedidos no pagados) de una mesa
  Future<void> loadCuentaMesa(int numeroMesa) async {
    try {
      List<Pedido> pedidos;
      if (sl.isRegistered<ApiClient>()) {
        pedidos = await sl<ApiClient>().obtenerCuentaMesa(numeroMesa);
      } else {
        pedidos = await DatabaseService.instance.obtenerCuentaMesa(numeroMesa);
      }
      _cuentaByMesa[numeroMesa] = pedidos;
      notifyListeners();
    } catch (e) {
      _cuentaByMesa[numeroMesa] = [];
      notifyListeners();
    }
  }

  /// Carga destinos activos (solo DB; en cliente no se usan para imprimir pero sí para nombres)
  Future<void> loadDestinos() async {
    try {
      _destinos = await DatabaseService.instance.obtenerDestinosActivos();
      notifyListeners();
    } catch (e) {
      _destinos = [];
      notifyListeners();
    }
  }

  /// Marca apertura de mesa (cubiertos o buffet) y opcionalmente añade ítems al carrito
  void setAperturaMesa(int numeroMesa, AperturaMesa apertura, {List<ItemCarrito>? itemsIniciales}) {
    _aperturaByMesa[numeroMesa] = apertura;
    if (itemsIniciales != null && itemsIniciales.isNotEmpty) {
      _carritoByMesa[numeroMesa] = List.from(itemsIniciales);
    }
    notifyListeners();
  }

  void addToCart(int numeroMesa, Producto producto) {
    _carritoByMesa.putIfAbsent(numeroMesa, () => []);
    final lista = _carritoByMesa[numeroMesa]!;
    lista.add(ItemCarrito(producto: producto, cantidad: 1, orden: 1));
    notifyListeners();
  }

  void removeFromCart(int numeroMesa, int index) {
    final lista = _carritoByMesa[numeroMesa];
    if (lista != null && index >= 0 && index < lista.length) {
      lista.removeAt(index);
      notifyListeners();
    }
  }

  void changeOrder(int numeroMesa, int index, int orden) {
    final lista = _carritoByMesa[numeroMesa];
    if (lista != null && index >= 0 && index < lista.length) {
      lista[index].orden = orden;
      notifyListeners();
    }
  }

  /// Envía el pedido de la mesa (DB o API según esté registrado ApiClient)
  Future<bool> sendOrder(int numeroMesa) async {
    final carrito = carritoMesa(numeroMesa);
    final apertura = aperturaMesa(numeroMesa);
    final tieneApertura = apertura.tieneApertura;
    if (carrito.isEmpty && !tieneApertura) return false;

    _enviando = true;
    _error = null;
    notifyListeners();

    try {
      final itemsPorDestino = <int?, List<ItemPedido>>{};
      for (final item in carrito) {
        final destinoId = item.producto.destinoId;
        String? nombreDestino;
        if (destinoId != null) {
          final d = _destinos.where((x) => x.id == destinoId).firstOrNull;
          nombreDestino = d?.nombre;
        }
        itemsPorDestino.putIfAbsent(destinoId, () => []).add(
          ItemPedido.crear(
            productoId: item.producto.id ?? 0,
            nombreProducto: item.producto.nombre,
            precioUnitario: item.producto.precio,
            cantidad: item.cantidad,
            destinoId: destinoId,
            nombreDestino: nombreDestino,
            orden: item.orden,
          ),
        );
      }
      final todosItems = itemsPorDestino.values.expand((x) => x).toList();
      final esBuffet = apertura.adultosBuffet > 0 || apertura.ninosBuffet > 0;
      final pedido = Pedido.crear(
        mesaNumero: numeroMesa,
        usuarioCamarero: 'Mesero',
        items: todosItems,
        esBuffet: esBuffet,
        numeroComensales: esBuffet
            ? (apertura.adultosBuffet + apertura.ninosBuffet)
            : apertura.cubiertos,
      );
      pedido.calcularTotal();

      if (sl.isRegistered<ApiClient>()) {
        await sl<ApiClient>().guardarPedido(pedido);
      } else {
        await DatabaseService.instance.guardarPedido(pedido);
        for (final item in pedido.items) {
          if (item.productoId <= 0) continue;
          await DatabaseService.instance.decrementarStock(item.productoId, item.cantidad);
        }
        await DatabaseService.instance.actualizarEstadoMesa(numeroMesa, EstadoMesa.ocupada);
      }

      _carritoByMesa[numeroMesa] = [];
      _aperturaByMesa.remove(numeroMesa);
      await loadCuentaMesa(numeroMesa);
      await loadMesasConCuentaAbierta();
      _enviando = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _enviando = false;
      notifyListeners();
      return false;
    }
  }
}
