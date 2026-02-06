import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../../core/core.dart';
import '../../domain/repositories/cocina_repository.dart';
import '../../data/repositories/cocina_repository_impl.dart';

/// Provider para manejar el estado de la pantalla de Cocina
class CocinaProvider extends ChangeNotifier {
  final CocinaRepository _repository;
  final DatabaseService _db;
  
  List<Pedido> _pedidos = [];
  List<Pedido> _pedidosFiltrados = [];
  List<DestinoImpresion> _destinos = [];
  DestinoImpresion? _destinoSeleccionado;
  bool _cargando = false;
  String? _error;
  StreamSubscription? _pedidosSubscription;

  /// Lista de pedidos para la cocina
  List<Pedido> get pedidos => _pedidosFiltrados;
  
  /// Lista de todos los destinos disponibles
  List<DestinoImpresion> get destinos => _destinos;
  
  /// Destino actualmente seleccionado
  DestinoImpresion? get destinoSeleccionado => _destinoSeleccionado;
  
  /// Pedidos pendientes (sin iniciar)
  List<Pedido> get pedidosPendientes => 
      _pedidosFiltrados.where((p) => p.estado == EstadoPedido.pendiente).toList();
  
  /// Pedidos en preparación
  List<Pedido> get pedidosPreparando => 
      _pedidosFiltrados.where((p) => p.estado == EstadoPedido.preparando).toList();
  
  /// Indica si hay una operación en progreso
  bool get cargando => _cargando;
  
  /// Mensaje de error
  String? get error => _error;
  
  /// Cantidad total de pedidos en cocina
  int get totalPedidos => _pedidosFiltrados.length;

  CocinaProvider({CocinaRepository? repository, DatabaseService? db})
      : _repository = repository ?? 
          CocinaRepositoryImpl(DatabaseService.instance),
        _db = db ?? DatabaseService.instance {
    _inicializar();
  }

  /// Inicializa el provider
  Future<void> _inicializar() async {
    await _cargarDestinos();
    _iniciarEscucha();
  }

  /// Carga los destinos disponibles
  Future<void> _cargarDestinos() async {
    try {
      _destinos = await _db.obtenerDestinosActivos();
      
      // Seleccionar el primer destino por defecto (típicamente "Cocina")
      if (_destinos.isNotEmpty) {
        _destinoSeleccionado = _destinos.first;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar destinos: $e');
    }
  }

  /// Cambia el destino seleccionado
  void seleccionarDestino(DestinoImpresion destino) {
    _destinoSeleccionado = destino;
    _filtrarPedidosPorDestino();
    notifyListeners();
  }

  /// Ver todos los pedidos (sin filtro de destino)
  void verTodos() {
    _destinoSeleccionado = null;
    _pedidosFiltrados = List.from(_pedidos);
    notifyListeners();
  }

  /// Filtra los pedidos según el destino seleccionado
  void _filtrarPedidosPorDestino() {
    if (_destinoSeleccionado == null) {
      _pedidosFiltrados = List.from(_pedidos);
    } else {
      // Filtrar pedidos que tengan items para este destino
      _pedidosFiltrados = _pedidos.where((pedido) {
        return pedido.items.any((item) => item.destinoId == _destinoSeleccionado!.id);
      }).map((pedido) {
        // Crear una copia del pedido solo con los items del destino
        final pedidoFiltrado = Pedido()
          ..id = pedido.id
          ..mesaNumero = pedido.mesaNumero
          ..items = pedido.items
              .where((item) => item.destinoId == _destinoSeleccionado!.id)
              .toList()
          ..estado = pedido.estado
          ..total = pedido.total
          ..usuarioCamarero = pedido.usuarioCamarero
          ..numeroComensales = pedido.numeroComensales
          ..notas = pedido.notas
          ..esBuffet = pedido.esBuffet
          ..fechaCreacion = pedido.fechaCreacion
          ..fechaActualizacion = pedido.fechaActualizacion
          ..fechaCompletado = pedido.fechaCompletado;
        
        return pedidoFiltrado;
      }).toList();
    }
  }

  /// Inicia la escucha de cambios en los pedidos
  void _iniciarEscucha() {
    _pedidosSubscription?.cancel();
    _pedidosSubscription = _repository.watchPedidosCocina().listen(
      (pedidos) {
        final anteriorCount = _pedidosFiltrados.length;
        _pedidos = pedidos;
        _filtrarPedidosPorDestino();
        _error = null;
        
        // Detectar nuevos pedidos para notificación
        if (_pedidosFiltrados.length > anteriorCount && anteriorCount > 0) {
          debugPrint('🔔 ¡Nuevo pedido recibido en cocina!');
        }
        
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  /// Recarga los pedidos
  Future<void> recargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      await _cargarDestinos();
      _pedidos = await _repository.obtenerPedidosCocina();
      _filtrarPedidosPorDestino();
    } catch (e) {
      _error = e.toString();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Inicia la preparación de un pedido
  Future<bool> iniciarPreparacion(int pedidoId) async {
    try {
      await _repository.iniciarPreparacion(pedidoId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Marca un pedido como listo
  Future<bool> marcarListo(int pedidoId) async {
    try {
      await _repository.marcarListo(pedidoId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Actualiza el estado de un item específico
  Future<bool> actualizarEstadoItem(
    int pedidoId,
    int itemIndex,
    EstadoPedido nuevoEstado,
  ) async {
    try {
      // Encontrar el índice real del item en el pedido original
      final pedidoOriginal = _pedidos.firstWhere((p) => p.id == pedidoId);
      final itemFiltrado = _pedidosFiltrados
          .firstWhere((p) => p.id == pedidoId)
          .items[itemIndex];
      
      final indiceReal = pedidoOriginal.items.indexOf(itemFiltrado);
      if (indiceReal >= 0) {
        await _repository.actualizarEstadoItem(pedidoId, indiceReal, nuevoEstado);
      } else {
        // Si no encuentra el item exacto, usar el índice proporcionado
        await _repository.actualizarEstadoItem(pedidoId, itemIndex, nuevoEstado);
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Verifica si un pedido es urgente (más de 15 minutos de espera)
  bool esPedidoUrgente(Pedido pedido) {
    final tiempoEspera = DateTime.now().difference(pedido.fechaCreacion);
    return tiempoEspera.inMinutes > 15;
  }

  /// Formatea el tiempo de espera de un pedido
  String formatearTiempoEspera(Pedido pedido) {
    final tiempoEspera = DateTime.now().difference(pedido.fechaCreacion);
    if (tiempoEspera.inHours > 0) {
      return '${tiempoEspera.inHours}h ${tiempoEspera.inMinutes % 60}m';
    } else if (tiempoEspera.inMinutes > 0) {
      return '${tiempoEspera.inMinutes}m';
    } else {
      return '${tiempoEspera.inSeconds}s';
    }
  }

  @override
  void dispose() {
    _pedidosSubscription?.cancel();
    super.dispose();
  }
}
