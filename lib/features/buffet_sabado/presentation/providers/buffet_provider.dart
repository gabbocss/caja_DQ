import 'package:flutter/foundation.dart';

import '../../../../core/core.dart';
import '../../domain/entities/buffet_session.dart';
import '../../domain/repositories/buffet_repository.dart';
import '../../data/repositories/buffet_repository_impl.dart';

/// Provider para manejar el estado del Buffet del Sábado
class BuffetProvider extends ChangeNotifier {
  final BuffetRepository _repository;

  List<BuffetSession> _sesionesActivas = [];
  List<Producto> _productosBuffet = [];
  List<Producto> _productosAdicionales = [];
  bool _cargando = false;
  String? _error;

  /// Sesiones de buffet activas
  List<BuffetSession> get sesionesActivas => _sesionesActivas;

  /// Productos incluidos en el buffet
  List<Producto> get productosBuffet => _productosBuffet;

  /// Productos adicionales (no incluidos)
  List<Producto> get productosAdicionales => _productosAdicionales;

  /// Indica si hay una operación en progreso
  bool get cargando => _cargando;

  /// Mensaje de error
  String? get error => _error;

  /// Verifica si hoy es día de buffet
  bool get esDiaDeBuffet => _repository.esDiaDeBuffet();

  /// Precio del buffet para adultos
  double get precioAdulto => AppConstants.precioBuffet;

  /// Precio del buffet para niños
  double get precioNino => AppConstants.precioBuffetNinos;

  BuffetProvider({BuffetRepository? repository})
      : _repository =
            repository ?? BuffetRepositoryImpl(DatabaseService.instance) {
    _cargarDatos();
  }

  /// Carga los datos iniciales
  Future<void> _cargarDatos() async {
    _cargando = true;
    notifyListeners();

    try {
      _productosBuffet = await _repository.obtenerProductosBuffet();
      _productosAdicionales = await _repository.obtenerProductosAdicionales();
      _sesionesActivas = await _repository.obtenerSesionesActivas();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Recarga los datos
  Future<void> recargar() async {
    await _cargarDatos();
  }

  /// Inicia una nueva sesión de buffet
  Future<bool> iniciarSesion({
    required int mesaNumero,
    required String camarero,
    required int adultos,
    required int ninos,
  }) async {
    try {
      // Verificar si ya hay una sesión activa en esta mesa
      final existente = await _repository.obtenerSesionActiva(mesaNumero);
      if (existente != null) {
        _error = 'La mesa $mesaNumero ya tiene una sesión de buffet activa';
        notifyListeners();
        return false;
      }

      final session = BuffetSession(
        mesaNumero: mesaNumero,
        camarero: camarero,
        adultos: adultos,
        ninos: ninos,
      );

      await _repository.iniciarSesion(session);
      _sesionesActivas = await _repository.obtenerSesionesActivas();
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Agrega un producto adicional a una sesión
  Future<bool> agregarAdicional({
    required int mesaNumero,
    required Producto producto,
    int cantidad = 1,
  }) async {
    try {
      final session = await _repository.obtenerSesionActiva(mesaNumero);
      if (session == null) {
        _error = 'No hay sesión activa en la mesa $mesaNumero';
        notifyListeners();
        return false;
      }

      session.agregarAdicional(ItemAdicionalBuffet(
        productoId: producto.id ?? 0,
        nombre: producto.nombre,
        precio: producto.precio,
        cantidad: cantidad,
      ));

      await _repository.actualizarSesion(session);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Actualiza la cantidad de comensales
  Future<bool> actualizarComensales({
    required int mesaNumero,
    int? adultos,
    int? ninos,
  }) async {
    try {
      final session = await _repository.obtenerSesionActiva(mesaNumero);
      if (session == null) {
        _error = 'No hay sesión activa en la mesa $mesaNumero';
        notifyListeners();
        return false;
      }

      if (adultos != null) session.adultos = adultos;
      if (ninos != null) session.ninos = ninos;

      await _repository.actualizarSesion(session);
      _sesionesActivas = await _repository.obtenerSesionesActivas();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Finaliza una sesión y genera el pedido
  Future<Pedido?> finalizarSesion(int mesaNumero) async {
    _cargando = true;
    notifyListeners();

    try {
      final pedido = await _repository.finalizarSesion(mesaNumero);
      _sesionesActivas = await _repository.obtenerSesionesActivas();
      _error = null;
      return pedido;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Obtiene una sesión específica
  Future<BuffetSession?> obtenerSesion(int mesaNumero) async {
    return await _repository.obtenerSesionActiva(mesaNumero);
  }

  /// Limpia el error
  void limpiarError() {
    _error = null;
    notifyListeners();
  }
}
