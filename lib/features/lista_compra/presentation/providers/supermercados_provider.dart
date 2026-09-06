import 'package:flutter/foundation.dart';

import '../../data/supermercados_remote_service.dart';
import '../../domain/entities/supermercado.dart';

/// Catálogo de supermercados: memoria de sesión + VPS.
class SupermercadosProvider extends ChangeNotifier {
  SupermercadosProvider({SupermercadosRemoteService? remote})
      : _remote = remote ?? SupermercadosRemoteService();

  final SupermercadosRemoteService _remote;

  List<Supermercado> _items = [];
  bool _cargando = false;
  String? _error;

  List<Supermercado> get items => List.unmodifiable(_items);
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _remote.obtenerLista();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('SupermercadosProvider.cargar: $e');
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> anadir(String nombre) async {
    final n = nombre.trim();
    if (n.isEmpty) {
      _error = 'El nombre es obligatorio';
      notifyListeners();
      return false;
    }
    try {
      await _remote.guardar(Supermercado(id: 0, nombre: n));
      await cargar();
      return _error == null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> editar(Supermercado item, String nombre) async {
    final n = nombre.trim();
    if (n.isEmpty) {
      _error = 'El nombre es obligatorio';
      notifyListeners();
      return false;
    }
    try {
      await _remote.guardar(item.copyWith(nombre: n));
      await cargar();
      return _error == null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminar(Supermercado item) async {
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

  Future<bool> reordenar(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final lista = List<Supermercado>.from(_items);
    final item = lista.removeAt(oldIndex);
    lista.insert(newIndex, item);
    _items = [
      for (var i = 0; i < lista.length; i++) lista[i].copyWith(orden: i),
    ];
    notifyListeners();
    try {
      _items = await _remote.reordenar(_items.map((e) => e.id).toList());
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      await cargar();
      return false;
    }
  }
}
