import 'package:flutter/foundation.dart';

import '../../data/lista_compra_remote_service.dart';
import '../../domain/entities/item_lista_compra.dart';
import '../../domain/entities/precio_producto.dart';
import '../../domain/entities/supermercado.dart';
import '../../domain/entities/unidad_medida.dart';

/// Comparativa de precios de un producto respecto al súper actual.
class ComparativaPrecio {
  final ItemListaCompra producto;
  final PrecioProducto? precioAqui;
  final PrecioProducto? mejorPrecio;
  final Supermercado? mejorSupermercado;
  final bool esMasBaratoAqui;
  final bool sinDatos;

  const ComparativaPrecio({
    required this.producto,
    this.precioAqui,
    this.mejorPrecio,
    this.mejorSupermercado,
    required this.esMasBaratoAqui,
    required this.sinDatos,
  });
}

/// Estado de la lista de la compra: solo memoria de sesión + VPS.
class ListaCompraProvider extends ChangeNotifier {
  ListaCompraProvider({ListaCompraRemoteService? remote})
      : _remote = remote ?? ListaCompraRemoteService();

  final ListaCompraRemoteService _remote;

  List<ItemListaCompra> _items = [];
  List<PrecioProducto> _precios = [];
  List<Supermercado> _supermercados = [];
  int? _supermercadoActualId;
  bool _cargando = false;
  String? _error;
  DateTime? _ultimaOk;

  List<ItemListaCompra> get items => List.unmodifiable(_items);
  List<PrecioProducto> get precios => List.unmodifiable(_precios);
  List<Supermercado> get supermercados => List.unmodifiable(_supermercados);
  int? get supermercadoActualId => _supermercadoActualId;

  List<ItemListaCompra> get pendientesCompra => _items
      .where((i) => i.hayQueComprar && !i.comprado)
      .toList();

  List<ItemListaCompra> get compradosCompra =>
      _items.where((i) => i.hayQueComprar && i.comprado).toList();

  bool get hayAlgoEnCompra =>
      pendientesCompra.isNotEmpty || compradosCompra.isNotEmpty;

  /// Productos marcados «hay que comprar» (pendientes o ya marcados).
  List<ItemListaCompra> get enListaCompra =>
      _items.where((i) => i.hayQueComprar).toList();

  /// Gasto estimado: cantidadMinima × precioEnvase más barato conocido.
  double get gastoEstimadoMinimo {
    var total = 0.0;
    for (final item in enListaCompra) {
      final precios = preciosDeProducto(item.id);
      if (precios.isEmpty) continue;
      var mejor = precios.first;
      for (final p in precios.skip(1)) {
        if (p.precioEnvase < mejor.precioEnvase) mejor = p;
      }
      total += mejor.precioEnvase * item.cantidadMinima;
    }
    return total;
  }

  /// Cuántos de la lista no tienen ningún precio guardado.
  int get productosSinPrecioEnEstimacion => enListaCompra
      .where((i) => preciosDeProducto(i.id).isEmpty)
      .length;

  bool get cargando => _cargando;
  String? get error => _error;
  DateTime? get ultimaActualizacionOk => _ultimaOk;

  Future<void> cargar({bool incluirPreciosYSupers = true}) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _remote.obtenerLista();
      if (incluirPreciosYSupers) {
        _precios = await _remote.obtenerPrecios();
        _supermercados = await _remote.obtenerSupermercados();
        if (_supermercadoActualId != null &&
            !_supermercados.any((s) => s.id == _supermercadoActualId)) {
          _supermercadoActualId = null;
        }
      }
      _ultimaOk = DateTime.now();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('ListaCompraProvider.cargar: $e');
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  void seleccionarSupermercado(int? id) {
    _supermercadoActualId = id;
    notifyListeners();
  }

  List<PrecioProducto> preciosDeProducto(int productoId) =>
      _precios.where((p) => p.productoId == productoId).toList();

  ComparativaPrecio comparativa(ItemListaCompra producto) {
    final preciosProd = preciosDeProducto(producto.id);
    if (preciosProd.isEmpty) {
      return ComparativaPrecio(
        producto: producto,
        esMasBaratoAqui: false,
        sinDatos: true,
      );
    }

    PrecioProducto mejor = preciosProd.first;
    for (final p in preciosProd.skip(1)) {
      if (p.precioPorBase < mejor.precioPorBase) mejor = p;
    }

    PrecioProducto? precioAqui;
    if (_supermercadoActualId != null) {
      for (final p in preciosProd) {
        if (p.supermercadoId == _supermercadoActualId) {
          precioAqui = p;
          break;
        }
      }
    }

    final esMasBaratoAqui = precioAqui != null &&
        (precioAqui.precioPorBase - mejor.precioPorBase).abs() < 0.0001;

    Supermercado? mejorSuper;
    for (final s in _supermercados) {
      if (s.id == mejor.supermercadoId) {
        mejorSuper = s;
        break;
      }
    }

    return ComparativaPrecio(
      producto: producto,
      precioAqui: precioAqui,
      mejorPrecio: mejor,
      mejorSupermercado: mejorSuper,
      esMasBaratoAqui: esMasBaratoAqui,
      sinDatos: false,
    );
  }

  /// Pendientes ordenados: más baratos aquí primero, luego el resto.
  List<ComparativaPrecio> get pendientesConComparativa {
    final lista = pendientesCompra.map(comparativa).toList();
    lista.sort((a, b) {
      if (a.esMasBaratoAqui != b.esMasBaratoAqui) {
        return a.esMasBaratoAqui ? -1 : 1;
      }
      if (a.sinDatos != b.sinDatos) return a.sinDatos ? 1 : -1;
      return a.producto.orden.compareTo(b.producto.orden);
    });
    return lista;
  }

  Future<bool> anadir({
    required String nombre,
    String cantidad = '',
    UnidadBase unidadBase = UnidadBase.unidad,
    double? contenidoCantidad,
    ContenidoUnidad? contenidoUnidad,
    int cantidadMinima = 1,
  }) async {
    final n = nombre.trim();
    if (n.isEmpty) {
      _error = 'El nombre es obligatorio';
      notifyListeners();
      return false;
    }
    try {
      await _remote.guardar(
        ItemListaCompra(
          id: 0,
          nombre: n,
          cantidad: cantidad.trim(),
          unidadBase: unidadBase,
          contenidoCantidad: contenidoCantidad,
          contenidoUnidad:
              contenidoUnidad ?? ContenidoUnidad.paraBase(unidadBase).first,
          cantidadMinima: cantidadMinima < 1 ? 1 : cantidadMinima,
        ),
      );
      await cargar();
      return _error == null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> editar(
    ItemListaCompra item, {
    required String nombre,
    String cantidad = '',
    UnidadBase? unidadBase,
    double? contenidoCantidad,
    bool clearContenido = false,
    ContenidoUnidad? contenidoUnidad,
    int? cantidadMinima,
  }) async {
    final n = nombre.trim();
    if (n.isEmpty) {
      _error = 'El nombre es obligatorio';
      notifyListeners();
      return false;
    }
    try {
      await _remote.guardar(
        item.copyWith(
          nombre: n,
          cantidad: cantidad.trim(),
          unidadBase: unidadBase,
          contenidoCantidad: contenidoCantidad,
          clearContenido: clearContenido,
          contenidoUnidad: contenidoUnidad,
          cantidadMinima: cantidadMinima,
        ),
      );
      await cargar();
      return _error == null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> guardarPrecio({
    required ItemListaCompra producto,
    required int supermercadoId,
    required double precioEnvase,
    required double contenidoCantidad,
    required ContenidoUnidad contenidoUnidad,
  }) async {
    try {
      await _remote.guardarPrecio(
        PrecioProducto(
          id: 0,
          productoId: producto.id,
          supermercadoId: supermercadoId,
          precioEnvase: precioEnvase,
          contenidoCantidad: contenidoCantidad,
          contenidoUnidad: contenidoUnidad,
          unidadBase: producto.unidadBase,
          precioPorBase: calcularPrecioPorBase(
                precioEnvase: precioEnvase,
                contenidoCantidad: contenidoCantidad,
                contenidoUnidad: contenidoUnidad,
                unidadBase: producto.unidadBase,
              ) ??
              0,
        ),
      );
      // Actualiza también el contenido típico del producto.
      await _remote.actualizar(producto.id, {
        'contenidoCantidad': contenidoCantidad,
        'contenidoUnidad': contenidoUnidad.name,
        'unidadBase': producto.unidadBase.apiValue,
      });
      await cargar();
      return _error == null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> marcarHayQueComprar(ItemListaCompra item, bool hayQueComprar) async {
    try {
      final idx = _items.indexWhere((i) => i.id == item.id);
      if (idx >= 0) {
        _items = List<ItemListaCompra>.from(_items);
        _items[idx] = item.copyWith(
          hayQueComprar: hayQueComprar,
          comprado: hayQueComprar ? item.comprado : false,
        );
        notifyListeners();
      }
      await _remote.actualizar(item.id, {
        'hayQueComprar': hayQueComprar,
        if (!hayQueComprar) 'comprado': false,
      });
      await cargar();
      return _error == null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      await cargar();
      return false;
    }
  }

  Future<bool> marcarComprado(ItemListaCompra item, bool comprado) async {
    try {
      await _remote.actualizar(item.id, {
        'hayQueComprar': true,
        'comprado': comprado,
      });
      await cargar();
      return _error == null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> reordenar(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final lista = List<ItemListaCompra>.from(_items);
    final item = lista.removeAt(oldIndex);
    lista.insert(newIndex, item);
    _items = [
      for (var i = 0; i < lista.length; i++) lista[i].copyWith(orden: i),
    ];
    notifyListeners();
    try {
      final ids = _items.map((e) => e.id).toList();
      _items = await _remote.reordenar(ids);
      _error = null;
      _ultimaOk = DateTime.now();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      await cargar();
      return false;
    }
  }

  Future<bool> vaciarCompra() async {
    try {
      await _remote.vaciarCompra();
      await cargar();
      return _error == null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
