import 'package:flutter/foundation.dart';

import '../../data/lista_compra_remote_service.dart';
import '../../domain/entities/item_lista_compra.dart';
import '../../domain/entities/supermercado.dart';

/// Estado de la lista de la compra: solo memoria de sesión + VPS.
class ListaCompraProvider extends ChangeNotifier {
  ListaCompraProvider({ListaCompraRemoteService? remote})
      : _remote = remote ?? ListaCompraRemoteService();

  final ListaCompraRemoteService _remote;

  List<ItemListaCompra> _items = [];
  List<Supermercado> _supermercados = [];
  int? _supermercadoActualId;
  bool _cargando = false;
  String? _error;
  DateTime? _ultimaOk;

  List<ItemListaCompra> get items => List.unmodifiable(_items);

  List<ItemListaCompra> itemsDe(ZonaListaCompra zona) =>
      _items.where((i) => i.zona == zona).toList();
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

  bool get cargando => _cargando;
  String? get error => _error;
  DateTime? get ultimaActualizacionOk => _ultimaOk;

  Supermercado? supermercadoDe(int? id) {
    if (id == null) return null;
    for (final s in _supermercados) {
      if (s.id == id) return s;
    }
    return null;
  }

  String? nombreSupermercado(int? id) => supermercadoDe(id)?.nombre;

  /// Pendientes visibles según el súper seleccionado en Comprar.
  /// Sin filtro: todos. Con filtro: los de ese súper + los sin asignar.
  List<ItemListaCompra> pendientesParaSupermercado(int? supermercadoId) {
    final lista = pendientesCompra;
    if (supermercadoId == null) return lista;
    return lista
        .where(
          (i) =>
              i.supermercadoId == null || i.supermercadoId == supermercadoId,
        )
        .toList();
  }

  List<ItemListaCompra> compradosParaSupermercado(int? supermercadoId) {
    final lista = compradosCompra;
    if (supermercadoId == null) return lista;
    return lista
        .where(
          (i) =>
              i.supermercadoId == null || i.supermercadoId == supermercadoId,
        )
        .toList();
  }

  Future<void> cargar({bool incluirSupers = true}) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _remote.obtenerLista();
      if (incluirSupers) {
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

  Future<bool> anadir({
    required String nombre,
    String cantidad = '',
    ZonaListaCompra zona = ZonaListaCompra.cocina,
    int? supermercadoId,
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
          zona: zona,
          supermercadoId: supermercadoId,
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
    ZonaListaCompra? zona,
    int? supermercadoId,
    bool clearSupermercado = false,
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
          zona: zona,
          supermercadoId: supermercadoId,
          clearSupermercado: clearSupermercado,
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

  Future<bool> eliminar(ItemListaCompra item) async {
    try {
      await _remote.eliminar(item.id);
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

  Future<bool> reordenar(
    ZonaListaCompra zona,
    int oldIndex,
    int newIndex,
  ) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final deZona = List<ItemListaCompra>.from(itemsDe(zona));
    if (oldIndex < 0 || oldIndex >= deZona.length) return false;
    final item = deZona.removeAt(oldIndex);
    final insertAt = newIndex.clamp(0, deZona.length);
    deZona.insert(insertAt, item);
    final cocina =
        zona == ZonaListaCompra.cocina ? deZona : itemsDe(ZonaListaCompra.cocina);
    final sala =
        zona == ZonaListaCompra.sala ? deZona : itemsDe(ZonaListaCompra.sala);
    final combinada = [...cocina, ...sala];
    _items = [
      for (var i = 0; i < combinada.length; i++) combinada[i].copyWith(orden: i),
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
