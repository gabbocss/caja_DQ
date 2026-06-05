import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../models/models.dart';
import '../services/registro_pago_service.dart';

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
          CategoriaSchema,
          CarritoQrMesaSchema,
          BuffetLimiteQrMesaSchema,
          ReservaSchema,
        ],
        directory: dbPath,
        name: 'restaurante',
        inspector: kDebugMode, // Solo en modo debug
      );

      debugPrint('Base de datos inicializada correctamente');
      
      // Inicializar datos por defecto si la DB está vacía
      await _inicializarDatosDefecto();
      // Migrar orden de productos al esquema categoría*1000+índice (una sola vez)
      await _migrarOrdenProductosPorCategoria();
      
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
    }

    // Crear categorías por defecto si la colección está vacía
    final categoriaCount = await _isar!.categorias.count();
    if (categoriaCount == 0) {
      debugPrint('Creando categorías por defecto...');
      await _isar!.writeTxn(() async {
        int orden = 0;
        for (final nombre in CategoriaProducto.todas) {
          final cat = Categoria.crear(nombre: nombre, orden: orden++);
          await _isar!.categorias.put(cat);
        }
      });
      debugPrint('Categorías creadas correctamente');
    }

    if (destinoCount != 0) {
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

  /// Migra el campo orden de productos al esquema categoría*1000+índice (solo si aún están en 0,1,2...).
  Future<void> _migrarOrdenProductosPorCategoria() async {
    final productos = await isar.productos.where().sortByOrden().findAll();
    if (productos.isEmpty) return;
    final maxOrden = productos.map((p) => p.orden).reduce((a, b) => a > b ? a : b);
    if (maxOrden >= 1000) return; // Ya migrado
    final categorias = await obtenerCategorias();
    final ordenPorCategoria = <String, int>{for (final c in categorias) c.nombre: c.orden};
    final indiceEnCategoria = <String, int>{};
    for (final p in productos) {
      final cat = p.categoria ?? '';
      final idx = indiceEnCategoria[cat] ?? 0;
      indiceEnCategoria[cat] = idx + 1;
      p.orden = (ordenPorCategoria[cat] ?? 9999) * 1000 + idx;
    }
    await isar.writeTxn(() async {
      for (final p in productos) {
        await isar.productos.put(p);
      }
    });
    debugPrint('Migración: orden de productos actualizado por categoría');
  }

  /// Recalcula el orden global de los productos según el orden actual de categorías.
  ///
  /// Mantiene el orden interno de cada categoría en base al orden actual de los productos
  /// (si se reordenaron desde "Gestión de productos", se respeta).
  ///
  /// Esto es importante para vistas "TODOS" (p. ej. cliente QR), que dependen de que
  /// `Producto.orden` codifique `categoria*1000 + índice`.
  Future<void> recalcularOrdenProductosPorCategorias() async {
    final categorias = await obtenerCategorias(); // ya viene sortByOrden()
    final ordenPorCategoria = <String, int>{for (final c in categorias) c.nombre: c.orden};

    // Cargar todos los productos en su orden actual para preservar el orden interno por categoría.
    final productos = await isar.productos.where().sortByOrden().findAll();
    if (productos.isEmpty) return;

    // Agrupar por categoría (null -> '') manteniendo el orden actual (sortByOrden()).
    final porCategoria = <String, List<Producto>>{};
    for (final p in productos) {
      final cat = p.categoria ?? '';
      (porCategoria[cat] ??= <Producto>[]).add(p);
    }

    // Orden estable dentro de cada categoría: por orden actual y luego por id.
    for (final entry in porCategoria.entries) {
      entry.value.sort((a, b) {
        final cmp = a.orden.compareTo(b.orden);
        if (cmp != 0) return cmp;
        return (a.id ?? 0).compareTo(b.id ?? 0);
      });
    }

    // Reasignar `orden = catOrden*1000 + idx`.
    // Categorías desconocidas / vacías quedan al final con prefijo 9999.
    var cambios = 0;
    for (final entry in porCategoria.entries) {
      final cat = entry.key;
      final catOrden = ordenPorCategoria[cat] ?? 9999;
      final list = entry.value;
      for (var i = 0; i < list.length; i++) {
        final p = list[i];
        final nuevoOrden = catOrden * 1000 + i;
        if (p.orden != nuevoOrden) {
          p.orden = nuevoOrden;
          cambios++;
        }
      }
    }

    if (cambios == 0) return;
    await isar.writeTxn(() async {
      for (final p in productos) {
        await isar.productos.put(p);
      }
    });
    debugPrint('Reindexado: orden de productos recalculado por categorías ($cambios cambios)');
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
    final list = await isar.productos.where().sortByOrden().findAll();
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
        .sortByOrden()
        .findAll();
  }

  /// Obtiene productos del buffet
  Future<List<Producto>> obtenerProductosBuffet() async {
    final list = await isar.productos
        .filter()
        .esBuffetEqualTo(true)
        .activoEqualTo(true)
        .sortByOrden()
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
    if (producto.id == null) {
      // Nuevo producto: orden = categoría*1000 + índice al final de la categoría
      final categorias = await obtenerCategorias();
      final cat = categorias.where((c) => c.nombre == (producto.categoria ?? '')).firstOrNull;
      final catOrden = cat?.orden ?? 9999;
      final enCategoria = await obtenerProductosPorCategoria(producto.categoria ?? '');
      producto.orden = catOrden * 1000 + enCategoria.length;
    }
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

  // ==================== TOKENS QR (URLs aleatorias por mesa) ====================

  static const _qrTokenChars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static const _qrTokenLength = 20;

  Future<Map<int, String>> _cargarQrTokensMap() async {
    if (_dbPath == null) return {};
    final file = File('$_dbPath/mesa_qr_tokens.json');
    if (!await file.exists()) return {};
    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final map = <int, String>{};
      for (final e in json.entries) {
        final numMesa = int.tryParse(e.key);
        if (numMesa != null && e.value is String) {
          map[numMesa] = e.value as String;
        }
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  Future<void> _guardarQrTokensMap(Map<int, String> map) async {
    if (_dbPath == null) return;
    final file = File('$_dbPath/mesa_qr_tokens.json');
    final json = map.map((k, v) => MapEntry(k.toString(), v));
    await file.writeAsString(const JsonEncoder().convert(json));
  }

  String _generarTokenAleatorio() {
    final rnd = Random.secure();
    return List.generate(
      _qrTokenLength,
      (_) => _qrTokenChars[rnd.nextInt(_qrTokenChars.length)],
    ).join();
  }

  /// Devuelve el token QR para una mesa; si no existe, lo genera y guarda.
  Future<String> getQrTokenForMesa(int numeroMesa) async {
    final map = await _cargarQrTokensMap();
    if (map.containsKey(numeroMesa)) return map[numeroMesa]!;
    final token = _generarTokenAleatorio();
    map[numeroMesa] = token;
    await _guardarQrTokensMap(map);
    return token;
  }

  /// Resuelve un token de la URL a número de mesa. Devuelve null si el token no existe.
  Future<int?> getMesaNumeroPorQrToken(String token) async {
    if (token.isEmpty) return null;
    final map = await _cargarQrTokensMap();
    for (final e in map.entries) {
      if (e.value == token) return e.key;
    }
    return null;
  }

  /// Regenera tokens QR para todas las mesas. Las URLs antiguas dejan de funcionar.
  Future<void> regenerarQrTokens() async {
    final mesas = await isar.mesas.where().sortByNumero().findAll();
    final map = <int, String>{};
    for (final m in mesas) {
      map[m.numero] = _generarTokenAleatorio();
    }
    await _guardarQrTokensMap(map);
    debugPrint('Tokens QR regenerados para ${map.length} mesas');
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
    await RegistroPagoService.instance.archivarPagosMesa(numeroMesa);
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

  /// Pedidos entre dos fechas (inclusive). Para estadísticas.
  Future<List<Pedido>> obtenerPedidosEntreFechas(DateTime desde, DateTime hasta) async {
    return await isar.pedidos
        .filter()
        .fechaCreacionBetween(desde, hasta)
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

  /// Guarda o actualiza un pedido y recalcula pendiente desde Isar.
  Future<int> guardarPedido(Pedido pedido) async {
    pedido.actualizarPendienteDesdeCobrosAcumulados();
    final id = await isar.writeTxn(() => isar.pedidos.put(pedido));
    await sincronizarPendienteMesaDesdeCobros(pedido.mesaNumero);
    return id;
  }

  /// totalPendiente = total − dineroCobradoAcumulado (dato vivo en Isar).
  Future<void> sincronizarPendienteMesaDesdeCobros(int numeroMesa) async {
    final pedidos = await obtenerCuentaMesa(numeroMesa);
    if (pedidos.isEmpty) return;

    await isar.writeTxn(() async {
      for (final pedido in pedidos) {
        pedido.actualizarPendienteDesdeCobrosAcumulados();
        await isar.pedidos.put(pedido);
      }
    });
  }

  /// Suma el importe pendiente de todos los pedidos abiertos de una mesa.
  Future<double> obtenerTotalPendienteMesa(int numeroMesa) async {
    final pedidos = await obtenerCuentaMesa(numeroMesa);
    var suma = 0.0;
    for (final p in pedidos) {
      p.normalizarTotalPendiente();
      suma += p.totalPendienteSeguro;
    }
    return suma;
  }

  /// Reparte un cobro entre los pedidos abiertos de la mesa (más antiguos primero).
  /// Devuelve el pendiente restante tras aplicar el importe.
  Future<double> aplicarPagoMesa(int numeroMesa, double importe) async {
    final pedidos = await obtenerCuentaMesa(numeroMesa);
    pedidos.sort((a, b) => a.fechaCreacion.compareTo(b.fechaCreacion));
    var restanteCobro = importe;

    await isar.writeTxn(() async {
      for (final pedido in pedidos) {
        if (restanteCobro <= 0.009) break;
        pedido.normalizarTotalPendiente();
        final pendientePedido = pedido.totalPendienteSeguro;
        if (pendientePedido <= 0.009) continue;
        final aplicar = restanteCobro < pendientePedido
            ? restanteCobro
            : pendientePedido;
        pedido.dineroCobradoAcumulado += aplicar;
        pedido.actualizarPendienteDesdeCobrosAcumulados();
        restanteCobro -= aplicar;
        await isar.pedidos.put(pedido);
      }
    });

    return obtenerTotalPendienteMesa(numeroMesa);
  }

  /// Actualiza el estado de un pedido
  Future<void> actualizarEstadoPedido(int id, EstadoPedido nuevoEstado) async {
    final pedido = await isar.pedidos.get(id);
    if (pedido != null) {
      pedido.estado = nuevoEstado;
      pedido.fechaActualizacion = DateTime.now();
      if (nuevoEstado == EstadoPedido.preparando) {
        pedido.fechaInicioPreparacion ??= DateTime.now();
      } else if (nuevoEstado == EstadoPedido.listo) {
        pedido.fechaListo = DateTime.now();
      }
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
        .sortByFechaCreacion()
        .watch(fireImmediately: true);
  }

  // ==================== CARRITO QR (BUFFET) ====================

  /// Índice de ventana temporal fija (mismos [minutosVentana] que en configuración).
  static int calcularVentanaBuffetId(DateTime ahora, int minutosVentana) {
    final m = max(1, minutosVentana);
    final durMs = m * 60 * 1000;
    return ahora.millisecondsSinceEpoch ~/ durMs;
  }

  /// Comensales registrados al abrir la mesa (adultos + niños en cuenta abierta).
  Future<int> obtenerComensalesRegistradosBuffetMesa(int mesaNumero) async {
    final cuenta = await obtenerCuentaMesa(mesaNumero);
    // Regla: el límite de tipos se calcula por (menú adulto + menú niño) de la mesa.
    // Si no hay apertura (no aparecen esos menús), se asume 1.
    //
    // Priorizamos numeroComensales si ya viene informado (p. ej. desde la app),
    // y como fallback inferimos por los ítems especiales "Buffet - Adulto" / "Buffet - Niño".
    var maxComensales = 0;
    var maxInferidos = 0;
    for (final p in cuenta) {
      final n = p.numeroComensales;
      if (n != null && n > maxComensales) maxComensales = n;

      var adultos = 0;
      var ninos = 0;
      for (final item in p.items) {
        if (item.nombreProducto == 'Buffet - Adulto') {
          adultos += item.cantidad;
        } else if (item.nombreProducto == 'Buffet - Niño') {
          ninos += item.cantidad;
        }
      }
      final inferidos = adultos + ninos;
      if (inferidos > maxInferidos) maxInferidos = inferidos;
    }

    final res = max(maxComensales, maxInferidos);
    return res > 0 ? res : 1;
  }

  void _sincronizarVentanaBuffetQr(BuffetLimiteQrMesa lim, int minutosVentana) {
    final minT = max(1, minutosVentana);
    final vid = calcularVentanaBuffetId(DateTime.now(), minT);
    if (lim.ventanaIdActual != vid) {
      lim.ventanaIdActual = vid;
      lim.productosDistintosEnviadosEnVentana = [];
    }
  }

  /// Segundos hasta que el cliente QR pueda enviar otro pedido (0 si ya puede).
  /// Solo lectura; no anida transacciones con el carrito.
  Future<int> segundosHastaPoderEnviarBuffetQr(int mesaNumero) async {
    final config = await obtenerConfiguracionBuffetActiva();
    if (config == null || !config.limiteBuffetQrActivo) return 0;
    final minT = max(1, config.buffetMinutosVentana);
    final lim = await isar.buffetLimiteQrMesas
        .filter()
        .mesaNumeroEqualTo(mesaNumero)
        .findFirst();
    final ult = lim?.fechaUltimoEnvioQr;
    if (ult == null) return 0;
    final siguiente = ult.add(Duration(minutes: minT));
    final d = siguiente.difference(DateTime.now());
    return d.isNegative ? 0 : d.inSeconds;
  }

  /// Tras guardar un pedido QR, actualiza tipos distintos enviados en la ventana y fecha de último envío.
  Future<void> registrarEnvioPedidoQrBuffet({
    required int mesaNumero,
    required List<int> productoIdsDistintosEnPedido,
  }) async {
    final config = await obtenerConfiguracionBuffetActiva();
    if (config == null || !config.limiteBuffetQrActivo) return;
    final minT = max(1, config.buffetMinutosVentana);
    await isar.writeTxn(() async {
      var lim = await isar.buffetLimiteQrMesas
          .filter()
          .mesaNumeroEqualTo(mesaNumero)
          .findFirst();
      lim ??= BuffetLimiteQrMesa()
        ..mesaNumero = mesaNumero
        ..ventanaIdActual = 0
        ..productosDistintosEnviadosEnVentana = []
        ..fechaUltimoEnvioQr = null;
      _sincronizarVentanaBuffetQr(lim, minT);
      // Opción C3: el cooldown es independiente y los "tipos" no se acumulan entre envíos.
      // El límite de tipos se valida únicamente con el carrito actual, así que aquí solo
      // marcamos el inicio de la espera y reseteamos el estado de tipos enviados.
      lim.productosDistintosEnviadosEnVentana = const [];
      lim.fechaUltimoEnvioQr = DateTime.now();
      await isar.buffetLimiteQrMesas.put(lim);
    });
  }

  /// Valida cupo de tipos distintos (carrito tras la operación). Devuelve código de error o null.
  Future<String?> _validarLimiteTiposDistintosBuffetQr(
    Isar isar,
    int mesaNumero,
    Set<int> idsCarritoTrasOperacion,
  ) async {
    final config = await obtenerConfiguracionBuffetActiva();
    if (config == null || !config.limiteBuffetQrActivo) return null;
    final minT = max(1, config.buffetMinutosVentana);
    final nPorPersona = max(1, config.buffetTiposDistintosPorPersonaPorVentana);

    var lim = await isar.buffetLimiteQrMesas
        .filter()
        .mesaNumeroEqualTo(mesaNumero)
        .findFirst();
    lim ??= BuffetLimiteQrMesa()
      ..mesaNumero = mesaNumero
      ..ventanaIdActual = calcularVentanaBuffetId(DateTime.now(), minT)
      ..productosDistintosEnviadosEnVentana = [];
    _sincronizarVentanaBuffetQr(lim, minT);
    await isar.buffetLimiteQrMesas.put(lim);

    final comensales = await obtenerComensalesRegistradosBuffetMesa(mesaNumero);
    final cap = comensales * nPorPersona;
    // Opción C3: validar SOLO contra el carrito tras la operación.
    if (idsCarritoTrasOperacion.length > cap) {
      return 'limite_tipos_distintos';
    }
    return null;
  }

  Future<CarritoQrMesa> _obtenerOCrearCarritoQrMesa(int mesaNumero) async {
    final existente = await isar.carritoQrMesas
        .filter()
        .mesaNumeroEqualTo(mesaNumero)
        .findFirst();
    if (existente != null) return existente;
    final nuevo = CarritoQrMesa()
      ..mesaNumero = mesaNumero
      ..items = []
      ..fechaActualizacion = DateTime.now();
    final id = await isar.writeTxn(() => isar.carritoQrMesas.put(nuevo));
    final creado = await isar.carritoQrMesas.get(id);
    return creado ?? nuevo;
  }

  /// Devuelve el carrito comunitario de una mesa.
  Future<List<ItemCarritoQr>> obtenerCarritoQrMesa(int mesaNumero) async {
    final carrito = await _obtenerOCrearCarritoQrMesa(mesaNumero);
    return List<ItemCarritoQr>.from(carrito.items);
  }

  /// Suma [delta] a la cantidad del producto en el carrito (si no existe, lo crea).
  /// Devuelve un código de error si no se puede (p. ej. límite de tipos distintos).
  Future<String?> sumarProductoCarritoQrMesa({
    required int mesaNumero,
    required int productoId,
    required int delta,
    required String nombreProducto,
    required double precioUnitario,
    int? destinoId,
    String? nombreDestino,
  }) async {
    if (delta == 0) return null;
    return isar.writeTxn(() async {
      final carrito = await isar.carritoQrMesas
          .filter()
          .mesaNumeroEqualTo(mesaNumero)
          .findFirst();
      final obj = carrito ??
          (CarritoQrMesa()
            ..mesaNumero = mesaNumero
            ..items = []
            ..fechaActualizacion = DateTime.now());
      // Isar puede devolver listas de longitud fija; trabajar siempre con una copia growable.
      final items = List<ItemCarritoQr>.from(obj.items);
      final idx = items.indexWhere((i) => i.productoId == productoId);
      if (idx >= 0) {
        final actual = items[idx];
        final nueva = actual.cantidad + delta;
        if (nueva <= 0) {
          items.removeAt(idx);
        } else {
          actual.cantidad = nueva;
        }
      } else if (delta > 0) {
        items.add(ItemCarritoQr.crear(
          productoId: productoId,
          nombreProducto: nombreProducto,
          precioUnitario: precioUnitario,
          cantidad: delta,
          destinoId: destinoId,
          nombreDestino: nombreDestino,
        ));
      } else {
        return null;
      }

      final idsDespues = items.map((e) => e.productoId).toSet();
      final err = await _validarLimiteTiposDistintosBuffetQr(isar, mesaNumero, idsDespues);
      if (err != null) return err;

      obj.items = items;
      obj.fechaActualizacion = DateTime.now();
      await isar.carritoQrMesas.put(obj);
      return null;
    });
  }

  /// Establece cantidad exacta de un producto en el carrito (0 = quitar).
  Future<String?> setCantidadProductoCarritoQrMesa({
    required int mesaNumero,
    required int productoId,
    required int cantidad,
    String? nombreProducto,
    double? precioUnitario,
    int? destinoId,
    String? nombreDestino,
  }) async {
    return isar.writeTxn(() async {
      final carrito = await isar.carritoQrMesas
          .filter()
          .mesaNumeroEqualTo(mesaNumero)
          .findFirst();
      final obj = carrito ??
          (CarritoQrMesa()
            ..mesaNumero = mesaNumero
            ..items = []
            ..fechaActualizacion = DateTime.now());
      // Isar puede devolver listas de longitud fija; trabajar siempre con una copia growable.
      final items = List<ItemCarritoQr>.from(obj.items);
      final idx = items.indexWhere((i) => i.productoId == productoId);
      if (cantidad <= 0) {
        if (idx >= 0) items.removeAt(idx);
      } else if (idx >= 0) {
        items[idx].cantidad = cantidad;
      } else {
        items.add(ItemCarritoQr.crear(
          productoId: productoId,
          nombreProducto: nombreProducto ?? 'Producto',
          precioUnitario: precioUnitario ?? 0.0,
          cantidad: cantidad,
          destinoId: destinoId,
          nombreDestino: nombreDestino,
        ));
      }

      final idsDespues = items.map((e) => e.productoId).toSet();
      final err = await _validarLimiteTiposDistintosBuffetQr(isar, mesaNumero, idsDespues);
      if (err != null) return err;

      obj.items = items;
      obj.fechaActualizacion = DateTime.now();
      await isar.carritoQrMesas.put(obj);
      return null;
    });
  }

  /// Vacía el carrito comunitario de una mesa.
  Future<void> limpiarCarritoQrMesa(int mesaNumero) async {
    await isar.writeTxn(() async {
      final carrito = await isar.carritoQrMesas
          .filter()
          .mesaNumeroEqualTo(mesaNumero)
          .findFirst();
      if (carrito == null) return;
      // Evitar mutar listas de longitud fija devueltas por Isar.
      carrito.items = <ItemCarritoQr>[];
      carrito.fechaActualizacion = DateTime.now();
      await isar.carritoQrMesas.put(carrito);
    });
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

  // ==================== OPERACIONES DE CATEGORÍAS ====================

  /// Obtiene todas las categorías ordenadas
  Future<List<Categoria>> obtenerCategorias() async {
    return await isar.categorias
        .where()
        .sortByOrden()
        .findAll();
  }

  /// Guarda o actualiza una categoría
  Future<int> guardarCategoria(Categoria categoria) async {
    return await isar.writeTxn(() => isar.categorias.put(categoria));
  }

  /// Elimina una categoría por ID.
  /// Si hay productos con esa categoría, los deja con categoria=null.
  Future<bool> eliminarCategoria(int id) async {
    return await isar.writeTxn(() async {
      final cat = await isar.categorias.get(id);
      if (cat == null) return false;
      // Actualizar productos que usan esta categoría a null
      final productos = await isar.productos
          .filter()
          .categoriaEqualTo(cat.nombre)
          .findAll();
      for (final p in productos) {
        p.categoria = null;
        await isar.productos.put(p);
      }
      return isar.categorias.delete(id);
    });
  }

  /// Actualiza el nombre de una categoría y todos los productos que la usan
  Future<void> renombrarCategoria(int id, String nuevoNombre) async {
    await isar.writeTxn(() async {
      final cat = await isar.categorias.get(id);
      if (cat == null) return;
      final nombreAntiguo = cat.nombre;
      cat.nombre = nuevoNombre;
      await isar.categorias.put(cat);
      // Actualizar productos
      final productos = await isar.productos
          .filter()
          .categoriaEqualTo(nombreAntiguo)
          .findAll();
      for (final p in productos) {
        p.categoria = nuevoNombre;
        await isar.productos.put(p);
      }
    });
  }

  /// Cuenta cuántos productos usan una categoría
  Future<int> contarProductosPorCategoria(String nombreCategoria) async {
    return await isar.productos
        .filter()
        .categoriaEqualTo(nombreCategoria)
        .count();
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
      final item = pedido.items[itemIndex];
      item.estadoItem = nuevoEstado;
      final ahora = DateTime.now();
      if (nuevoEstado == EstadoPedido.preparando) {
        item.fechaInicioPreparacionItem = ahora;
      } else if (nuevoEstado == EstadoPedido.listo || nuevoEstado == EstadoPedido.servido) {
        item.fechaListoItem = ahora;
      }
      pedido.fechaActualizacion = ahora;
      
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

  /// Stream de productos para actualizaciones en tiempo real (orden: categoría + orden dentro de categoría)
  Stream<List<Producto>> watchProductos() {
    return isar.productos
        .where()
        .sortByOrden()
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

  // ==================== OPERACIONES DE RESERVAS ====================

  Future<int> guardarReserva(Reserva reserva) async {
    reserva.fechaActualizacion = DateTime.now();
    if (reserva.fechaCreacion.millisecondsSinceEpoch == 0) {
      reserva.fechaCreacion = DateTime.now();
    }
    return await isar.writeTxn(() => isar.reservas.put(reserva));
  }

  Future<Reserva?> obtenerReservaPorId(int id) async {
    return await isar.reservas.get(id);
  }

  Future<List<Reserva>> obtenerReservasPendientes() async {
    return await isar.reservas
        .filter()
        .estadoEqualTo(EstadoReserva.pendiente)
        .sortByFechaHoraLlegada()
        .findAll();
  }

  Future<List<Reserva>> obtenerTodasReservas() async {
    return await isar.reservas.where().sortByFechaHoraLlegada().findAll();
  }

  /// Reservas cuya [fechaHoraLlegada] cae en el día civil [dia] (todas los estados).
  Future<List<Reserva>> obtenerReservasDelDia(DateTime dia) async {
    final inicio = DateTime(dia.year, dia.month, dia.day);
    final fin = inicio.add(const Duration(days: 1));
    final todas = await obtenerTodasReservas();
    return todas
        .where(
          (r) =>
              !r.fechaHoraLlegada.isBefore(inicio) &&
              r.fechaHoraLlegada.isBefore(fin),
        )
        .toList()
      ..sort((a, b) => a.fechaHoraLlegada.compareTo(b.fechaHoraLlegada));
  }

  Future<bool> eliminarReserva(int id) async {
    return await isar.writeTxn(() => isar.reservas.delete(id));
  }

  /// Upsert de reservas del VPS; no elimina reservas locales que ya no vienen en el pull.
  Future<void> fusionarReservasRemotas(List<Reserva> remotas) async {
    await isar.writeTxn(() async {
      for (final remota in remotas) {
        if (remota.id != null) {
          final local = await isar.reservas.get(remota.id!);
          if (local != null) {
            remota.fechaCreacion = local.fechaCreacion;
          }
        }
        await isar.reservas.put(remota);
      }
    });
  }

  Future<void> actualizarEstadoReserva(int id, EstadoReserva estado,
      {int? mesaAsignada}) async {
    final reserva = await isar.reservas.get(id);
    if (reserva == null) return;
    reserva.estado = estado;
    if (mesaAsignada != null) reserva.mesaAsignada = mesaAsignada;
    reserva.fechaActualizacion = DateTime.now();
    await isar.writeTxn(() => isar.reservas.put(reserva));
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
