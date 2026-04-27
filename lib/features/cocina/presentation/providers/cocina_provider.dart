import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/core.dart';
import '../../domain/entities/linea_buffet.dart';
import '../../domain/repositories/cocina_repository.dart';
import '../../data/repositories/cocina_repository_impl.dart';

/// Provider para manejar el estado de la pantalla de Cocina
class CocinaProvider extends ChangeNotifier {
  final CocinaRepository _repository;
  final DatabaseService _db;
  static const _uuid = Uuid();
  final Beeper _beeper;

  List<Pedido> _pedidos = [];
  List<Pedido> _pedidosFiltrados = [];
  List<DestinoImpresion> _destinos = [];
  DestinoImpresion? _destinoSeleccionado;
  bool _cargando = false;
  String? _error;
  StreamSubscription? _pedidosSubscription;
  /// true = Modo Buffet, false = Modo Carta
  bool _modoBuffet = false;

  /// Líneas cerradas (congeladas) en modo buffet. Al pulsar "Empezar" se añaden aquí.
  final List<LineaBuffetCerrada> _lineasCerradas = [];
  /// Claves pedidoId_itemIndex de ítems ya asignados a una línea cerrada (no se suman en abiertas).
  final Set<String> _itemKeysEnLineasCerradas = {};

  /// Estado de pedido pendiente de confirmar por el servidor (modo carta, optimista).
  final Map<int, EstadoPedido> _pendingEstadoPedido = {};
  /// Estado de ítem pendiente de confirmar por el servidor (clave "pedidoId_itemIndex").
  final Map<String, EstadoPedido> _pendingEstadoItem = {};

  /// Versión que se incrementa en cada actualización optimista (para forzar rebuild en la UI).
  int _versionOptimista = 0;
  int get versionOptimista => _versionOptimista;

  /// Sonido (solo web): requiere interacción del usuario para activarse.
  bool _sonidoActivado = false;
  bool get sonidoActivado => _sonidoActivado;

  /// Control de notificación: detectar pedidos nuevos por ID (un pitido por batch).
  bool _streamInicializado = false;
  Set<String> _idsVistos = <String>{};

  /// Última vez que se aplicó una actualización optimista (evitar que el stream pise justo después).
  DateTime? _ultimaOptimista;

  /// Modo actual del KDS: Buffet o Carta
  bool get modoBuffet => _modoBuffet;
  void setModoKds(bool modoBuffet) {
    if (_modoBuffet == modoBuffet) return;
    _modoBuffet = modoBuffet;
    notifyListeners();
  }
  void toggleModoKds() {
    _modoBuffet = !_modoBuffet;
    notifyListeners();
  }

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

  /// Líneas cerradas en modo buffet (en preparación; las listas se eliminan tras imprimir).
  List<LineaBuffetCerrada> get lineasCerradas => List.unmodifiable(_lineasCerradas);

  /// Líneas abiertas en modo buffet: platos únicos con cantidad total y contribuciones (sin congelar).
  List<LineaBuffetAbierta> get lineasAbiertas => _calcularLineasAbiertas();

  CocinaProvider({CocinaRepository? repository, DatabaseService? db, Beeper? beeper})
      : _repository = repository ?? 
          CocinaRepositoryImpl(DatabaseService.instance),
        _db = db ?? DatabaseService.instance,
        _beeper = beeper ?? Beeper() {
    _inicializar();
  }

  Future<void> toggleSonido() async {
    _sonidoActivado = !_sonidoActivado;
    if (_sonidoActivado) {
      await _beeper.enable();
    } else {
      await _beeper.disable();
    }
    notifyListeners();
  }

  /// Inicializa el provider
  Future<void> _inicializar() async {
    await _cargarDestinos();
    await _ajustarModoBuffetPorHorario();
    _iniciarEscucha();
  }

  /// Ajusta modo buffet según si estamos en horario de buffet (en web no hay config local; se ignora).
  Future<void> _ajustarModoBuffetPorHorario() async {
    try {
      final configs = await _db.obtenerConfiguracionesBuffet();
      final activa = configs.where((c) => c.activo).toList();
      final enHorario = activa.any((c) => c.esHorarioBuffet());
      if (_modoBuffet != enHorario) {
        _modoBuffet = enHorario;
        notifyListeners();
      }
    } catch (_) {
      // En web no hay DB; el usuario puede cambiar modo manualmente
    }
  }

  /// Carga los destinos disponibles (en web el stub no tiene DB; se deja lista vacía)
  Future<void> _cargarDestinos() async {
    try {
      _destinos = await _db.obtenerDestinosActivos();
      if (_destinos.isNotEmpty) {
        _destinoSeleccionado = _destinos.first;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar destinos: $e');
      _destinos = [];
      _destinoSeleccionado = null;
      notifyListeners();
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

  /// Calcula líneas abiertas (agrupación por plato) excluyendo ítems ya asignados a líneas cerradas
  /// y ítems ya marcados como listo/servido en el servidor.
  List<LineaBuffetAbierta> _calcularLineasAbiertas() {
    final map = <String, LineaBuffetAbierta>{};
    for (final pedido in _pedidosFiltrados) {
      final pedidoId = pedido.id ?? 0;
      for (var i = 0; i < pedido.items.length; i++) {
        final item = pedido.items[i];
        if (item.estadoItem == EstadoPedido.listo || item.estadoItem == EstadoPedido.servido) continue;
        final key = '${pedidoId}_$i';
        if (_itemKeysEnLineasCerradas.contains(key)) continue;
        final k = '${item.productoId}_${item.nombreProducto}';
        final contrib = ContribucionAbierta(
          pedidoId: pedidoId,
          itemIndex: i,
          mesaNumero: pedido.mesaNumero,
          cantidad: item.cantidad,
          fechaCreacion: pedido.fechaCreacion,
        );
        if (map.containsKey(k)) {
          final existente = map[k]!;
          final nuevasContrib = [...existente.contribuciones, contrib];
          map[k] = LineaBuffetAbierta(
            productoId: existente.productoId,
            nombreProducto: existente.nombreProducto,
            cantidadTotal: existente.cantidadTotal + item.cantidad,
            contribuciones: nuevasContrib,
          );
        } else {
          map[k] = LineaBuffetAbierta(
            productoId: item.productoId,
            nombreProducto: item.nombreProducto,
            cantidadTotal: item.cantidad,
            contribuciones: [contrib],
          );
        }
      }
    }
    return map.values.toList();
  }

  /// Cierra una línea abierta (congela el contador). Los nuevos pedidos del mismo plato irán a otra línea.
  void empezarLinea(LineaBuffetAbierta linea) {
    final contribuciones = <ContribucionBuffet>[];
    for (final c in linea.contribuciones) {
      Pedido? pedido;
      try {
        pedido = _pedidosFiltrados.firstWhere((p) => p.id == c.pedidoId);
      } catch (_) {
        continue;
      }
      if (c.itemIndex >= pedido.items.length) continue;
      final item = pedido.items[c.itemIndex];
      final pedidoOriginal = _pedidos.firstWhere((p) => p.id == c.pedidoId);
      final indiceReal = pedidoOriginal.items.indexOf(item);
      if (indiceReal < 0) continue;
      contribuciones.add(ContribucionBuffet(
        pedidoId: c.pedidoId,
        itemIndex: indiceReal,
        keyEnLineasCerradas: c.key,
        mesaNumero: c.mesaNumero,
        cantidad: c.cantidad,
        nombreProducto: item.nombreProducto,
        productoId: item.productoId,
        destinoId: item.destinoId,
        precioUnitario: item.precioUnitario,
        fechaCreacion: c.fechaCreacion,
      ));
      _itemKeysEnLineasCerradas.add(c.key);
    }
    if (contribuciones.isEmpty) return;
    final total = contribuciones.fold<int>(0, (s, c) => s + c.cantidad);
    _lineasCerradas.add(LineaBuffetCerrada(
      id: _uuid.v4(),
      productoId: linea.productoId,
      nombreProducto: linea.nombreProducto,
      cantidadTotal: total,
      contribuciones: contribuciones,
      estado: EstadoLineaBuffet.enPreparacion,
    ));
    notifyListeners();
  }

  /// Imprime un ticket por cada mesa de la línea, marca los ítems como listo en el servidor y elimina la línea.
  Future<void> hechoTodoLinea(String lineaId) async {
    final idx = _lineasCerradas.indexWhere((l) => l.id == lineaId);
    if (idx < 0) return;
    final linea = _lineasCerradas[idx];
    for (final c in linea.contribuciones) {
      await _imprimirTicketMesa(c.mesaNumero, c.nombreProducto, c.productoId, c.cantidad, c.destinoId, c.precioUnitario);
      try {
        await _repository.actualizarEstadoItem(c.pedidoId, c.itemIndex, EstadoPedido.listo);
      } catch (e) {
        debugPrint('Error al marcar ítem como listo en servidor: $e');
      }
      _itemKeysEnLineasCerradas.remove(c.keyEnLineasCerradas);
    }
    _lineasCerradas.removeAt(idx);
    notifyListeners();
  }

  /// Marca como terminada una cantidad X; prioriza mesas por orden de pedido e imprime sus tickets.
  /// Las contribuciones totalmente completadas se marcan como listo en el servidor.
  Future<void> hechoParcialLinea(String lineaId, int cantidad) async {
    final idx = _lineasCerradas.indexWhere((l) => l.id == lineaId);
    if (idx < 0 || cantidad <= 0) return;
    final linea = _lineasCerradas[idx];
    final ordenadas = List<ContribucionBuffet>.from(linea.contribuciones)
      ..sort((a, b) => a.fechaCreacion.compareTo(b.fechaCreacion));
    var restante = cantidad;
    final nuevosContrib = <ContribucionBuffet>[];
    for (final c in ordenadas) {
      if (restante <= 0) {
        nuevosContrib.add(c);
        continue;
      }
      final aImprimir = restante >= c.cantidad ? c.cantidad : restante;
      restante -= aImprimir;
      if (aImprimir > 0) {
        await _imprimirTicketMesa(c.mesaNumero, c.nombreProducto, c.productoId, aImprimir, c.destinoId, c.precioUnitario);
      }
      final nuevoCant = c.cantidad - aImprimir;
      if (nuevoCant > 0) {
        nuevosContrib.add(ContribucionBuffet(
          pedidoId: c.pedidoId,
          itemIndex: c.itemIndex,
          keyEnLineasCerradas: c.keyEnLineasCerradas,
          mesaNumero: c.mesaNumero,
          cantidad: nuevoCant,
          nombreProducto: c.nombreProducto,
          productoId: c.productoId,
          destinoId: c.destinoId,
          precioUnitario: c.precioUnitario,
          fechaCreacion: c.fechaCreacion,
        ));
      } else {
        try {
          await _repository.actualizarEstadoItem(c.pedidoId, c.itemIndex, EstadoPedido.listo);
        } catch (e) {
          debugPrint('Error al marcar ítem como listo en servidor: $e');
        }
        _itemKeysEnLineasCerradas.remove(c.keyEnLineasCerradas);
      }
    }
    if (nuevosContrib.isEmpty) {
      _lineasCerradas.removeAt(idx);
    } else {
      linea.contribuciones
        ..clear()
        ..addAll(nuevosContrib);
      linea.cantidadTotal = nuevosContrib.fold<int>(0, (s, c) => s + c.cantidad);
    }
    notifyListeners();
  }

  /// Genera e imprime un ticket para una mesa (plato y cantidad).
  /// En web llama al servidor (API); en desktop imprime en la impresora local.
  Future<void> _imprimirTicketMesa(
    int mesaNumero,
    String nombreProducto,
    int productoId,
    int cantidad,
    int? destinoId,
    double precioUnitario,
  ) async {
    await _repository.imprimirTicketCocina(
      mesaNumero,
      nombreProducto,
      productoId,
      cantidad,
      destinoId,
      precioUnitario,
      useBuffetPrinter: _modoBuffet,
    );
  }

  /// Aplica la lista del servidor preservando estados optimistas pendientes.
  void _aplicarPedidosDelServidor(List<Pedido> pedidos) {
    for (final p in pedidos) {
      final id = p.id;
      if (id == null) continue;
      final pendingEstado = _pendingEstadoPedido[id];
      if (pendingEstado != null) {
        if (p.estado == pendingEstado) {
          _pendingEstadoPedido.remove(id);
        } else {
          p.estado = pendingEstado;
        }
      }
      for (var j = 0; j < p.items.length; j++) {
        final key = '${id}_$j';
        final pendingItem = _pendingEstadoItem[key];
        if (pendingItem != null) {
          if (p.items[j].estadoItem == pendingItem) {
            _pendingEstadoItem.remove(key);
          } else {
            p.items[j].estadoItem = pendingItem;
          }
        }
      }
    }
    _pedidos = pedidos;
    _filtrarPedidosPorDestino();
  }

  /// Inicia la escucha de cambios en los pedidos
  void _iniciarEscucha() {
    _pedidosSubscription?.cancel();
    _pedidosSubscription = _repository.watchPedidosCocina().listen(
      (pedidos) {
        // No pisar la UI si acabamos de hacer una actualización optimista (stream puede traer datos viejos).
        final ahora = DateTime.now();
        if (_ultimaOptimista != null &&
            ahora.difference(_ultimaOptimista!).inMilliseconds < 800) {
          return;
        }
        // Detectar nuevos pedidos por ID (1 pitido por batch).
        final currentIds = <String>{};
        for (final p in pedidos) {
          final id = p.id;
          if (id == null) continue;
          currentIds.add(id.toString());
        }
        final nuevosIds = currentIds.difference(_idsVistos);
        if (_streamInicializado && nuevosIds.isNotEmpty && _sonidoActivado) {
          // Un pitido por batch de pedidos nuevos.
          _beeper.beep();
        }
        _idsVistos = currentIds;
        _streamInicializado = true;

        final anteriorCount = _pedidosFiltrados.length;
        _aplicarPedidosDelServidor(pedidos);
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

  /// Refresca solo la lista de pedidos (sin loading ni destinos). Tras cada acción en cocina.
  Future<void> _refrescarListaPedidos() async {
    try {
      final list = await _repository.obtenerPedidosCocina();
      _aplicarPedidosDelServidor(list);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _marcarOptimistaAplicada() {
    _versionOptimista++;
    _ultimaOptimista = DateTime.now();
  }

  /// Actualización optimista: refleja "Empezar" en la lista local (modo carta).
  void _aplicarOptimisticoIniciarPreparacion(int pedidoId) {
    final idx = _pedidos.indexWhere((p) => p.id == pedidoId);
    if (idx >= 0) {
      _pendingEstadoPedido[pedidoId] = EstadoPedido.preparando;
      _pedidos[idx].estado = EstadoPedido.preparando;
      _filtrarPedidosPorDestino();
      _marcarOptimistaAplicada();
      notifyListeners();
    }
  }

  /// Actualización optimista: refleja "Listo" en la lista local (modo carta).
  void _aplicarOptimisticoMarcarListo(int pedidoId) {
    final idx = _pedidos.indexWhere((p) => p.id == pedidoId);
    if (idx >= 0) {
      _pendingEstadoPedido[pedidoId] = EstadoPedido.listo;
      _pedidos[idx].estado = EstadoPedido.listo;
      _filtrarPedidosPorDestino();
      _marcarOptimistaAplicada();
      notifyListeners();
    }
  }

  /// Actualización optimista: refleja cambio de estado de un ítem en la lista local (modo carta).
  void _aplicarOptimisticoEstadoItem(int pedidoId, int itemIndex, EstadoPedido nuevoEstado) {
    final idx = _pedidos.indexWhere((p) => p.id == pedidoId);
    if (idx >= 0 && itemIndex >= 0 && itemIndex < _pedidos[idx].items.length) {
      _pendingEstadoItem['${pedidoId}_$itemIndex'] = nuevoEstado;
      _pedidos[idx].items[itemIndex].estadoItem = nuevoEstado;
      _filtrarPedidosPorDestino();
      _marcarOptimistaAplicada();
      notifyListeners();
    }
  }

  /// Revierte la actualización optimista si falla la API (pedido vuelve a pendiente).
  void _revertirOptimisticoIniciarPreparacion(int pedidoId) {
    _pendingEstadoPedido.remove(pedidoId);
    final idx = _pedidos.indexWhere((p) => p.id == pedidoId);
    if (idx >= 0) {
      _pedidos[idx].estado = EstadoPedido.pendiente;
      _filtrarPedidosPorDestino();
      notifyListeners();
    }
  }

  /// Revierte la actualización optimista si falla la API (pedido vuelve a preparando).
  void _revertirOptimisticoMarcarListo(int pedidoId) {
    _pendingEstadoPedido.remove(pedidoId);
    final idx = _pedidos.indexWhere((p) => p.id == pedidoId);
    if (idx >= 0) {
      _pedidos[idx].estado = EstadoPedido.preparando;
      _filtrarPedidosPorDestino();
      notifyListeners();
    }
  }

  /// Revierte la actualización optimista de un ítem si falla la API.
  void _revertirOptimisticoEstadoItem(int pedidoId, int itemIndex, EstadoPedido estadoAnterior) {
    _pendingEstadoItem.remove('${pedidoId}_$itemIndex');
    final idx = _pedidos.indexWhere((p) => p.id == pedidoId);
    if (idx >= 0 && itemIndex >= 0 && itemIndex < _pedidos[idx].items.length) {
      _pedidos[idx].items[itemIndex].estadoItem = estadoAnterior;
      _filtrarPedidosPorDestino();
      notifyListeners();
    }
  }

  /// Recarga los pedidos
  Future<void> recargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      await _cargarDestinos();
      final list = await _repository.obtenerPedidosCocina();
      _aplicarPedidosDelServidor(list);
    } catch (e) {
      _error = e.toString();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Inicia la preparación de un pedido
  Future<bool> iniciarPreparacion(int pedidoId) async {
    _aplicarOptimisticoIniciarPreparacion(pedidoId);
    try {
      await _repository.iniciarPreparacion(pedidoId);
      _refrescarListaPedidos(); // en segundo plano
      return true;
    } catch (e) {
      _error = e.toString();
      _revertirOptimisticoIniciarPreparacion(pedidoId);
      return false;
    }
  }

  /// Marca un pedido como listo
  Future<bool> marcarListo(int pedidoId) async {
    _aplicarOptimisticoMarcarListo(pedidoId);
    try {
      await _repository.marcarListo(pedidoId);
      _refrescarListaPedidos(); // en segundo plano
      return true;
    } catch (e) {
      _error = e.toString();
      _revertirOptimisticoMarcarListo(pedidoId);
      return false;
    }
  }

  /// Actualiza el estado de un item específico
  Future<bool> actualizarEstadoItem(
    int pedidoId,
    int itemIndex,
    EstadoPedido nuevoEstado,
  ) async {
    int? idx;
    EstadoPedido? estadoAnterior;
    try {
      final pedidoOriginal = _pedidos.firstWhere((p) => p.id == pedidoId);
      final itemFiltrado = _pedidosFiltrados
          .firstWhere((p) => p.id == pedidoId)
          .items[itemIndex];
      final indiceReal = pedidoOriginal.items.indexOf(itemFiltrado);
      idx = indiceReal >= 0 ? indiceReal : itemIndex;
      estadoAnterior = pedidoOriginal.items[idx].estadoItem;

      _aplicarOptimisticoEstadoItem(pedidoId, idx, nuevoEstado);
      await _repository.actualizarEstadoItem(pedidoId, idx, nuevoEstado);
      _refrescarListaPedidos(); // en segundo plano
      return true;
    } catch (e) {
      _error = e.toString();
      if (idx != null && estadoAnterior != null) {
        _revertirOptimisticoEstadoItem(pedidoId, idx, estadoAnterior);
      } else {
        notifyListeners();
      }
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
