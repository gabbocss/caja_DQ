import 'dart:convert';
import 'dart:io';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// Servicio singleton para gestionar la base de datos Isar
/// 
/// Este servicio proporciona acceso centralizado a la base de datos
/// y maneja la inicialización y cierre de conexiones.
class DatabaseService {
  static DatabaseService? _instance;
  static Isar? _isar;
  static String? _dbPath;

  DatabaseService._();

  /// Obtiene la instancia singleton del servicio
  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  /// Obtiene la instancia de Isar (debe inicializarse primero)
  Isar get isar {
    if (_isar == null) {
      throw StateError(
        'DatabaseService no inicializado. Llama a initialize() primero.',
      );
    }
    return _isar!;
  }

  /// Verifica si la base de datos está inicializada
  bool get isInitialized => _isar != null;

  /// Inicializa la base de datos Isar
  /// 
  /// Debe llamarse una vez al inicio de la aplicación
  Future<void> initialize() async {
    if (_isar != null) {
      debugPrint('DatabaseService ya está inicializado');
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final dbPath = '${dir.path}/programa_caja_db';
      _dbPath = dbPath;

      // Crear el directorio si no existe
      final dbDir = Directory(dbPath);
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
        debugPrint('Directorio de base de datos creado: $dbPath');
      }

      debugPrint('Inicializando base de datos en: $dbPath');

      _isar = await Isar.open(
        [
          ProductoSchema,
          MesaSchema,
          PedidoSchema,
          DestinoImpresionSchema,
          ConfiguracionBuffetSchema,
        ],
        directory: dbPath,
        name: 'restaurante',
        inspector: kDebugMode, // Solo en modo debug
      );

      debugPrint('Base de datos inicializada correctamente');
      
      // Inicializar datos por defecto si la DB está vacía
      await _inicializarDatosDefecto();
      
    } catch (e, stackTrace) {
      debugPrint('Error al inicializar la base de datos: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Inicializa datos por defecto si la base de datos está vacía
  Future<void> _inicializarDatosDefecto() async {
    final mesaCount = await _isar!.mesas.count();
    
    if (mesaCount == 0) {
      debugPrint('Creando mesas por defecto...');
      
      await _isar!.writeTxn(() async {
        // Crear 10 mesas por defecto
        for (int i = 1; i <= 10; i++) {
          final mesa = Mesa.crear(
            numero: i,
            capacidad: i <= 5 ? 4 : 6, // Mesas 1-5 para 4, 6-10 para 6
            ubicacion: i <= 5 ? 'Interior' : 'Terraza',
          );
          await _isar!.mesas.put(mesa);
        }
      });
      
      debugPrint('Mesas creadas correctamente');
    }

    // Crear destinos ANTES de productos para poder asignarlos
    final destinoCount = await _isar!.destinoImpresions.count();
    int? cocinaId;
    int? barraId;
    
    if (destinoCount == 0) {
      debugPrint('Creando destinos de impresión por defecto...');
      
      await _isar!.writeTxn(() async {
        final cocina = DestinoImpresion.crear(
          nombre: 'Cocina',
          descripcion: 'Cocina principal - platos calientes',
          icono: 'restaurant',
          color: '#E94560',
          tipo: TipoDestino.pantalla,
          orden: 1,
        );
        cocinaId = await _isar!.destinoImpresions.put(cocina);
        
        final barra = DestinoImpresion.crear(
          nombre: 'Barra',
          descripcion: 'Barra de bebidas',
          icono: 'local_bar',
          color: '#00D9A5',
          tipo: TipoDestino.pantalla,
          orden: 2,
        );
        barraId = await _isar!.destinoImpresions.put(barra);
        
        final postres = DestinoImpresion.crear(
          nombre: 'Postres',
          descripcion: 'Área de postres y cafetería',
          icono: 'cake',
          color: '#FFB74D',
          tipo: TipoDestino.pantalla,
          orden: 3,
        );
        await _isar!.destinoImpresions.put(postres);
      });
      
      debugPrint('Destinos de impresión creados correctamente');
    } else {
      // Obtener IDs de destinos existentes
      final destinos = await _isar!.destinoImpresions.where().findAll();
      cocinaId = destinos.where((d) => d.nombre == 'Cocina').firstOrNull?.id;
      barraId = destinos.where((d) => d.nombre == 'Barra').firstOrNull?.id;
    }

    final productoCount = await _isar!.productos.count();
    
    if (productoCount == 0) {
      debugPrint('Creando productos de ejemplo...');
      
      await _isar!.writeTxn(() async {
        // Productos de ejemplo con destino y disponibilidad configurados
        final productosEjemplo = [
          // === COMIDA (destino: cocina) ===
          Producto.crear(
            nombre: 'Tacos al Pastor',
            precio: 45.00,
            descripcion: 'Orden de 3 tacos con piña y cebolla',
            categoria: 'Tacos',
            esBuffet: true,
            destino: DestinoProducto.cocina,
            destinoId: cocinaId,
            isAvailable: true,
          ),
          Producto.crear(
            nombre: 'Tacos de Bistec',
            precio: 50.00,
            descripcion: 'Orden de 3 tacos de bistec',
            categoria: 'Tacos',
            esBuffet: true,
            destino: DestinoProducto.cocina,
            destinoId: cocinaId,
            isAvailable: true,
          ),
          Producto.crear(
            nombre: 'Quesadilla de Queso',
            precio: 35.00,
            descripcion: 'Quesadilla con queso Oaxaca',
            categoria: 'Antojitos',
            esBuffet: true,
            destino: DestinoProducto.cocina,
            destinoId: cocinaId,
            isAvailable: true,
          ),
          Producto.crear(
            nombre: 'Quesadilla de Pollo',
            precio: 45.00,
            descripcion: 'Quesadilla con pollo deshebrado',
            categoria: 'Antojitos',
            esBuffet: true,
            destino: DestinoProducto.cocina,
            destinoId: cocinaId,
            isAvailable: true,
          ),
          Producto.crear(
            nombre: 'Enchiladas Verdes',
            precio: 85.00,
            descripcion: 'Orden de 3 enchiladas con salsa verde',
            categoria: 'Platos Fuertes',
            esBuffet: true,
            destino: DestinoProducto.cocina,
            destinoId: cocinaId,
            isAvailable: true,
          ),
          Producto.crear(
            nombre: 'Pozole Rojo',
            precio: 75.00,
            descripcion: 'Plato de pozole tradicional',
            categoria: 'Sopas',
            esBuffet: true,
            destino: DestinoProducto.cocina,
            destinoId: cocinaId,
            isAvailable: true,
          ),
          Producto.crear(
            nombre: 'Flan Napolitano',
            precio: 40.00,
            descripcion: 'Flan casero con caramelo',
            categoria: 'Postres',
            esBuffet: true,
            destino: DestinoProducto.cocina,
            destinoId: cocinaId,
            isAvailable: true,
          ),
          // === BEBIDAS (destino: barra) ===
          Producto.crear(
            nombre: 'Refresco',
            precio: 25.00,
            descripcion: 'Refresco de la casa 500ml',
            categoria: 'Bebidas',
            esBuffet: false,
            destino: DestinoProducto.barra,
            destinoId: barraId,
            isAvailable: true,
          ),
          Producto.crear(
            nombre: 'Agua Fresca',
            precio: 20.00,
            descripcion: 'Agua fresca del día',
            categoria: 'Bebidas',
            esBuffet: true,
            destino: DestinoProducto.barra,
            destinoId: barraId,
            isAvailable: true,
          ),
          Producto.crear(
            nombre: 'Limonada',
            precio: 30.00,
            descripcion: 'Limonada natural',
            categoria: 'Bebidas',
            esBuffet: true,
            destino: DestinoProducto.barra,
            destinoId: barraId,
            isAvailable: true,
          ),
          Producto.crear(
            nombre: 'Cerveza Nacional',
            precio: 40.00,
            descripcion: 'Cerveza nacional 355ml',
            categoria: 'Bebidas Alcohólicas',
            esBuffet: false,
            destino: DestinoProducto.barra,
            destinoId: barraId,
            isAvailable: true,
          ),
          Producto.crear(
            nombre: 'Cerveza Importada',
            precio: 55.00,
            descripcion: 'Cerveza importada 355ml',
            categoria: 'Bebidas Alcohólicas',
            esBuffet: false,
            destino: DestinoProducto.barra,
            destinoId: barraId,
            isAvailable: true,
          ),
          Producto.crear(
            nombre: 'Margarita',
            precio: 80.00,
            descripcion: 'Margarita clásica con sal',
            categoria: 'Bebidas Alcohólicas',
            esBuffet: false,
            destino: DestinoProducto.barra,
            destinoId: barraId,
            isAvailable: true,
          ),
          Producto.crear(
            nombre: 'Café Americano',
            precio: 25.00,
            descripcion: 'Café de olla tradicional',
            categoria: 'Bebidas',
            esBuffet: true,
            destino: DestinoProducto.barra,
            destinoId: barraId,
            isAvailable: true,
          ),
        ];

        for (final producto in productosEjemplo) {
          await _isar!.productos.put(producto);
        }
      });
      
      debugPrint('Productos de ejemplo creados correctamente');
    }

    // Crear configuración de buffet por defecto
    await inicializarConfiguracionBuffetDefecto();
  }

  /// Cierra la conexión con la base de datos
  Future<void> close() async {
    if (_isar != null) {
      await _isar!.close();
      _isar = null;
      debugPrint('Base de datos cerrada');
    }
  }

  /// Limpia todos los datos de la base de datos (usar con precaución)
  Future<void> clearAll() async {
    await _isar!.writeTxn(() async {
      await _isar!.clear();
    });
    debugPrint('Todos los datos han sido eliminados');
  }

  // ==================== OPERACIONES DE PRODUCTOS ====================

  /// Carga el mapa de alérgenos por id de producto (archivo externo para compatibilidad con DB existente)
  Future<Map<int, List<String>>> _cargarAlergenosMap() async {
    if (_dbPath == null) return {};
    final file = File('$_dbPath/producto_alergenos.json');
    if (!await file.exists()) return {};
    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return json.map((k, v) => MapEntry(
        int.parse(k),
        (v as List<dynamic>).map((e) => e as String).toList(),
      ));
    } catch (_) {
      return {};
    }
  }

  /// Guarda el mapa de alérgenos
  Future<void> _guardarAlergenosMap(Map<int, List<String>> map) async {
    if (_dbPath == null) return;
    final file = File('$_dbPath/producto_alergenos.json');
    final json = map.map((k, v) => MapEntry(k.toString(), v));
    await file.writeAsString(const JsonEncoder().convert(json));
  }

  /// Obtiene todos los productos
  Future<List<Producto>> obtenerProductos() async {
    final list = await isar.productos.where().findAll();
    final alergenosMap = await _cargarAlergenosMap();
    for (final p in list) {
      if (p.id != null && alergenosMap.containsKey(p.id)) {
        p.alergenos = List.from(alergenosMap[p.id]!);
      }
    }
    return list;
  }

  /// Obtiene productos por categoría
  Future<List<Producto>> obtenerProductosPorCategoria(String categoria) async {
    return await isar.productos
        .filter()
        .categoriaEqualTo(categoria)
        .findAll();
  }

  /// Obtiene productos del buffet
  Future<List<Producto>> obtenerProductosBuffet() async {
    final list = await isar.productos
        .filter()
        .esBuffetEqualTo(true)
        .activoEqualTo(true)
        .findAll();
    final alergenosMap = await _cargarAlergenosMap();
    for (final p in list) {
      if (p.id != null && alergenosMap.containsKey(p.id)) {
        p.alergenos = List.from(alergenosMap[p.id]!);
      }
    }
    return list;
  }

  /// Guarda o actualiza un producto
  Future<int> guardarProducto(Producto producto) async {
    producto.fechaModificacion = DateTime.now();
    final id = await isar.writeTxn(() => isar.productos.put(producto));
    final alergenosMap = await _cargarAlergenosMap();
    alergenosMap[id] = List.from(producto.alergenos);
    await _guardarAlergenosMap(alergenosMap);
    return id;
  }

  /// Elimina un producto por ID
  Future<bool> eliminarProducto(int id) async {
    final ok = await isar.writeTxn(() => isar.productos.delete(id));
    if (ok) {
      final map = await _cargarAlergenosMap();
      map.remove(id);
      await _guardarAlergenosMap(map);
    }
    return ok;
  }

  // ==================== OPERACIONES DE MESAS ====================

  /// Obtiene todas las mesas
  Future<List<Mesa>> obtenerMesas() async {
    return await isar.mesas.where().sortByNumero().findAll();
  }

  /// Obtiene mesas por estado
  Future<List<Mesa>> obtenerMesasPorEstado(EstadoMesa estado) async {
    return await isar.mesas
        .filter()
        .estadoEqualTo(estado)
        .sortByNumero()
        .findAll();
  }

  /// Obtiene una mesa por número
  Future<Mesa?> obtenerMesaPorNumero(int numero) async {
    return await isar.mesas.filter().numeroEqualTo(numero).findFirst();
  }

  /// Actualiza el estado de una mesa
  Future<void> actualizarEstadoMesa(int numero, EstadoMesa nuevoEstado) async {
    final mesa = await obtenerMesaPorNumero(numero);
    if (mesa != null) {
      mesa.estado = nuevoEstado;
      mesa.ultimaActualizacion = DateTime.now();
      await isar.writeTxn(() => isar.mesas.put(mesa));
    }
  }

  /// Libera una mesa: busca todos los pedidos de esa mesa, los marca como pagados y pone la mesa libre.
  /// No devuelve stock a productos (consumo de buffet ya realizado).
  /// El próximo cliente empezará de cero (mesa libre, sin pedidos abiertos).
  Future<void> liberarMesa(int numeroMesa, {bool isBuffetClose = false}) async {
    final pedidos = await obtenerCuentaMesa(numeroMesa);
    await isar.writeTxn(() async {
      for (final pedido in pedidos) {
        pedido.estado = EstadoPedido.pagado;
        pedido.fechaCompletado = DateTime.now();
        pedido.fechaActualizacion = DateTime.now();
        await isar.pedidos.put(pedido);
      }
    });
    await actualizarEstadoMesa(numeroMesa, EstadoMesa.libre);
    // No se devuelve stock: es cierre de cuenta (buffet o no), consumo ya realizado
  }

  /// Guarda o actualiza una mesa
  Future<int> guardarMesa(Mesa mesa) async {
    mesa.ultimaActualizacion = DateTime.now();
    return await isar.writeTxn(() => isar.mesas.put(mesa));
  }

  // ==================== OPERACIONES DE PEDIDOS ====================

  /// Obtiene todos los pedidos activos
  Future<List<Pedido>> obtenerPedidosActivos() async {
    return await isar.pedidos
        .filter()
        .estadoEqualTo(EstadoPedido.pendiente)
        .or()
        .estadoEqualTo(EstadoPedido.preparando)
        .or()
        .estadoEqualTo(EstadoPedido.listo)
        .sortByFechaCreacionDesc()
        .findAll();
  }

  /// Obtiene pedidos por estado
  Future<List<Pedido>> obtenerPedidosPorEstado(EstadoPedido estado) async {
    return await isar.pedidos
        .filter()
        .estadoEqualTo(estado)
        .sortByFechaCreacionDesc()
        .findAll();
  }

  /// Obtiene pedidos de una mesa específica
  Future<List<Pedido>> obtenerPedidosDeMesa(int mesaNumero) async {
    return await isar.pedidos
        .filter()
        .mesaNumeroEqualTo(mesaNumero)
        .sortByFechaCreacionDesc()
        .findAll();
  }

  /// Obtiene el pedido activo de una mesa (si existe)
  Future<Pedido?> obtenerPedidoActivoDeMesa(int mesaNumero) async {
    return await isar.pedidos
        .filter()
        .mesaNumeroEqualTo(mesaNumero)
        .and()
        .group((q) => q
            .estadoEqualTo(EstadoPedido.pendiente)
            .or()
            .estadoEqualTo(EstadoPedido.preparando)
            .or()
            .estadoEqualTo(EstadoPedido.listo))
        .findFirst();
  }

  /// Cuenta por mesa: pedidos de la mesa que NO están pagados (ni cancelados)
  Future<List<Pedido>> obtenerCuentaMesa(int mesaNumero) async {
    final todos = await isar.pedidos
        .filter()
        .mesaNumeroEqualTo(mesaNumero)
        .sortByFechaCreacionDesc()
        .findAll();
    return todos
        .where((p) =>
            p.estado != EstadoPedido.pagado &&
            p.estado != EstadoPedido.cancelado)
        .toList();
  }

  /// Números de mesas que tienen al menos un pedido no pagado (cuenta abierta)
  Future<List<int>> obtenerMesasConCuentaAbierta() async {
    final pedidos = await isar.pedidos.where().findAll();
    final mesas = <int>{};
    for (final p in pedidos) {
      if (p.estado != EstadoPedido.pagado &&
          p.estado != EstadoPedido.cancelado) {
        mesas.add(p.mesaNumero);
      }
    }
    return mesas.toList()..sort();
  }

  /// Guarda o actualiza un pedido
  Future<int> guardarPedido(Pedido pedido) async {
    pedido.fechaActualizacion = DateTime.now();
    pedido.calcularTotal();
    return await isar.writeTxn(() => isar.pedidos.put(pedido));
  }

  /// Actualiza el estado de un pedido
  Future<void> actualizarEstadoPedido(int id, EstadoPedido nuevoEstado) async {
    final pedido = await isar.pedidos.get(id);
    if (pedido != null) {
      pedido.estado = nuevoEstado;
      pedido.fechaActualizacion = DateTime.now();
      if (nuevoEstado == EstadoPedido.pagado ||
          nuevoEstado == EstadoPedido.cancelado) {
        pedido.fechaCompletado = DateTime.now();
      }
      await isar.writeTxn(() => isar.pedidos.put(pedido));
    }
  }

  /// Stream de pedidos para actualizaciones en tiempo real
  Stream<List<Pedido>> watchPedidosActivos() {
    return isar.pedidos
        .filter()
        .estadoEqualTo(EstadoPedido.pendiente)
        .or()
        .estadoEqualTo(EstadoPedido.preparando)
        .or()
        .estadoEqualTo(EstadoPedido.listo)
        .sortByFechaCreacionDesc()
        .watch(fireImmediately: true);
  }

  /// Stream de pedidos pendientes para la cocina
  Stream<List<Pedido>> watchPedidosCocina() {
    return isar.pedidos
        .filter()
        .estadoEqualTo(EstadoPedido.pendiente)
        .or()
        .estadoEqualTo(EstadoPedido.preparando)
        .sortByFechaCreacionDesc()
        .watch(fireImmediately: true);
  }

  // ==================== OPERACIONES DE DESTINOS ====================

  /// Obtiene todos los destinos de impresión
  Future<List<DestinoImpresion>> obtenerDestinos() async {
    return await isar.destinoImpresions
        .where()
        .sortByOrden()
        .findAll();
  }

  /// Obtiene destinos activos
  Future<List<DestinoImpresion>> obtenerDestinosActivos() async {
    return await isar.destinoImpresions
        .filter()
        .activoEqualTo(true)
        .sortByOrden()
        .findAll();
  }

  /// Obtiene un destino por ID
  Future<DestinoImpresion?> obtenerDestinoPorId(int id) async {
    return await isar.destinoImpresions.get(id);
  }

  /// Obtiene un destino por nombre
  Future<DestinoImpresion?> obtenerDestinoPorNombre(String nombre) async {
    return await isar.destinoImpresions
        .filter()
        .nombreEqualTo(nombre)
        .findFirst();
  }

  /// Guarda o actualiza un destino
  Future<int> guardarDestino(DestinoImpresion destino) async {
    return await isar.writeTxn(() => isar.destinoImpresions.put(destino));
  }

  /// Elimina un destino por ID
  Future<bool> eliminarDestino(int id) async {
    return await isar.writeTxn(() => isar.destinoImpresions.delete(id));
  }

  /// Stream de destinos para actualizaciones en tiempo real
  Stream<List<DestinoImpresion>> watchDestinos() {
    return isar.destinoImpresions
        .where()
        .sortByOrden()
        .watch(fireImmediately: true);
  }

  // ==================== OPERACIONES DE PEDIDOS POR DESTINO ====================

  /// Obtiene pedidos pendientes filtrados por destino
  Future<List<Pedido>> obtenerPedidosPorDestino(int destinoId) async {
    final pedidos = await isar.pedidos
        .filter()
        .estadoEqualTo(EstadoPedido.pendiente)
        .or()
        .estadoEqualTo(EstadoPedido.preparando)
        .sortByFechaCreacionDesc()
        .findAll();
    
    // Filtrar pedidos que tienen items para este destino
    return pedidos.where((pedido) {
      return pedido.items.any((item) => item.destinoId == destinoId);
    }).toList();
  }

  /// Stream de pedidos filtrados por destino
  Stream<List<Pedido>> watchPedidosPorDestino(int destinoId) {
    return isar.pedidos
        .filter()
        .estadoEqualTo(EstadoPedido.pendiente)
        .or()
        .estadoEqualTo(EstadoPedido.preparando)
        .sortByFechaCreacionDesc()
        .watch(fireImmediately: true)
        .map((pedidos) {
          return pedidos.where((pedido) {
            return pedido.items.any((item) => item.destinoId == destinoId);
          }).toList();
        });
  }

  /// Actualiza el estado de un item específico de un pedido
  Future<void> actualizarEstadoItem(int pedidoId, int itemIndex, EstadoPedido nuevoEstado) async {
    final pedido = await isar.pedidos.get(pedidoId);
    if (pedido != null && itemIndex < pedido.items.length) {
      pedido.items[itemIndex].estadoItem = nuevoEstado;
      pedido.fechaActualizacion = DateTime.now();
      
      // Verificar si todos los items están listos para cambiar estado del pedido
      final todosListos = pedido.items.every((item) => 
          item.estadoItem == EstadoPedido.listo || 
          item.estadoItem == EstadoPedido.servido);
      
      if (todosListos && pedido.estado == EstadoPedido.preparando) {
        pedido.estado = EstadoPedido.listo;
      }
      
      // Si hay alguno preparando, el pedido está preparando
      final algunoPreparando = pedido.items.any((item) => 
          item.estadoItem == EstadoPedido.preparando);
      
      if (algunoPreparando && pedido.estado == EstadoPedido.pendiente) {
        pedido.estado = EstadoPedido.preparando;
      }
      
      await isar.writeTxn(() => isar.pedidos.put(pedido));
    }
  }

  // ==================== OPERACIONES DE INVENTARIO ====================

  /// Obtiene un producto por su ID
  Future<Producto?> obtenerProductoPorId(int id) async {
    return await isar.productos.get(id);
  }

  /// Verifica la disponibilidad de múltiples productos
  /// Retorna una lista de IDs de productos que NO están disponibles
  Future<List<int>> verificarDisponibilidad(List<int> productosIds) async {
    final noDisponibles = <int>[];
    
    for (final id in productosIds) {
      final producto = await isar.productos.get(id);
      if (producto == null || !producto.isAvailable) {
        noDisponibles.add(id);
      }
    }
    
    return noDisponibles;
  }

  /// Actualiza la disponibilidad de un producto
  Future<void> actualizarDisponibilidad(int id, bool disponible) async {
    final producto = await isar.productos.get(id);
    if (producto != null) {
      producto.isAvailable = disponible;
      producto.fechaModificacion = DateTime.now();
      await isar.writeTxn(() => isar.productos.put(producto));
    }
  }

  /// Actualiza el stock de un producto
  /// Nota: Este método actualiza el producto en la base de datos, lo que
  /// automáticamente dispara el stream watchProductos() para todos los listeners
  Future<void> actualizarStock(int id, int nuevoStock) async {
    final producto = await isar.productos.get(id);
    if (producto != null) {
      producto.stockDisponible = nuevoStock;
      producto.stock = nuevoStock; // Legacy - mantener por compatibilidad
      // Marcar como no disponible si el stock llega a 0
      if (nuevoStock <= 0 && producto.usarInventario) {
        producto.isAvailable = false;
        debugPrint('📦 Producto ${producto.nombre} (ID: $id) agotado - stock: $nuevoStock');
      } else if (nuevoStock > 0 && !producto.isAvailable && producto.usarInventario) {
        // Si el stock se repone y estaba marcado como agotado, reactivarlo
        producto.isAvailable = true;
        debugPrint('✅ Producto ${producto.nombre} (ID: $id) reactivado - stock: $nuevoStock');
      }
      producto.fechaModificacion = DateTime.now();
      await isar.writeTxn(() => isar.productos.put(producto));
      debugPrint('🔄 Stock actualizado: ${producto.nombre} → $nuevoStock unidades');
    }
  }

  /// Decrementa el stock de un producto
  Future<bool> decrementarStock(int id, int cantidad) async {
    final producto = await isar.productos.get(id);
    if (producto == null) return false;
    
    // Usar stockDisponible si el producto tiene inventario activado
    if (producto.usarInventario) {
      if (producto.stockDisponible < cantidad) return false;
      producto.stockDisponible = producto.stockDisponible - cantidad;
      producto.stock = producto.stockDisponible; // Sincronizar legacy
      if (producto.stockDisponible <= 0) {
        producto.isAvailable = false;
      }
    } else if (producto.stock != null) {
      // Legacy: usar stock si existe pero no tiene inventario activado
      if (producto.stock! < cantidad) return false;
      producto.stock = producto.stock! - cantidad;
      if (producto.stock! <= 0) {
        producto.isAvailable = false;
      }
    }
    
    producto.fechaModificacion = DateTime.now();
    await isar.writeTxn(() => isar.productos.put(producto));
    return true;
  }

  /// Stream de productos para actualizaciones en tiempo real
  Stream<List<Producto>> watchProductos() {
    return isar.productos
        .where()
        .watch(fireImmediately: true);
  }

  // ==================== OPERACIONES DE CONFIGURACIÓN BUFFET ====================

  /// Obtiene la configuración del buffet activa
  Future<ConfiguracionBuffet?> obtenerConfiguracionBuffetActiva() async {
    return await isar.configuracionBuffets
        .filter()
        .activoEqualTo(true)
        .findFirst();
  }

  /// Obtiene todas las configuraciones de buffet
  Future<List<ConfiguracionBuffet>> obtenerConfiguracionesBuffet() async {
    return await isar.configuracionBuffets.where().findAll();
  }

  /// Guarda o actualiza una configuración de buffet
  Future<int> guardarConfiguracionBuffet(ConfiguracionBuffet config) async {
    config.fechaModificacion = DateTime.now();
    return await isar.writeTxn(() => isar.configuracionBuffets.put(config));
  }

  /// Elimina una configuración de buffet
  Future<bool> eliminarConfiguracionBuffet(int id) async {
    return await isar.writeTxn(() => isar.configuracionBuffets.delete(id));
  }

  /// Verifica si actualmente es horario de buffet
  Future<bool> esHorarioBuffet() async {
    final config = await obtenerConfiguracionBuffetActiva();
    if (config == null) return false;
    return config.esHorarioBuffet();
  }

  /// Obtiene el precio del buffet según la edad
  Future<double?> obtenerPrecioBuffet(int edad) async {
    final config = await obtenerConfiguracionBuffetActiva();
    if (config == null) return null;
    return config.obtenerPrecioPorEdad(edad);
  }

  /// Inicializa configuración por defecto del buffet si no existe
  Future<void> inicializarConfiguracionBuffetDefecto() async {
    final count = await isar.configuracionBuffets.count();
    if (count == 0) {
      debugPrint('Creando configuración de buffet por defecto...');
      final config = ConfiguracionBuffet.sabadoDefault();
      await guardarConfiguracionBuffet(config);
      debugPrint('Configuración de buffet creada');
    }
  }
}
