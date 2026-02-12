import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../database/database_service.dart';
import '../models/models.dart';

/// Servidor HTTP local para comunicación entre dispositivos
/// 
/// Permite que la App Web (cocina) y la App Android (meseros)
/// se comuniquen con la base de datos local en la misma red WiFi.
class LocalServer {
  static LocalServer? _instance;
  HttpServer? _server;
  final DatabaseService _db = DatabaseService.instance;

  /// Puerto por defecto del servidor
  static const int defaultPort = 8080;

  /// IP del servidor (se detecta automáticamente)
  String? _serverIp;

  LocalServer._();

  /// Obtiene la instancia singleton
  static LocalServer get instance {
    _instance ??= LocalServer._();
    return _instance!;
  }

  /// Verifica si el servidor está corriendo
  bool get isRunning => _server != null;

  /// Obtiene la IP del servidor
  String? get serverIp => _serverIp;

  /// Obtiene la URL completa del servidor
  String? get serverUrl => _serverIp != null ? 'http://$_serverIp:$defaultPort' : null;

  /// Inicia el servidor HTTP local
  Future<void> start({int port = defaultPort}) async {
    if (_server != null) {
      debugPrint('El servidor ya está corriendo en ${_server!.address.address}:${_server!.port}');
      return;
    }

    try {
      // Obtener la IP local
      _serverIp = await _getLocalIp();
      
      if (_serverIp == null) {
        throw Exception('No se pudo obtener la IP local');
      }

      // Crear el router con las rutas API
      final router = _createRouter();

      // Middleware para logging y CORS
      final handler = const Pipeline()
          .addMiddleware(_logRequests())
          .addMiddleware(_corsHeaders())
          .addHandler(router.call);

      // Escuchar en 0.0.0.0 para aceptar conexiones desde otros dispositivos (ej. móvil por WiFi)
      const host = '0.0.0.0';
      _server = await shelf_io.serve(
        handler,
        host,
        port,
      );

      debugPrint('╔════════════════════════════════════════════════════════════╗');
      debugPrint('║  🚀 Servidor local iniciado correctamente                  ║');
      debugPrint('║  📡 URL: http://$_serverIp:$port                           ║');
      debugPrint('║  💡 Usa esta URL en los dispositivos de la red local       ║');
      debugPrint('╚════════════════════════════════════════════════════════════╝');
      debugPrint('');
      debugPrint('Servidor listo en http://$_serverIp:$port');
      debugPrint('En el móvil escribe esta URL en el navegador: http://$_serverIp:$port');
      debugPrint('');

    } catch (e) {
      debugPrint('Error al iniciar el servidor: $e');
      rethrow;
    }
  }

  /// Detiene el servidor
  Future<void> stop() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
      _serverIp = null;
      debugPrint('Servidor local detenido');
    }
  }

  /// Obtiene la IP local del dispositivo
  Future<String?> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          // Buscar una IP en el rango de red local típico
          if (addr.address.startsWith('192.168.') ||
              addr.address.startsWith('10.') ||
              addr.address.startsWith('172.')) {
            return addr.address;
          }
        }
      }

      // Si no encontramos una IP de red local, usar localhost
      return '127.0.0.1';
    } catch (e) {
      debugPrint('Error obteniendo IP local: $e');
      return '127.0.0.1';
    }
  }

  /// Crea el router con todas las rutas de la API
  Router _createRouter() {
    final router = Router();

    // ==================== RUTAS DE INFORMACIÓN ====================
    
    router.get('/', (Request request) {
      return Response.ok(
        jsonEncode({
          'mensaje': 'API del Sistema de Restaurante',
          'version': '1.0.0',
          'endpoints': {
            'productos': '/api/productos',
            'mesas': '/api/mesas',
            'pedidos': '/api/pedidos',
            'destinos': '/api/destinos',
            'pedidos_destino': '/api/pedidos/destino/<id>',
          }
        }),
        headers: {'Content-Type': 'application/json'},
      );
    });

    router.get('/health', (Request request) {
      return Response.ok(
        jsonEncode({'status': 'ok', 'timestamp': DateTime.now().toIso8601String()}),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // ==================== RUTAS DE PRODUCTOS ====================

    // GET /api/productos - Obtener todos los productos
    router.get('/api/productos', (Request request) async {
      try {
        final productos = await _db.obtenerProductos();
        return Response.ok(
          jsonEncode(productos.map((p) => p.toJson()).toList()),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al obtener productos: $e');
      }
    });

    // GET /api/productos/buffet - Obtener productos del buffet
    router.get('/api/productos/buffet', (Request request) async {
      try {
        final productos = await _db.obtenerProductosBuffet();
        return Response.ok(
          jsonEncode(productos.map((p) => p.toJson()).toList()),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al obtener productos buffet: $e');
      }
    });

    // POST /api/productos - Crear/actualizar producto
    router.post('/api/productos', (Request request) async {
      try {
        final body = await request.readAsString();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final producto = Producto.fromJson(json);
        final id = await _db.guardarProducto(producto);
        return Response.ok(
          jsonEncode({'id': id, 'mensaje': 'Producto guardado correctamente'}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al guardar producto: $e');
      }
    });

    // DELETE /api/productos/<id> - Eliminar producto
    router.delete('/api/productos/<id>', (Request request, String id) async {
      try {
        final success = await _db.eliminarProducto(int.parse(id));
        if (success) {
          return Response.ok(
            jsonEncode({'mensaje': 'Producto eliminado'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
        return Response.notFound(jsonEncode({'error': 'Producto no encontrado'}));
      } catch (e) {
        return _errorResponse('Error al eliminar producto: $e');
      }
    });

    // ==================== RUTAS DE MESAS ====================

    // GET /api/mesas - Obtener todas las mesas
    router.get('/api/mesas', (Request request) async {
      try {
        final mesas = await _db.obtenerMesas();
        return Response.ok(
          jsonEncode(mesas.map((m) => m.toJson()).toList()),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al obtener mesas: $e');
      }
    });

    // GET /api/mesas/<numero> - Obtener mesa por número
    router.get('/api/mesas/<numero>', (Request request, String numero) async {
      try {
        final mesa = await _db.obtenerMesaPorNumero(int.parse(numero));
        if (mesa != null) {
          return Response.ok(
            jsonEncode(mesa.toJson()),
            headers: {'Content-Type': 'application/json'},
          );
        }
        return Response.notFound(jsonEncode({'error': 'Mesa no encontrada'}));
      } catch (e) {
        return _errorResponse('Error al obtener mesa: $e');
      }
    });

    // PUT /api/mesas/<numero>/estado - Actualizar estado de mesa
    router.put('/api/mesas/<numero>/estado', (Request request, String numero) async {
      try {
        final body = await request.readAsString();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final estadoStr = json['estado'] as String;
        final estado = EstadoMesa.values.firstWhere(
          (e) => e.name == estadoStr,
          orElse: () => EstadoMesa.libre,
        );
        await _db.actualizarEstadoMesa(int.parse(numero), estado);
        return Response.ok(
          jsonEncode({'mensaje': 'Estado de mesa actualizado'}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al actualizar estado de mesa: $e');
      }
    });

    // GET /api/mesas/cuentas-abiertas - Mesas con al menos un pedido no pagado
    router.get('/api/mesas/cuentas-abiertas', (Request request) async {
      try {
        final mesas = await _db.obtenerMesasConCuentaAbierta();
        return Response.ok(
          jsonEncode(mesas),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al obtener mesas con cuenta abierta: $e');
      }
    });

    // GET /api/mesas/<numero>/cuenta - Cuenta de la mesa (pedidos no pagados)
    router.get('/api/mesas/<numero>/cuenta', (Request request, String numero) async {
      try {
        final pedidos = await _db.obtenerCuentaMesa(int.parse(numero));
        return Response.ok(
          jsonEncode(pedidos.map((p) => p.toJson()).toList()),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al obtener cuenta de mesa: $e');
      }
    });

    // POST /api/mesas/liberar - Cierra la cuenta de la mesa y la deja libre
    router.post('/api/mesas/liberar', (Request request) async {
      try {
        final body = await request.readAsString();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final numero = json['numero'] as int;
        final isBuffetClose = json['isBuffetClose'] as bool? ?? false;
        await _db.liberarMesa(numero, isBuffetClose: isBuffetClose);
        return Response.ok(
          jsonEncode({'mensaje': 'Mesa $numero liberada correctamente'}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al liberar mesa: $e');
      }
    });

    // ==================== RUTAS DE PEDIDOS ====================

    // GET /api/pedidos - Obtener pedidos activos
    router.get('/api/pedidos', (Request request) async {
      try {
        final pedidos = await _db.obtenerPedidosActivos();
        return Response.ok(
          jsonEncode(pedidos.map((p) => p.toJson()).toList()),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al obtener pedidos: $e');
      }
    });

    // GET /api/pedidos/cocina - Pedidos para la cocina (pendientes y preparando)
    router.get('/api/pedidos/cocina', (Request request) async {
      try {
        final pendientes = await _db.obtenerPedidosPorEstado(EstadoPedido.pendiente);
        final preparando = await _db.obtenerPedidosPorEstado(EstadoPedido.preparando);
        final pedidos = [...pendientes, ...preparando];
        return Response.ok(
          jsonEncode(pedidos.map((p) => p.toJson()).toList()),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al obtener pedidos para cocina: $e');
      }
    });

    // GET /api/pedidos/mesa/<numero> - Pedidos de una mesa
    router.get('/api/pedidos/mesa/<numero>', (Request request, String numero) async {
      try {
        final pedidos = await _db.obtenerPedidosDeMesa(int.parse(numero));
        return Response.ok(
          jsonEncode(pedidos.map((p) => p.toJson()).toList()),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al obtener pedidos de mesa: $e');
      }
    });

    // POST /api/pedidos - Crear/actualizar pedido
    router.post('/api/pedidos', (Request request) async {
      try {
        final body = await request.readAsString();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final pedido = Pedido.fromJson(json);
        
        // Validar disponibilidad de productos antes de guardar
        final productosNoDisponibles = <String>[];
        for (final item in pedido.items) {
          final producto = await _db.obtenerProductoPorId(item.productoId);
          if (producto == null || !producto.isAvailable) {
            productosNoDisponibles.add(item.nombreProducto);
          }
          // Si el producto usa inventario, verificar stock suficiente
          if (producto != null && producto.usarInventario) {
            if (producto.stockDisponible < item.cantidad) {
              productosNoDisponibles.add('${item.nombreProducto} (stock insuficiente)');
            }
          }
        }
        
        // Si hay productos no disponibles, rechazar el pedido
        if (productosNoDisponibles.isNotEmpty) {
          return Response(
            400,
            body: jsonEncode({
              'error': 'Productos no disponibles',
              'productos_agotados': productosNoDisponibles,
              'mensaje': 'Los siguientes productos ya no están disponibles: ${productosNoDisponibles.join(", ")}',
            }),
            headers: {'Content-Type': 'application/json'},
          );
        }
        
        // ========== DESCONTAR STOCK AUTOMÁTICAMENTE ==========
        for (final item in pedido.items) {
          final producto = await _db.obtenerProductoPorId(item.productoId);
          if (producto != null && producto.usarInventario) {
            final nuevoStock = producto.stockDisponible - item.cantidad;
            await _db.actualizarStock(producto.id!, nuevoStock);
            if (nuevoStock <= 0) {
              await _db.actualizarDisponibilidad(producto.id!, false);
            }
          }
        }
        
        final id = await _db.guardarPedido(pedido);
        
        // Actualizar estado de la mesa a ocupada
        await _db.actualizarEstadoMesa(pedido.mesaNumero, EstadoMesa.ocupada);
        
        return Response.ok(
          jsonEncode({'id': id, 'mensaje': 'Pedido guardado correctamente'}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al guardar pedido: $e');
      }
    });

    // PUT /api/pedidos/<id>/estado - Actualizar estado de pedido
    router.put('/api/pedidos/<id>/estado', (Request request, String id) async {
      try {
        final body = await request.readAsString();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final estadoStr = json['estado'] as String;
        final estado = EstadoPedido.values.firstWhere(
          (e) => e.name == estadoStr,
          orElse: () => EstadoPedido.pendiente,
        );
        await _db.actualizarEstadoPedido(int.parse(id), estado);
        return Response.ok(
          jsonEncode({'mensaje': 'Estado de pedido actualizado'}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al actualizar estado de pedido: $e');
      }
    });

    // PUT /api/pedidos/<id>/item/<index>/estado - Actualizar estado de un item
    router.put('/api/pedidos/<id>/item/<index>/estado', (Request request, String id, String index) async {
      try {
        final body = await request.readAsString();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final estadoStr = json['estado'] as String;
        final estado = EstadoPedido.values.firstWhere(
          (e) => e.name == estadoStr,
          orElse: () => EstadoPedido.pendiente,
        );
        await _db.actualizarEstadoItem(int.parse(id), int.parse(index), estado);
        return Response.ok(
          jsonEncode({'mensaje': 'Estado de item actualizado'}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al actualizar estado de item: $e');
      }
    });

    // GET /api/pedidos/destino/<id> - Pedidos filtrados por destino
    router.get('/api/pedidos/destino/<destinoId>', (Request request, String destinoId) async {
      try {
        final pedidos = await _db.obtenerPedidosPorDestino(int.parse(destinoId));
        
        // Preparar respuesta con items filtrados por destino
        final respuesta = pedidos.map((pedido) {
          final itemsFiltrados = pedido.items
              .where((item) => item.destinoId == int.parse(destinoId))
              .toList();
          
          return {
            ...pedido.toJson(),
            'items': itemsFiltrados.map((item) => item.toJson()).toList(),
          };
        }).toList();
        
        return Response.ok(
          jsonEncode(respuesta),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al obtener pedidos por destino: $e');
      }
    });

    // ==================== RUTAS DE DESTINOS ====================

    // GET /api/destinos - Obtener todos los destinos
    router.get('/api/destinos', (Request request) async {
      try {
        final destinos = await _db.obtenerDestinos();
        return Response.ok(
          jsonEncode(destinos.map((d) => d.toJson()).toList()),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al obtener destinos: $e');
      }
    });

    // GET /api/destinos/activos - Obtener destinos activos
    router.get('/api/destinos/activos', (Request request) async {
      try {
        final destinos = await _db.obtenerDestinosActivos();
        return Response.ok(
          jsonEncode(destinos.map((d) => d.toJson()).toList()),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al obtener destinos activos: $e');
      }
    });

    // GET /api/destinos/<id> - Obtener destino por ID
    router.get('/api/destinos/<id>', (Request request, String id) async {
      try {
        final destino = await _db.obtenerDestinoPorId(int.parse(id));
        if (destino != null) {
          return Response.ok(
            jsonEncode(destino.toJson()),
            headers: {'Content-Type': 'application/json'},
          );
        }
        return Response.notFound(jsonEncode({'error': 'Destino no encontrado'}));
      } catch (e) {
        return _errorResponse('Error al obtener destino: $e');
      }
    });

    // POST /api/destinos - Crear/actualizar destino
    router.post('/api/destinos', (Request request) async {
      try {
        final body = await request.readAsString();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final destino = DestinoImpresion.fromJson(json);
        final id = await _db.guardarDestino(destino);
        return Response.ok(
          jsonEncode({'id': id, 'mensaje': 'Destino guardado correctamente'}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al guardar destino: $e');
      }
    });

    // DELETE /api/destinos/<id> - Eliminar destino
    router.delete('/api/destinos/<id>', (Request request, String id) async {
      try {
        final success = await _db.eliminarDestino(int.parse(id));
        if (success) {
          return Response.ok(
            jsonEncode({'mensaje': 'Destino eliminado'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
        return Response.notFound(jsonEncode({'error': 'Destino no encontrado'}));
      } catch (e) {
        return _errorResponse('Error al eliminar destino: $e');
      }
    });

    // ==================== RUTAS DE CLIENTES QR ====================

    // GET /qr/<mesa> - Página web simplificada para clientes
    router.get('/qr/<mesa>', (Request request, String mesa) async {
      try {
        final mesaNumero = int.parse(mesa);
        final productos = await _db.obtenerProductosBuffet();
        
        // Verificar si es horario de buffet
        final esHorarioBuffet = await _db.esHorarioBuffet();
        
        return Response.ok(
          _generarPaginaClienteQR(mesaNumero, productos, esHorarioBuffet),
          headers: {'Content-Type': 'text/html; charset=utf-8'},
        );
      } catch (e) {
        return _errorResponse('Error al cargar página QR: $e');
      }
    });

    // POST /api/qr/pedido - Crear pedido desde cliente QR
    router.post('/api/qr/pedido', (Request request) async {
      try {
        final body = await request.readAsString();
        final json = jsonDecode(body) as Map<String, dynamic>;
        
        // Crear pedido con origen QR
        final pedido = Pedido()
          ..mesaNumero = json['mesaNumero'] as int
          ..usuarioCamarero = 'CLIENTE QR'
          ..origen = OrigenPedido.qr
          ..estado = EstadoPedido.pendiente
          ..esBuffet = json['esBuffet'] as bool? ?? false
          ..fechaCreacion = DateTime.now()
          ..fechaActualizacion = DateTime.now()
          ..total = 0
          ..items = [];
        
        // Procesar items
        final itemsJson = json['items'] as List<dynamic>;
        for (final itemJson in itemsJson) {
          final item = ItemPedido.fromJson(itemJson as Map<String, dynamic>);
          pedido.items.add(item);
        }
        
        // Validar disponibilidad de productos antes de guardar
        final productosNoDisponibles = <String>[];
        for (final item in pedido.items) {
          final producto = await _db.obtenerProductoPorId(item.productoId);
          if (producto == null || !producto.isAvailable) {
            productosNoDisponibles.add(item.nombreProducto);
          }
          // Si el producto usa inventario, verificar stock suficiente
          if (producto != null && producto.usarInventario) {
            if (producto.stockDisponible < item.cantidad) {
              productosNoDisponibles.add('${item.nombreProducto} (stock insuficiente)');
            }
          }
        }
        
        // Si hay productos no disponibles, rechazar el pedido
        if (productosNoDisponibles.isNotEmpty) {
          return Response(
            400,
            body: jsonEncode({
              'error': 'Productos no disponibles',
              'productos_agotados': productosNoDisponibles,
              'mensaje': 'Los siguientes productos ya no están disponibles: ${productosNoDisponibles.join(", ")}',
            }),
            headers: {'Content-Type': 'application/json'},
          );
        }
        
        // ========== DESCONTAR STOCK AUTOMÁTICAMENTE ==========
        for (final item in pedido.items) {
          final producto = await _db.obtenerProductoPorId(item.productoId);
          if (producto != null && producto.usarInventario) {
            final nuevoStock = producto.stockDisponible - item.cantidad;
            await _db.actualizarStock(producto.id!, nuevoStock);
            if (nuevoStock <= 0) {
              await _db.actualizarDisponibilidad(producto.id!, false);
            }
          }
        }
        
        pedido.calcularTotal();
        final id = await _db.guardarPedido(pedido);
        
        // Actualizar estado de la mesa a ocupada
        await _db.actualizarEstadoMesa(pedido.mesaNumero, EstadoMesa.ocupada);
        
        debugPrint('📱 Pedido QR #$id recibido para mesa ${pedido.mesaNumero}');
        
        return Response.ok(
          jsonEncode({
            'id': id, 
            'mensaje': '¡Pedido enviado! Tu pedido llegará pronto.',
            'origen': 'qr',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al procesar pedido QR: $e');
      }
    });

    // GET /api/productos/disponibles - Productos disponibles para clientes
    router.get('/api/productos/disponibles', (Request request) async {
      try {
        final productos = await _db.obtenerProductos();
        final disponibles = productos.where((p) => p.activo && p.isAvailable).toList();
        return Response.ok(
          jsonEncode(disponibles.map((p) => p.toJson()).toList()),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al obtener productos disponibles: $e');
      }
    });

    // PUT /api/productos/<id>/disponibilidad - Actualizar disponibilidad
    router.put('/api/productos/<id>/disponibilidad', (Request request, String id) async {
      try {
        final body = await request.readAsString();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final disponible = json['disponible'] as bool;
        await _db.actualizarDisponibilidad(int.parse(id), disponible);
        return Response.ok(
          jsonEncode({'mensaje': 'Disponibilidad actualizada'}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al actualizar disponibilidad: $e');
      }
    });

    // ==================== VALIDACIÓN PRE-VUELO ====================
    
    // POST /api/productos/validar-stock - Validar disponibilidad de múltiples productos
    // Endpoint ultra rápido para verificar antes de enviar un pedido
    // Formato de entrada: { "items": [{"id": 1, "cantidad": 4}, ...] }
    router.post('/api/productos/validar-stock', (Request request) async {
      try {
        final body = await request.readAsString();
        final json = jsonDecode(body) as Map<String, dynamic>;
        
        // Soporte para formato antiguo (solo IDs) y nuevo (items con cantidad)
        List<Map<String, dynamic>> items;
        if (json.containsKey('items')) {
          items = (json['items'] as List<dynamic>).cast<Map<String, dynamic>>();
        } else if (json.containsKey('ids')) {
          // Formato legacy: solo IDs, asumir cantidad 1
          final ids = (json['ids'] as List<dynamic>).cast<int>();
          items = ids.map((id) => {'id': id, 'cantidad': 1}).toList();
        } else {
          return _errorResponse('Formato inválido: se requiere "items" o "ids"');
        }
        
        final resultados = <Map<String, dynamic>>[];
        final errores = <Map<String, dynamic>>[];
        bool tieneErrores = false;
        
        for (final item in items) {
          final id = item['id'] as int;
          final cantidadSolicitada = item['cantidad'] as int? ?? 1;
          final producto = await _db.obtenerProductoPorId(id);
          
          if (producto == null) {
            errores.add({
              'id': id,
              'nombre': 'Producto desconocido',
              'solicitado': cantidadSolicitada,
              'disponible': 0,
              'error': 'no_existe',
            });
            tieneErrores = true;
            continue;
          }
          
          if (!producto.isAvailable) {
            errores.add({
              'id': id,
              'nombre': producto.nombre,
              'solicitado': cantidadSolicitada,
              'disponible': 0,
              'error': 'agotado',
            });
            tieneErrores = true;
            continue;
          }
          
          // Si el producto usa inventario, verificar stock
          if (producto.usarInventario) {
            final stockDisponible = producto.stockDisponible;
            
            if (stockDisponible < cantidadSolicitada) {
              // Stock parcial disponible
              errores.add({
                'id': id,
                'nombre': producto.nombre,
                'solicitado': cantidadSolicitada,
                'disponible': stockDisponible,
                'error': 'parcial',
              });
              tieneErrores = true;
            } else {
              // Stock suficiente
              resultados.add({
                'id': id,
                'nombre': producto.nombre,
                'disponible': true,
                'stock': stockDisponible,
              });
            }
          } else {
            // Producto sin control de inventario, siempre disponible
            resultados.add({
              'id': id,
              'nombre': producto.nombre,
              'disponible': true,
            });
          }
        }
        
        return Response.ok(
          jsonEncode({
            'valido': !tieneErrores,
            'productos': resultados,
            'errores': errores,
            'mensaje': tieneErrores 
                ? 'Hay problemas con algunos productos' 
                : 'Todos los productos están disponibles',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al validar stock: $e');
      }
    });

    return router;
  }

  /// Genera la página HTML para clientes QR
  String _generarPaginaClienteQR(int mesa, List<Producto> productos, bool esHorarioBuffet) {
    final productosHtml = productos.map((p) => '''
      <div class="producto ${p.isAvailable ? '' : 'agotado'}" data-id="${p.id}" data-nombre="${p.nombre}" data-precio="${p.precio}">
        <div class="producto-info">
          <span class="nombre">${p.nombre}</span>
          ${p.descripcion != null ? '<span class="descripcion">${p.descripcion}</span>' : ''}
          <span class="precio">${p.isAvailable ? '${p.precio.toStringAsFixed(2)}€' : 'AGOTADO'}</span>
        </div>
        ${p.isAvailable ? '<button class="btn-agregar" onclick="agregarAlCarrito(${p.id}, \'${p.nombre.replaceAll("'", "\\'")}\', ${p.precio}, ${p.destinoId ?? 'null'})">+</button>' : ''}
      </div>
    ''').join('\n');

    return '''
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>Pedir - Mesa $mesa</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: linear-gradient(135deg, #1A1A2E 0%, #16213E 100%);
      color: white;
      min-height: 100vh;
      padding-bottom: 120px;
    }
    .header {
      background: #16213E;
      padding: 16px 20px;
      position: sticky;
      top: 0;
      z-index: 100;
      box-shadow: 0 4px 20px rgba(0,0,0,0.3);
    }
    .header h1 {
      font-size: 18px;
      color: #FFD700;
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .header .mesa {
      background: #E94560;
      padding: 4px 12px;
      border-radius: 20px;
      font-size: 14px;
      color: white;
    }
    ${esHorarioBuffet ? '''
    .buffet-banner {
      background: linear-gradient(90deg, #FFD700, #FFA500);
      color: #1A1A2E;
      text-align: center;
      padding: 12px;
      font-weight: bold;
      font-size: 14px;
    }
    ''' : ''}
    .productos {
      padding: 16px;
      display: flex;
      flex-direction: column;
      gap: 12px;
    }
    .producto {
      background: #16213E;
      border-radius: 12px;
      padding: 16px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      border: 1px solid #0F3460;
    }
    .producto.agotado {
      opacity: 0.5;
      background: #2A2A2A;
    }
    .producto-info {
      display: flex;
      flex-direction: column;
      gap: 4px;
      flex: 1;
    }
    .nombre { font-weight: bold; font-size: 16px; }
    .descripcion { font-size: 12px; color: #888; }
    .precio { color: #00D9A5; font-weight: bold; font-size: 18px; }
    .btn-agregar {
      background: #E94560;
      border: none;
      color: white;
      width: 44px;
      height: 44px;
      border-radius: 12px;
      font-size: 24px;
      font-weight: bold;
      cursor: pointer;
      flex-shrink: 0;
      margin-left: 12px;
    }
    .btn-agregar:active { transform: scale(0.95); }
    /* Botón flotante del carrito (móvil) */
    .btn-carrito-flotante {
      position: fixed;
      bottom: 24px;
      right: 20px;
      width: 56px;
      height: 56px;
      border-radius: 50%;
      background: linear-gradient(135deg, #E94560, #FF6B6B);
      border: none;
      color: white;
      box-shadow: 0 4px 20px rgba(233, 69, 96, 0.5);
      cursor: pointer;
      z-index: 100;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 26px;
      transition: transform 0.2s, box-shadow 0.2s;
    }
    .btn-carrito-flotante:active { transform: scale(0.95); }
    .btn-carrito-flotante .carrito-badge {
      position: absolute;
      top: -4px;
      right: -4px;
      min-width: 20px;
      height: 20px;
      border-radius: 10px;
      background: #E94560;
      color: white;
      font-size: 12px;
      font-weight: bold;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 0 5px;
      border: 2px solid #1A1A2E;
    }
    .btn-carrito-flotante .carrito-badge.oculto { display: none; }
    /* Panel desplegable del carrito */
    .carrito-drawer-overlay {
      position: fixed;
      inset: 0;
      background: rgba(0,0,0,0.5);
      z-index: 150;
      display: none;
      transition: opacity 0.3s;
    }
    .carrito-drawer-overlay.visible { display: block; }
    .carrito-drawer {
      position: fixed;
      top: 0;
      right: 0;
      width: 100%;
      max-width: 320px;
      height: 100%;
      background: #16213E;
      box-shadow: -4px 0 20px rgba(0,0,0,0.3);
      z-index: 160;
      display: flex;
      flex-direction: column;
      transform: translateX(100%);
      transition: transform 0.3s ease-out;
    }
    .carrito-drawer.abierto { transform: translateX(0); }
    .carrito-drawer-header {
      padding: 20px;
      border-bottom: 1px solid #0F3460;
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-shrink: 0;
    }
    .carrito-drawer-header h2 { margin: 0; font-size: 20px; color: #eee; }
    .btn-cerrar-drawer {
      background: transparent;
      border: none;
      color: #888;
      font-size: 24px;
      cursor: pointer;
      padding: 0 8px;
      line-height: 1;
    }
    .btn-cerrar-drawer:active { color: #fff; }
    .carrito-drawer-lista {
      flex: 1;
      overflow: auto;
      padding: 12px;
      -webkit-overflow-scrolling: touch;
    }
    .carrito-drawer-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 12px;
      margin-bottom: 8px;
      background: #0F3460;
      border-radius: 12px;
      font-size: 15px;
    }
    .carrito-drawer-item .nombre { color: #eee; flex: 1; }
    .carrito-drawer-item .cantidad { color: #00D9A5; font-weight: bold; margin: 0 8px; }
    .carrito-drawer-vacio {
      color: #888;
      text-align: center;
      padding: 24px 16px;
      font-size: 15px;
    }
    .carrito-drawer-footer {
      padding: 16px 20px;
      border-top: 2px solid #E94560;
      flex-shrink: 0;
    }
    .btn-enviar {
      background: linear-gradient(135deg, #E94560, #FF6B6B);
      border: none;
      color: white;
      padding: 14px 28px;
      border-radius: 12px;
      font-size: 16px;
      font-weight: bold;
      cursor: pointer;
      text-transform: uppercase;
      letter-spacing: 1px;
      width: 100%;
    }
    .btn-enviar:disabled { background: #333; cursor: not-allowed; }
    .btn-enviar:active:not(:disabled) { transform: scale(0.98); }
    .mensaje {
      position: fixed;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      background: #16213E;
      padding: 32px;
      border-radius: 20px;
      text-align: center;
      z-index: 200;
      display: none;
      border: 2px solid #00D9A5;
      max-width: 300px;
    }
    .mensaje.visible { display: block; }
    .mensaje h2 { color: #00D9A5; margin-bottom: 16px; }
    .mensaje p { margin-bottom: 20px; }
    .btn-aceptar-mensaje {
      background: #00D9A5;
      color: #1A1A2E;
      border: none;
      padding: 12px 28px;
      border-radius: 12px;
      font-size: 16px;
      font-weight: bold;
      cursor: pointer;
    }
    .btn-aceptar-mensaje:active { opacity: 0.9; }
    .overlay {
      position: fixed;
      inset: 0;
      background: rgba(0,0,0,0.7);
      z-index: 150;
      display: none;
    }
    .overlay.visible { display: block; }
    
    /* Estilos para productos marcados como agotados durante el envío */
    .producto.marcado-error {
      border: 2px solid #E94560 !important;
      animation: shake 0.5s ease-in-out;
    }
    @keyframes shake {
      0%, 100% { transform: translateX(0); }
      25% { transform: translateX(-5px); }
      75% { transform: translateX(5px); }
    }
    
    /* Diálogo de error para productos agotados */
    .dialog-overlay {
      position: fixed;
      inset: 0;
      background: rgba(0,0,0,0.85);
      z-index: 300;
      display: flex;
      justify-content: center;
      align-items: center;
      animation: fadeIn 0.3s ease-out;
    }
    @keyframes fadeIn {
      from { opacity: 0; }
      to { opacity: 1; }
    }
    .dialog-error {
      background: #16213E;
      padding: 28px;
      border-radius: 20px;
      text-align: center;
      max-width: 350px;
      margin: 16px;
      border: 2px solid #E94560;
      box-shadow: 0 0 30px rgba(233, 69, 96, 0.3);
    }
    .dialog-icon {
      font-size: 48px;
      margin-bottom: 16px;
    }
    .dialog-error h2 {
      color: #E94560;
      margin-bottom: 12px;
      font-size: 22px;
    }
    .dialog-error p {
      color: #aaa;
      font-size: 14px;
      margin-bottom: 16px;
    }
    .lista-agotados {
      list-style: none;
      padding: 12px;
      background: #0F3460;
      border-radius: 10px;
      margin-bottom: 16px;
      text-align: left;
      max-height: 150px;
      overflow-y: auto;
    }
    .lista-agotados li {
      color: #E94560;
      padding: 8px 0;
      border-bottom: 1px solid #1a1a2e;
      font-weight: 500;
    }
    .lista-agotados li:last-child {
      border-bottom: none;
    }
    .lista-ajustes {
      list-style: none;
      padding: 12px;
      background: #0F3460;
      border-radius: 10px;
      margin-bottom: 16px;
      text-align: left;
      max-height: 150px;
      overflow-y: auto;
    }
    .lista-ajustes li {
      color: #FFA500;
      padding: 8px 0;
      border-bottom: 1px solid #1a1a2e;
      font-weight: 500;
      line-height: 1.5;
    }
    .lista-ajustes li:last-child {
      border-bottom: none;
    }
    .seccion-ajustes, .seccion-agotados {
      margin-bottom: 12px;
    }
    .dialog-hint {
      color: #888;
      font-size: 12px;
      font-style: italic;
    }
    .btn-dialog {
      background: #E94560;
      color: white;
      border: none;
      padding: 14px 32px;
      border-radius: 12px;
      font-size: 16px;
      font-weight: bold;
      cursor: pointer;
      margin-top: 12px;
      width: 100%;
    }
    .btn-dialog:active {
      background: #c73850;
    }
    /* Mis Pedidos realizados */
    .mis-pedidos-section {
      padding: 16px;
      background: #0F3460;
      margin: 0 16px 16px;
      border-radius: 12px;
      border: 1px solid #16213E;
    }
    .mis-pedidos-section h2 {
      color: #00D9A5;
      font-size: 16px;
      margin-bottom: 12px;
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .mis-pedidos-lista {
      display: flex;
      flex-direction: column;
      gap: 8px;
    }
    .mis-pedidos-vacio {
      color: #888;
      font-size: 14px;
      padding: 12px 0;
      text-align: center;
    }
    .item-pedido-realizado {
      background: #16213E;
      padding: 12px 14px;
      border-radius: 10px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 8px;
      border-left: 4px solid #00D9A5;
    }
    .item-pedido-realizado .nombre-cantidad {
      color: white;
      font-weight: 500;
      font-size: 14px;
    }
    .item-pedido-realizado .estado-badge {
      font-size: 12px;
      font-weight: bold;
      padding: 4px 10px;
      border-radius: 20px;
    }
    .item-pedido-realizado .estado-preparacion {
      background: #FFA500;
      color: #1A1A2E;
    }
    .item-pedido-realizado .estado-servido {
      background: #00D9A5;
      color: #1A1A2E;
    }
  </style>
</head>
<body>
  <div class="header">
    <h1>
      <span>🍽️ Realizar Pedido</span>
      <span class="mesa">Mesa $mesa</span>
    </h1>
  </div>
  
  ${esHorarioBuffet ? '<div class="buffet-banner">⭐ BUFFET ALL YOU CAN EAT ACTIVO ⭐</div>' : ''}
  
  <div class="productos">
    $productosHtml
  </div>
  
  <div class="mis-pedidos-section">
    <h2>📋 Mis Pedidos realizados</h2>
    <div id="mis-pedidos-lista" class="mis-pedidos-lista"></div>
  </div>
  
  <button class="btn-carrito-flotante" id="btn-carrito-flotante" onclick="toggleCarritoDrawer()" aria-label="Ver carrito">
    <span class="carrito-icon">🛒</span>
    <span class="carrito-badge oculto" id="carrito-badge">0</span>
  </button>
  
  <div class="carrito-drawer-overlay" id="carrito-drawer-overlay" onclick="cerrarCarritoDrawer()"></div>
  <div class="carrito-drawer" id="carrito-drawer">
    <div class="carrito-drawer-header">
      <h2>Tu carrito</h2>
      <button class="btn-cerrar-drawer" onclick="cerrarCarritoDrawer()" aria-label="Cerrar">✕</button>
    </div>
    <div class="carrito-drawer-lista" id="carrito-drawer-lista"></div>
    <div class="carrito-drawer-footer">
      <button class="btn-enviar" id="btn-enviar" disabled onclick="enviarPedido()">Enviar Pedido</button>
    </div>
  </div>
  
  <div class="overlay" id="overlay"></div>
  <div class="mensaje" id="mensaje">
    <h2>✅ ¡Pedido Enviado!</h2>
    <p>Tu pedido llegará pronto a tu mesa.</p>
    <button class="btn-aceptar-mensaje" onclick="cerrarMensajeYRecargar()">Aceptar</button>
  </div>
  
  <script>
    const mesa = $mesa;
    const esBuffet = $esHorarioBuffet;
    let carrito = [];
    
    function estadoItemATexto(estadoItem) {
      if (estadoItem === 'pendiente' || estadoItem === 'preparando') return { texto: 'En preparación', clase: 'estado-preparacion' };
      if (estadoItem === 'listo' || estadoItem === 'servido') return { texto: 'Servido', clase: 'estado-servido' };
      return { texto: estadoItem || 'En preparación', clase: 'estado-preparacion' };
    }
    
    async function refrescarMisPedidos() {
      const contenedor = document.getElementById('mis-pedidos-lista');
      if (!contenedor) return;
      try {
        const response = await fetch('/api/mesas/' + mesa + '/cuenta');
        if (!response.ok) {
          contenedor.innerHTML = '<div class="mis-pedidos-vacio">No se pudieron cargar los pedidos.</div>';
          return;
        }
        const pedidos = await response.json();
        const items = [];
        (pedidos || []).forEach(function(p) {
          if (p.items && p.items.length) {
            p.items.forEach(function(item) {
              items.push({
                nombre: item.nombreProducto || 'Producto',
                cantidad: item.cantidad || 1,
                estadoItem: item.estadoItem || 'pendiente'
              });
            });
          }
        });
        if (items.length === 0) {
          contenedor.innerHTML = '<div class="mis-pedidos-vacio">Aún no tienes pedidos en la cuenta. Añade productos y envía el pedido.</div>';
          return;
        }
        const html = items.map(function(it) {
          const e = estadoItemATexto(it.estadoItem);
          const linea = it.cantidad > 1 ? it.nombre + ' x' + it.cantidad : it.nombre;
          return '<div class="item-pedido-realizado"><span class="nombre-cantidad">' + linea + '</span><span class="estado-badge ' + e.clase + '">' + e.texto + '</span></div>';
        }).join('');
        contenedor.innerHTML = html;
      } catch (err) {
        console.error('Error cargando mis pedidos:', err);
        contenedor.innerHTML = '<div class="mis-pedidos-vacio">Error al cargar. Reintenta en un momento.</div>';
      }
    }
    
    function agregarAlCarrito(id, nombre, precio, destinoId) {
      const existente = carrito.find(item => item.productoId === id);
      if (existente) {
        existente.cantidad++;
      } else {
        carrito.push({
          productoId: id,
          nombreProducto: nombre,
          precioUnitario: precio,
          cantidad: 1,
          destinoId: destinoId
        });
      }
      actualizarUI();
    }
    
    function actualizarUI() {
      const totalItems = carrito.reduce((sum, item) => sum + item.cantidad, 0);
      const badge = document.getElementById('carrito-badge');
      if (badge) {
        badge.textContent = totalItems > 99 ? '99+' : totalItems;
        badge.classList.toggle('oculto', totalItems === 0);
      }
      document.getElementById('btn-enviar').disabled = totalItems === 0;
      renderCarritoEnDrawer();
    }
    
    function renderCarritoEnDrawer() {
      const lista = document.getElementById('carrito-drawer-lista');
      if (!lista) return;
      if (carrito.length === 0) {
        lista.innerHTML = '<div class="carrito-drawer-vacio">Añade productos desde la carta y pulsa Enviar pedido cuando termines.</div>';
        return;
      }
      lista.innerHTML = carrito.map(function(item) {
        const linea = item.cantidad > 1 ? item.nombreProducto + ' x' + item.cantidad : item.nombreProducto;
        return '<div class="carrito-drawer-item"><span class="nombre">' + linea + '</span><span class="cantidad">' + item.cantidad + '</span></div>';
      }).join('');
    }
    
    function toggleCarritoDrawer() {
      const drawer = document.getElementById('carrito-drawer');
      const overlay = document.getElementById('carrito-drawer-overlay');
      if (drawer.classList.contains('abierto')) {
        cerrarCarritoDrawer();
      } else {
        renderCarritoEnDrawer();
        drawer.classList.add('abierto');
        overlay.classList.add('visible');
      }
    }
    
    function cerrarCarritoDrawer() {
      document.getElementById('carrito-drawer').classList.remove('abierto');
      document.getElementById('carrito-drawer-overlay').classList.remove('visible');
    }
    
    async function enviarPedido() {
      if (carrito.length === 0) return;
      
      const btn = document.getElementById('btn-enviar');
      btn.disabled = true;
      btn.textContent = 'Verificando...';
      
      try {
        // ========== VALIDACIÓN PRE-VUELO ==========
        const itemsParaValidar = carrito.map(item => ({
          id: item.productoId,
          cantidad: item.cantidad
        }));
        
        const validacionResponse = await fetch('/api/productos/validar-stock', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ items: itemsParaValidar })
        });
        
        if (!validacionResponse.ok) {
          throw new Error('Error al validar disponibilidad');
        }
        
        const validacion = await validacionResponse.json();
        
        // Si hay errores, procesarlos
        if (!validacion.valido && validacion.errores && validacion.errores.length > 0) {
          const ajustes = [];
          const agotados = [];
          
          for (const error of validacion.errores) {
            if (error.error === 'parcial' && error.disponible > 0) {
              // Stock parcial: ajustar cantidad en el carrito
              ajustes.push(error);
              const itemIndex = carrito.findIndex(item => item.productoId === error.id);
              if (itemIndex >= 0) {
                carrito[itemIndex].cantidad = error.disponible;
              }
            } else {
              // Producto completamente agotado
              agotados.push(error);
            }
          }
          
          // Eliminar productos completamente agotados del carrito
          const agotadosIds = agotados.map(e => e.id);
          carrito = carrito.filter(item => !agotadosIds.includes(item.productoId));
          
          // Actualizar UI
          actualizarUI();
          
          // Mostrar diálogo con información detallada
          mostrarDialogoValidacionStock(ajustes, agotados);
          
          btn.disabled = carrito.length === 0;
          btn.textContent = 'Enviar Pedido';
          
          // Si hay productos completamente agotados, no continuar
          if (agotados.length > 0) {
            return;
          }
          
          // Si solo hubo ajustes, continuar con el pedido ajustado
        }
        
        // ========== ENVIAR PEDIDO ==========
        btn.textContent = 'Enviando...';
        
        const response = await fetch('/api/qr/pedido', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            mesaNumero: mesa,
            esBuffet: esBuffet,
            items: carrito
          })
        });
        
        if (response.ok) {
          cerrarCarritoDrawer();
          carrito = [];
          actualizarUI();
          refrescarMisPedidos();
          document.getElementById('overlay').classList.add('visible');
          document.getElementById('mensaje').classList.add('visible');
        } else {
          const errorData = await response.json().catch(() => ({}));
          if (errorData.productos_agotados) {
            mostrarDialogoAgotados(errorData.productos_agotados);
          } else {
            alert('Error al enviar el pedido. Inténtalo de nuevo.');
          }
        }
      } catch (e) {
        console.error('Error:', e);
        alert('Error de conexión. Verifica tu conexión WiFi.');
      } finally {
        btn.disabled = carrito.length === 0;
        btn.textContent = 'Enviar Pedido';
      }
    }
    
    function cerrarMensajeYRecargar() {
      document.getElementById('overlay').classList.remove('visible');
      document.getElementById('mensaje').classList.remove('visible');
      location.reload();
    }
    
    function marcarProductosAgotados(ids) {
      // Marcar visualmente los productos agotados en la lista
      document.querySelectorAll('.producto').forEach(el => {
        const productoId = parseInt(el.dataset.id);
        if (ids.includes(productoId)) {
          el.classList.add('agotado', 'marcado-error');
          el.querySelector('.btn-agregar')?.remove();
          const precioEl = el.querySelector('.precio');
          if (precioEl) precioEl.textContent = 'AGOTADO';
        }
      });
      
      // Quitar del carrito los productos agotados
      carrito = carrito.filter(item => !ids.includes(item.productoId));
      actualizarUI();
    }
    
    function mostrarDialogoValidacionStock(ajustes, agotados) {
      const tieneAjustes = ajustes.length > 0;
      const tieneAgotados = agotados.length > 0;
      
      // Crear overlay del diálogo
      const dialogOverlay = document.createElement('div');
      dialogOverlay.className = 'dialog-overlay';
      
      let contenidoAjustes = '';
      if (tieneAjustes) {
        contenidoAjustes = `
          <div class="seccion-ajustes">
            <h3 style="color: #FFA500; margin-bottom: 12px; font-size: 16px;">Ajustes Automáticos:</h3>
            <ul class="lista-ajustes">
              \${ajustes.map(a => 
                '<li>⚠️ <strong>' + a.nombre + '</strong>: Pediste <strong>' + a.solicitado + '</strong>, pero solo quedan <strong style="color: #FFA500;">' + a.disponible + '</strong></li>'
              ).join('')}
            </ul>
            <p class="dialog-hint" style="color: #FFA500; margin-top: 8px;">Hemos ajustado tu pedido automáticamente.</p>
          </div>
        `;
      }
      
      let contenidoAgotados = '';
      if (tieneAgotados) {
        contenidoAgotados = `
          <div class="seccion-agotados" style="margin-top: \${tieneAjustes ? '16px' : '0'};">
            <h3 style="color: #E94560; margin-bottom: 12px; font-size: 16px;">Productos Agotados:</h3>
            <ul class="lista-agotados">
              \${agotados.map(a => '<li>❌ ' + a.nombre + '</li>').join('')}
            </ul>
            <p class="dialog-hint" style="color: #E94560; margin-top: 8px;">Se han eliminado del carrito automáticamente.</p>
          </div>
        `;
      }
      
      dialogOverlay.innerHTML = `
        <div class="dialog-error">
          <div class="dialog-icon">\${(tieneAjustes && !tieneAgotados) ? '⚠️' : '❌'}</div>
          <h2>\${(tieneAjustes && !tieneAgotados) ? 'Ajuste de Cantidades' : tieneAjustes && tieneAgotados ? 'Problemas con el Pedido' : 'Productos Agotados'}</h2>
          \${contenidoAjustes}
          \${contenidoAgotados}
          <button class="btn-dialog" onclick="this.closest('.dialog-overlay').remove()">
            \${(tieneAjustes && !tieneAgotados) ? 'CONTINUAR CON AJUSTES' : 'ENTENDIDO'}
          </button>
        </div>
      `;
      document.body.appendChild(dialogOverlay);
    }
    
    function mostrarDialogoAgotados(nombres) {
      mostrarDialogoValidacionStock([], nombres.map(n => ({nombre: n})));
    }
    
    refrescarMisPedidos();
  </script>
</body>
</html>
''';
  }

  /// Middleware para logging de requests
  Middleware _logRequests() {
    return (Handler innerHandler) {
      return (Request request) async {
        final stopwatch = Stopwatch()..start();
        final response = await innerHandler(request);
        stopwatch.stop();
        
        debugPrint(
          '[${DateTime.now().toIso8601String()}] '
          '${request.method} ${request.url} '
          '→ ${response.statusCode} '
          '(${stopwatch.elapsedMilliseconds}ms)',
        );
        
        return response;
      };
    };
  }

  /// Middleware para headers CORS
  Middleware _corsHeaders() {
    return (Handler innerHandler) {
      return (Request request) async {
        // Manejar preflight OPTIONS
        if (request.method == 'OPTIONS') {
          return Response.ok(
            '',
            headers: {
              'Access-Control-Allow-Origin': '*',
              'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
              'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
            },
          );
        }

        final response = await innerHandler(request);
        
        return response.change(headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
        });
      };
    };
  }

  /// Genera una respuesta de error estandarizada
  Response _errorResponse(String mensaje, {int statusCode = 500}) {
    return Response(
      statusCode,
      body: jsonEncode({'error': mensaje}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
