import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';

import '../database/database_service.dart';
import '../models/models.dart';
import '../services/imprimir_pedido_service.dart';
import '../services/registro_pago_service.dart';
import '../services/reserva_persistence_service.dart';
import 'api_endpoints.dart';

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

  /// Ruta a build/web para servir la app Flutter web (cocina, etc.)
  String _webRoot = '';

  /// Sesiones activas: sessionId -> fecha de expiración
  final Map<String, DateTime> _sessions = {};

  static const String _cookieSessionName = 'cocina_session';
  static const int _sessionHours = 24;

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

      // Ruta a la app web: primero junto al ejecutable (distribución), luego build/web (desarrollo)
      final executableDir = p.dirname(Platform.resolvedExecutable);
      final webJuntoAlExe = p.join(executableDir, 'web');
      final webEnBuild = p.join(Directory.current.path, 'build', 'web');
      final dirJuntoAlExe = Directory(webJuntoAlExe);
      final dirBuildWeb = Directory(webEnBuild);
      if (await dirJuntoAlExe.exists()) {
        _webRoot = webJuntoAlExe;
        debugPrint('App web: sirviendo desde carpeta junto al ejecutable ($_webRoot)');
      } else if (await dirBuildWeb.exists()) {
        _webRoot = webEnBuild;
        debugPrint('App web: sirviendo desde build/web (desarrollo)');
      } else {
        _webRoot = '';
      }
      final webDir = Directory(_webRoot);
      final bool webDirExists = _webRoot.isNotEmpty && await webDir.exists();

      // Crear el router con las rutas API y login
      final router = _createRouter();

      // Handler principal: intentar servir app web si build/web existe; si no, solo API (para que el servidor arranque y se vea la URL)
      Handler mainHandler;
      try {
        if (!webDirExists) {
          debugPrint('⚠️ No se encontró la app web. En desarrollo: ejecuta "flutter build web". En el .exe: copia la carpeta "web" (contenido de build/web) junto al ejecutable.');
          mainHandler = (Request request) async {
            final response = await router.call(request);
            if (response.statusCode == 404 && _isAppPath(request.url.path)) {
              final sessionId = _getSessionFromRequest(request);
              if (!_isValidSession(sessionId)) {
                final redirect = request.url.path.isEmpty ? '/' : request.url.path;
                return Response.ok(
                  _loginPageHtml(redirect),
                  headers: {'Content-Type': 'text/html; charset=utf-8'},
                );
              }
              return Response.notFound(
                'App web no disponible. Copia la carpeta "web" (contenido de build/web del proyecto) en la misma carpeta que el ejecutable.',
              );
            }
            return response;
          };
        } else {
          final staticHandler = createStaticHandler(_webRoot, defaultDocument: 'index.html');
          final staticOrIndexHandler = (Request request) async {
            var response = await staticHandler(request);
            if (response.statusCode == 404) {
              final path = request.url.path;
              if (!path.contains('.') && !path.startsWith('/api')) {
                final indexFile = File(p.join(_webRoot, 'index.html'));
                if (await indexFile.exists()) {
                  return Response.ok(
                    await indexFile.readAsString(),
                    headers: {'Content-Type': 'text/html; charset=utf-8'},
                  );
                }
              }
            }
            return response;
          };
          mainHandler = (Request request) async {
            final response = await router.call(request);
            if (response.statusCode == 404 && _isAppPath(request.url.path)) {
              final sessionId = _getSessionFromRequest(request);
              if (!_isValidSession(sessionId)) {
                final redirect = request.url.path.isEmpty ? '/' : request.url.path;
                return Response.ok(
                  _loginPageHtml(redirect),
                  headers: {'Content-Type': 'text/html; charset=utf-8'},
                );
              }
              final appResponse = await staticOrIndexHandler(request);
              // Sin caché en el HTML de la SPA para que "Reintentar sin caché" obtenga versión nueva
              final headers = Map<String, String>.from(appResponse.headers);
              headers['Cache-Control'] = 'no-cache';
              return appResponse.change(headers: headers);
            }
            return response;
          };
        }
      } catch (e) {
        debugPrint('⚠️ No se pudo configurar la app web: $e. Servidor solo API.');
        mainHandler = router.call;
      }

      // Middleware para logging y CORS
      final handler = const Pipeline()
          .addMiddleware(_logRequests())
          .addMiddleware(_corsHeaders())
          .addHandler(mainHandler);

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
      debugPrint('App web (cocina): http://$_serverIp:$port/cocina (protegida con contraseña)');
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

    // ==================== QR CLIENTES (primero para que no lo capture otra ruta) ====================
    router.get('/qr/<token>', (Request request, String token) async {
      try {
        final mesaNumero = await _db.getMesaNumeroPorQrToken(token);
        if (mesaNumero == null) {
          return Response.notFound(
            jsonEncode({'error': 'Enlace no válido o caducado. Escanee el QR de su mesa.'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
        // Productos ya vienen ordenados por orden (categoría*1000 + índice en categoría)
        final productos = await _db.obtenerProductosBuffet();
        final esHorarioBuffet = await _db.esHorarioBuffet();
        final html = await _generarPaginaClienteQR(mesaNumero, token, productos, esHorarioBuffet);
        return Response.ok(
          html,
          headers: {'Content-Type': 'text/html; charset=utf-8'},
        );
      } catch (e) {
        return _errorResponse('Error al cargar página QR: $e');
      }
    });

    // ==================== CARRITO QR COMUNITARIO (persistente) ====================

    // GET /api/qr/carrito/<token> - Obtiene carrito comunitario de la mesa del token
    router.get('/api/qr/carrito/<token>', (Request request, String token) async {
      try {
        final mesaNumero = await _db.getMesaNumeroPorQrToken(token);
        if (mesaNumero == null) {
          return Response(404, body: jsonEncode({'error': 'Token no válido'}), headers: {'Content-Type': 'application/json'});
        }
        final items = await _db.obtenerCarritoQrMesa(mesaNumero);
        final segundos = await _db.segundosHastaPoderEnviarBuffetQr(mesaNumero);
        return Response.ok(
          jsonEncode({
            'mesaNumero': mesaNumero,
            'items': items.map((i) => i.toJson()).toList(),
            'segundosHastaPoderEnviar': segundos,
          }),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al obtener carrito QR: $e');
      }
    });

    // POST /api/qr/carrito/<token>/add - Suma 1 (o delta) a un producto en el carrito
    router.post('/api/qr/carrito/<token>/add', (Request request, String token) async {
      try {
        final mesaNumero = await _db.getMesaNumeroPorQrToken(token);
        if (mesaNumero == null) {
          return Response(404, body: jsonEncode({'error': 'Token no válido'}), headers: {'Content-Type': 'application/json'});
        }
        final body = await request.readAsString();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final productoId = (json['productoId'] as num).toInt();
        final delta = (json['delta'] as num?)?.toInt() ?? 1;

        final producto = await _db.obtenerProductoPorId(productoId);
        if (producto == null) {
          return Response(400, body: jsonEncode({'error': 'Producto no encontrado'}), headers: {'Content-Type': 'application/json'});
        }
        final errSum = await _db.sumarProductoCarritoQrMesa(
          mesaNumero: mesaNumero,
          productoId: productoId,
          delta: delta,
          nombreProducto: producto.nombre,
          precioUnitario: producto.precio,
          destinoId: producto.destinoId,
          nombreDestino: null,
        );
        final items = await _db.obtenerCarritoQrMesa(mesaNumero);
        final segundos = await _db.segundosHastaPoderEnviarBuffetQr(mesaNumero);
        if (errSum != null) {
          return Response(
            403,
            body: jsonEncode({
              'error': errSum,
              'items': items.map((i) => i.toJson()).toList(),
              'segundosHastaPoderEnviar': segundos,
            }),
            headers: {'Content-Type': 'application/json'},
          );
        }
        return Response.ok(
          jsonEncode({
            'ok': true,
            'items': items.map((i) => i.toJson()).toList(),
            'segundosHastaPoderEnviar': segundos,
          }),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al modificar carrito QR: $e');
      }
    });

    // POST /api/qr/carrito/<token>/set - Establece cantidad exacta
    router.post('/api/qr/carrito/<token>/set', (Request request, String token) async {
      try {
        final mesaNumero = await _db.getMesaNumeroPorQrToken(token);
        if (mesaNumero == null) {
          return Response(404, body: jsonEncode({'error': 'Token no válido'}), headers: {'Content-Type': 'application/json'});
        }
        final body = await request.readAsString();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final productoId = (json['productoId'] as num).toInt();
        final cantidad = (json['cantidad'] as num).toInt();

        final producto = await _db.obtenerProductoPorId(productoId);
        if (producto == null) {
          return Response(400, body: jsonEncode({'error': 'Producto no encontrado'}), headers: {'Content-Type': 'application/json'});
        }
        final errSet = await _db.setCantidadProductoCarritoQrMesa(
          mesaNumero: mesaNumero,
          productoId: productoId,
          cantidad: cantidad,
          nombreProducto: producto.nombre,
          precioUnitario: producto.precio,
          destinoId: producto.destinoId,
          nombreDestino: null,
        );
        final items = await _db.obtenerCarritoQrMesa(mesaNumero);
        final segundos = await _db.segundosHastaPoderEnviarBuffetQr(mesaNumero);
        if (errSet != null) {
          return Response(
            403,
            body: jsonEncode({
              'error': errSet,
              'items': items.map((i) => i.toJson()).toList(),
              'segundosHastaPoderEnviar': segundos,
            }),
            headers: {'Content-Type': 'application/json'},
          );
        }
        return Response.ok(
          jsonEncode({
            'ok': true,
            'items': items.map((i) => i.toJson()).toList(),
            'segundosHastaPoderEnviar': segundos,
          }),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al establecer cantidad carrito QR: $e');
      }
    });

    // POST /api/qr/carrito/<token>/remove - Quita un producto
    router.post('/api/qr/carrito/<token>/remove', (Request request, String token) async {
      try {
        final mesaNumero = await _db.getMesaNumeroPorQrToken(token);
        if (mesaNumero == null) {
          return Response(404, body: jsonEncode({'error': 'Token no válido'}), headers: {'Content-Type': 'application/json'});
        }
        final body = await request.readAsString();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final productoId = (json['productoId'] as num).toInt();
        await _db.setCantidadProductoCarritoQrMesa(
          mesaNumero: mesaNumero,
          productoId: productoId,
          cantidad: 0,
        );
        final items = await _db.obtenerCarritoQrMesa(mesaNumero);
        final segundos = await _db.segundosHastaPoderEnviarBuffetQr(mesaNumero);
        return Response.ok(
          jsonEncode({
            'ok': true,
            'items': items.map((i) => i.toJson()).toList(),
            'segundosHastaPoderEnviar': segundos,
          }),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al quitar producto del carrito QR: $e');
      }
    });

    // POST /api/qr/carrito/<token>/clear - Vacía carrito
    router.post('/api/qr/carrito/<token>/clear', (Request request, String token) async {
      try {
        final mesaNumero = await _db.getMesaNumeroPorQrToken(token);
        if (mesaNumero == null) {
          return Response(404, body: jsonEncode({'error': 'Token no válido'}), headers: {'Content-Type': 'application/json'});
        }
        await _db.limpiarCarritoQrMesa(mesaNumero);
        return Response.ok(
          jsonEncode({'ok': true}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al limpiar carrito QR: $e');
      }
    });

    // ==================== RUTAS DE INFORMACIÓN ====================
    // GET /api devuelve la info de la API (la app web se sirve en /, /cocina, etc. con protección)

    router.get('/api', (Request request) {
      return Response.ok(
        jsonEncode({
          'mensaje': 'API del Sistema de Restaurante',
          'version': '1.0.0',
          'endpoints': {
            'productos': '/api/productos',
            'mesas': '/api/mesas',
            'pedidos': '/api/pedidos',
            'reservas': ApiEndpoints.reservas,
            'destinos': '/api/destinos',
            'pedidos_destino': '/api/pedidos/destino/<id>',
          }
        }),
        headers: {'Content-Type': 'application/json'},
      );
    });

    Response healthOk() => Response.ok(
          jsonEncode({
            'status': 'ok',
            'timestamp': DateTime.now().toIso8601String(),
          }),
          headers: {'Content-Type': 'application/json'},
        );

    router.get(ApiEndpoints.health, (Request request) => healthOk());
    router.get(ApiEndpoints.healthApi, (Request request) => healthOk());

    // ==================== LOGIN APP WEB (cocina, etc.) ====================
    router.get('/login', (Request request) {
      final redirect = request.url.queryParameters['redirect'] ?? '/cocina';
      return Response.ok(
        _loginPageHtml(redirect),
        headers: {'Content-Type': 'text/html; charset=utf-8'},
      );
    });

    router.post('/login', (Request request) async {
      try {
        final body = await request.readAsString();
        final params = Uri.splitQueryString(body);
        final password = (params['password'] ?? '').toString().trim();
        final redirect = (params['redirect'] ?? '/cocina').toString().trim();
        final expected = await _getCocinaPassword();
        if (expected.isEmpty || password != expected) {
          return Response(
            401,
            body: _loginPageHtml(redirect, error: 'Contraseña incorrecta'),
            headers: {'Content-Type': 'text/html; charset=utf-8'},
          );
        }
        final sessionId = _generateSessionId();
        _sessions[sessionId] = DateTime.now().add(Duration(hours: _sessionHours));
        final path = redirect.startsWith('/') ? redirect : '/$redirect';
        return Response.found(
          request.url.replace(path: path).toString(),
          headers: {
            'Set-Cookie': '$_cookieSessionName=$sessionId; Path=/; HttpOnly; Max-Age=${_sessionHours * 3600}; SameSite=Lax',
          },
        );
      } catch (e) {
        return _errorResponse('Error en login: $e');
      }
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

    // GET /api/categorias - Obtener todas las categorías
    router.get('/api/categorias', (Request request) async {
      try {
        final categorias = await _db.obtenerCategorias();
        return Response.ok(
          jsonEncode(categorias.map((c) => c.toJson()).toList()),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al obtener categorías: $e');
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

    // GET /api/mesas/cuentas-abiertas - Mesas con al menos un pedido no pagado
    // DEBE ir ANTES de /api/mesas/<numero> para que no capture "cuentas-abiertas" como numero
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

    // GET /api/mesas/<numero>/qr - URL del QR para pedir buffet en esa mesa (UI camarero)
    router.get('/api/mesas/<numero>/qr', (Request request, String numero) async {
      try {
        final numeroMesa = int.parse(numero);
        final token = await _db.getQrTokenForMesa(numeroMesa);
        final baseUrl = serverUrl ?? 'http://localhost:$defaultPort';
        final url = '$baseUrl/qr/$token';
        return Response.ok(
          jsonEncode({'url': url}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al obtener QR de mesa: $e');
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

    // POST /api/mesas/pago - Cobro parcial o total sobre la cuenta abierta
    router.post('/api/mesas/pago', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body) as Map<String, dynamic>;
        final numero = data['numero'] as int;
        final importe = (data['importe'] as num).toDouble();
        final metodo = data['metodo'] as String;
        final importeRecibido = (data['importeRecibido'] as num?)?.toDouble();
        final pagoTotal = data['pagoTotal'] as bool? ?? false;

        final pendienteAntes = await _db.obtenerTotalPendienteMesa(numero);
        final esPagoTotal = pagoTotal || importe >= pendienteAntes - 0.009;
        final double importeCobrado = esPagoTotal
            ? pendienteAntes
            : importe.clamp(0, pendienteAntes).toDouble();

        final double? vuelto = importeRecibido != null && esPagoTotal
            ? (importeRecibido - importeCobrado)
                .clamp(0, double.infinity)
                .toDouble()
            : null;

        double pendienteRestante;
        if (esPagoTotal) {
          await RegistroPagoService.instance.registrar(
            RegistroPago(
              fecha: DateTime.now(),
              mesaNumero: numero,
              metodo: metodo,
              importeCobrado: importeCobrado,
              esParcial: false,
              importeRecibido: importeRecibido,
              vuelto: vuelto,
              pendienteRestante: 0,
              cerrado: true,
            ),
          );
          pendienteRestante = 0;
          final isBuffetClose = data['isBuffetClose'] as bool? ?? false;
          await _db.liberarMesa(numero, isBuffetClose: isBuffetClose);
        } else {
          pendienteRestante = await _db.aplicarPagoMesa(numero, importeCobrado);
          await RegistroPagoService.instance.registrar(
            RegistroPago(
              fecha: DateTime.now(),
              mesaNumero: numero,
              metodo: metodo,
              importeCobrado: importeCobrado,
              esParcial: true,
              importeRecibido: importeRecibido,
              vuelto: vuelto,
              pendienteRestante: pendienteRestante,
            ),
          );
        }

        final pedidos = await _db.obtenerCuentaMesa(numero);
        return Response.ok(
          jsonEncode({
            'pendienteRestante': pendienteRestante,
            'esPagoTotal': esPagoTotal,
            'importeCobrado': importeCobrado,
            'pedidos': pedidos.map((p) => p.toJson()).toList(),
          }),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al registrar pago: $e');
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

    // ==================== RUTAS DE RESERVAS ====================

    // GET /api/reservas — solo pendientes (servidor central / caja)
    router.get(ApiEndpoints.reservas, (Request request) async {
      try {
        final reservas =
            await ReservaPersistenceService.instance.obtenerReservasPendientes();
        return Response.ok(
          jsonEncode(reservas.map((r) => r.toJson()).toList()),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al obtener reservas: $e');
      }
    });

    // POST /api/reservas — crear o modificar (con id en body = actualización)
    router.post(ApiEndpoints.reservas, (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body) as Map<String, dynamic>;
        final reserva = Reserva.fromJson(data);
        await ReservaPersistenceService.instance.guardarReserva(reserva);
        final id = reserva.id;
        final guardada = id != null
            ? await ReservaPersistenceService.instance.obtenerPorId(id)
            : reserva;
        return Response.ok(
          jsonEncode((guardada ?? reserva).toJson()),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al guardar reserva: $e');
      }
    });

    // PUT /api/reservas/<id>/estado — p. ej. marcar sentada desde la caja
    router.put('${ApiEndpoints.reservas}/<id>/estado', (Request request, String id) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body) as Map<String, dynamic>;
        final estado = EstadoReserva.values.firstWhere(
          (e) => e.name == data['estado'],
          orElse: () => EstadoReserva.pendiente,
        );
        final mesaAsignada = data['mesaAsignada'] as int?;
        final reservaId = int.parse(id);
        await _db.actualizarEstadoReserva(
          reservaId,
          estado,
          mesaAsignada: mesaAsignada,
        );
        final actualizada = await _db.obtenerReservaPorId(reservaId);
        if (actualizada != null) {
          await ReservaPersistenceService.instance.guardarReserva(actualizada);
        }
        return Response.ok(
          jsonEncode(actualizada?.toJson()),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al actualizar estado reserva: $e');
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

    // GET /api/pedidos/cocina - Pedidos para la cocina (pendientes y preparando). Orden: más antiguos primero (nuevos abajo en modo buffet).
    // Se serializa id como string para que la web no pierda precisión (JS Number < 2^53).
    router.get('/api/pedidos/cocina', (Request request) async {
      try {
        final pendientes = await _db.obtenerPedidosPorEstado(EstadoPedido.pendiente);
        final preparando = await _db.obtenerPedidosPorEstado(EstadoPedido.preparando);
        final pedidos = [...pendientes, ...preparando];
        pedidos.sort((a, b) => a.fechaCreacion.compareTo(b.fechaCreacion));
        final list = pedidos.map((p) {
          final m = Map<String, dynamic>.from(p.toJson());
          if (p.id != null) m['id'] = p.id.toString();
          return m;
        }).toList();
        return Response.ok(
          jsonEncode(list),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al obtener pedidos para cocina: $e');
      }
    });

    // POST /api/cocina/imprimir-ticket - Imprime ticket desde UI cocina (web); el servidor envía a la impresora configurada o impresora buffet
    router.post('/api/cocina/imprimir-ticket', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body) as Map<String, dynamic>;
        final mesaNumero = data['mesaNumero'] as int;
        final nombreProducto = data['nombreProducto'] as String;
        final productoId = data['productoId'] as int;
        final cantidad = data['cantidad'] as int;
        final destinoId = data['destinoId'] as int?;
        final precioUnitario = (data['precioUnitario'] as num).toDouble();
        final useBuffetPrinter = data['useBuffetPrinter'] as bool? ?? false;
        final item = ItemPedido.crear(
          productoId: productoId,
          nombreProducto: nombreProducto,
          precioUnitario: precioUnitario,
          cantidad: cantidad,
          destinoId: destinoId,
        );
        final pedido = Pedido.crear(
          mesaNumero: mesaNumero,
          usuarioCamarero: 'Buffet',
          items: [item],
        );
        pedido.fechaCreacion = DateTime.now();
        pedido.fechaActualizacion = DateTime.now();
        if (useBuffetPrinter) {
          final configBuffet = await _db.obtenerConfiguracionBuffetActiva();
          if (configBuffet != null && configBuffet.tieneImpresoraBuffet) {
            final host = configBuffet.impresoraBuffetIp!.trim();
            final port = configBuffet.impresoraBuffetPuerto ?? 9100;
            await ImprimirPedidoService.instance.imprimirPedidoEnImpresora(
              pedido,
              host,
              port,
            );
            return Response.ok(
              jsonEncode({'ok': true}),
              headers: {'Content-Type': 'application/json'},
            );
          }
        }
        await ImprimirPedidoService.instance.imprimirPedido(pedido);
        return Response.ok(
          jsonEncode({'ok': true}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        debugPrint('Error al imprimir ticket cocina: $e');
        return _errorResponse('Error al imprimir ticket: $e');
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
        
        // Validar disponibilidad de productos antes de guardar (omitir ítems especiales: Cubiertos, Buffet con productoId <= 0)
        final productosNoDisponibles = <String>[];
        for (final item in pedido.items) {
          if (item.productoId <= 0) continue;
          final producto = await _db.obtenerProductoPorId(item.productoId);
          if (producto == null || !producto.isAvailable) {
            productosNoDisponibles.add(item.nombreProducto);
          }
          // Si el producto usa inventario, verificar stock suficiente
          else if (producto.usarInventario) {
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
          if (item.productoId <= 0) continue;
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

        // Imprimir en impresoras por destino (igual que pedidos desde UI servidor / QR)
        pedido.id = id;
        ImprimirPedidoService.instance.imprimirPedido(pedido).catchError((e, st) {
          debugPrint('Error al imprimir pedido (app): $e');
        });
        
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

    // GET /api/configuracion-buffet - Configuración de buffet activa (precio cubierto, horarios, etc.)
    router.get('/api/configuracion-buffet', (Request request) async {
      try {
        final config = await _db.obtenerConfiguracionBuffetActiva();
        if (config == null) {
          return Response.notFound(
            jsonEncode({'error': 'No hay configuración de buffet activa'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
        return Response.ok(
          jsonEncode(config.toJson()),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return _errorResponse('Error al obtener configuración buffet: $e');
      }
    });

    // POST /api/qr/pedido - Crear pedido desde cliente QR (solo en horario de buffet)
    router.post('/api/qr/pedido', (Request request) async {
      try {
        final body = await request.readAsString();
        final json = jsonDecode(body) as Map<String, dynamic>;

        // Solo permitir pedidos desde la web si estamos en horario de buffet
        final enHorarioBuffet = await _db.esHorarioBuffet();
        if (!enHorarioBuffet) {
          return Response(
            403,
            body: jsonEncode({
              'error': 'Fuera de horario',
              'mensaje': 'Solo se pueden enviar pedidos en horario de buffet. Consulta los horarios en el restaurante.',
            }),
            headers: {'Content-Type': 'application/json'},
          );
        }

        final token = json['token'] as String?;
        int mesaNumero;
        if (token != null && token.trim().isNotEmpty) {
          final n = await _db.getMesaNumeroPorQrToken(token.trim());
          if (n == null) {
            return Response(404, body: jsonEncode({'error': 'Token no válido'}), headers: {'Content-Type': 'application/json'});
          }
          mesaNumero = n;
        } else {
          mesaNumero = json['mesaNumero'] as int;
        }

        // Crear pedido con origen QR
        final pedido = Pedido()
          ..mesaNumero = mesaNumero
          ..usuarioCamarero = 'CLIENTE QR'
          ..origen = OrigenPedido.qr
          ..estado = EstadoPedido.pendiente
          ..esBuffet = json['esBuffet'] as bool? ?? false
          ..fechaCreacion = DateTime.now()
          ..fechaActualizacion = DateTime.now()
          ..total = 0
          ..items = [];
        
        // Procesar items: si viene token, usamos el carrito comunitario persistido
        if (token != null && token.trim().isNotEmpty) {
          final carritoItems = await _db.obtenerCarritoQrMesa(mesaNumero);
          for (final c in carritoItems) {
            final item = ItemPedido.crear(
              productoId: c.productoId,
              nombreProducto: c.nombreProducto,
              precioUnitario: c.precioUnitario,
              cantidad: c.cantidad,
              destinoId: c.destinoId,
              nombreDestino: c.nombreDestino,
            );
            pedido.items.add(item);
          }
        } else {
          final itemsJson = (json['items'] as List<dynamic>? ?? const []);
          for (final itemJson in itemsJson) {
            final item = ItemPedido.fromJson(itemJson as Map<String, dynamic>);
            pedido.items.add(item);
          }
        }

        if (pedido.items.isEmpty) {
          return Response(
            400,
            body: jsonEncode({'error': 'Carrito vacío', 'mensaje': 'No hay platos para enviar.'}),
            headers: {'Content-Type': 'application/json'},
          );
        }

        // Tiempo de espera obligatorio entre envíos (cliente QR + límite buffet activo)
        if (token != null && token.trim().isNotEmpty) {
          final cfgLim = await _db.obtenerConfiguracionBuffetActiva();
          if (cfgLim != null && cfgLim.limiteBuffetQrActivo) {
            final espera = await _db.segundosHastaPoderEnviarBuffetQr(mesaNumero);
            if (espera > 0) {
              return Response(
                429,
                body: jsonEncode({
                  'error': 'espera_envio',
                  'segundosRestantes': espera,
                  'mensaje': 'Aún no puedes enviar otro pedido.',
                }),
                headers: {'Content-Type': 'application/json'},
              );
            }
          }
        }
        
        // Validar disponibilidad de productos antes de guardar (omitir ítems especiales con productoId <= 0)
        final productosNoDisponibles = <String>[];
        for (final item in pedido.items) {
          if (item.productoId <= 0) continue;
          final producto = await _db.obtenerProductoPorId(item.productoId);
          if (producto == null || !producto.isAvailable) {
            productosNoDisponibles.add(item.nombreProducto);
          }
          else if (producto.usarInventario) {
            if (producto.stockDisponible < item.cantidad) {
              productosNoDisponibles.add('${item.nombreProducto} (stock insuficiente)');
            }
          }
        }
        
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
          if (item.productoId <= 0) continue;
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

        // Registro de límite buffet QR (tipos distintos por ventana + inicio de espera entre envíos)
        if (token != null && token.trim().isNotEmpty) {
          final idsDistintos = pedido.items
              .map((i) => i.productoId)
              .where((id) => id > 0)
              .toSet()
              .toList();
          await _db.registrarEnvioPedidoQrBuffet(
            mesaNumero: mesaNumero,
            productoIdsDistintosEnPedido: idsDistintos,
          );
          await _db.limpiarCarritoQrMesa(mesaNumero);
        }

        // Actualizar estado de la mesa a ocupada
        await _db.actualizarEstadoMesa(pedido.mesaNumero, EstadoMesa.ocupada);

        // Imprimir en las impresoras configuradas por destino (mismo flujo que pedidos de camarero)
        ImprimirPedidoService.instance.imprimirPedido(pedido).catchError((e, st) {
          debugPrint('Error al imprimir pedido QR: $e');
        });

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

  static String _escapeHtmlAttr(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('"', '&quot;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  static String _escapeHtmlContent(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  /// CSS de respaldo cuando no existe la imagen de azulejos (patrón SVG)
  String _fallbackAzulejoCss() {
    const svg = '<svg xmlns="http://www.w3.org/2000/svg" width="80" height="80" viewBox="0 0 80 80">'
        '<rect width="80" height="80" fill="#FAF8F5" fill-opacity="0.12"/>'
        '<rect x="3" y="3" width="74" height="74" fill="none" stroke="#0047AB" stroke-width="1.2" stroke-opacity="0.1"/>'
        '<circle cx="40" cy="40" r="6" fill="#F4A460" fill-opacity="0.08"/>'
        '<path d="M40 30 L43 40 L40 50 L37 40 Z" fill="#0047AB" fill-opacity="0.08"/>'
        '<path d="M28 40 L40 37 L52 40 L40 44 Z" fill="#0047AB" fill-opacity="0.08"/>'
        '</svg>';
    final dataUrl = 'data:image/svg+xml,${Uri.encodeComponent(svg)}';
    return 'body { font-family: \'Poppins\', -apple-system, BlinkMacSystemFont, sans-serif; background-color: #FAFAF8; background-image: url("$dataUrl"); background-repeat: repeat; background-size: 80px 80px; color: #212121; min-height: 100vh; padding-bottom: 120px; }';
  }

  /// Genera la página HTML para clientes QR
  Future<String> _generarPaginaClienteQR(int mesa, String token, List<Producto> productos, bool esHorarioBuffet) async {
    final productosHtml = productos.map((p) {
      final descAttr = p.descripcion != null ? _escapeHtmlAttr(p.descripcion!) : '';
      final imgAttr = p.imagen != null && p.imagen!.isNotEmpty ? _escapeHtmlAttr(p.imagen!) : '';
      final alergenosAttr = _escapeHtmlAttr(jsonEncode(p.alergenos));
      final nombreJs = p.nombre.replaceAll("'", "\\'").replaceAll('\r', '').replaceAll('\n', ' ');
      return '''
      <div class="producto ${p.isAvailable ? '' : 'agotado'}" data-id="${p.id}" data-nombre="${_escapeHtmlAttr(p.nombre)}" data-precio="${p.precio}" data-descripcion="$descAttr" data-imagen="$imgAttr" data-alergenos="$alergenosAttr" role="button" tabindex="0" onclick="abrirModalPlato(this)" onkeydown="if(event.key==='Enter'||event.key===' ') { event.preventDefault(); abrirModalPlato(this); }">
        ${p.imagen != null && p.imagen!.isNotEmpty ? '<img class="producto-foto" src="$imgAttr" alt="">' : ''}
        <div class="producto-fila">
          <div class="producto-info">
            <span class="nombre">${p.nombre}</span>
            ${p.descripcion != null ? '<span class="descripcion">${_escapeHtmlContent(p.descripcion!)}</span>' : ''}
            <span class="precio">${p.isAvailable ? '${p.precio.toStringAsFixed(2)}€' : 'AGOTADO'}</span>
          </div>
          ${p.isAvailable ? '<button type="button" class="btn-agregar" onclick="event.stopPropagation(); agregarAlCarrito(${p.id}, \'$nombreJs\', ${p.precio}, ${p.destinoId ?? 'null'})">+</button>' : ''}
        </div>
      </div>
    ''';
    }).join('\n');

    // Fondo: imagen de azulejos (PNG) si existe; si no, patrón SVG de respaldo
    String backgroundCss;
    final exeDir = p.dirname(Platform.resolvedExecutable);
    final candidates = [
      p.join(exeDir, 'fondo_azulejos.png'),
      p.join(exeDir, 'web', 'fondo_azulejos.png'),
      p.join(Directory.current.path, 'web', 'fondo_azulejos.png'),
      p.join(Directory.current.path, 'build', 'web', 'fondo_azulejos.png'),
    ];
    File? imageFile;
    for (final path in candidates) {
      final f = File(path);
      if (f.existsSync()) {
        imageFile = f;
        break;
      }
    }
    if (imageFile != null) {
      try {
        final bytes = await imageFile.readAsBytes();
        final base64 = base64Encode(bytes);
        final dataUrl = 'data:image/png;base64,$base64';
        backgroundCss = '''
    body { position: relative; font-family: 'Poppins', -apple-system, BlinkMacSystemFont, sans-serif; background-color: #FAFAF8; color: #212121; min-height: 100vh; padding-bottom: 120px; }
    body::before {
      content: '';
      position: absolute;
      inset: 0;
      background-image: url("$dataUrl");
      background-repeat: repeat;
      background-size: 300px auto;
      opacity: 0.13;
      z-index: 0;
      pointer-events: none;
    }
    body > * { position: relative; z-index: 1; }
''';
      } catch (_) {
        backgroundCss = _fallbackAzulejoCss();
      }
    } else {
      backgroundCss = _fallbackAzulejoCss();
    }

    return '''
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>Pedir - Mesa $mesa</title>
  <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600;700&display=swap" rel="stylesheet">
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    $backgroundCss
    .header {
      background: #FFFFFF;
      padding: 16px 20px;
      position: sticky;
      top: 0;
      z-index: 100;
      box-shadow: 0 2px 12px rgba(0,0,0,0.06);
    }
    .header h1 {
      font-size: 18px;
      font-weight: 700;
      color: #212121;
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .header .mesa {
      background: #C41E3A;
      padding: 4px 12px;
      border-radius: 20px;
      font-size: 14px;
      color: white;
    }
    ${esHorarioBuffet ? '''
    .buffet-banner {
      background: #C41E3A;
      color: #FFFFFF;
      text-align: center;
      padding: 14px 20px;
      font-weight: 700;
      font-size: 14px;
      border-radius: 12px;
      margin: 12px 16px;
      box-shadow: 0 4px 16px rgba(196, 30, 58, 0.25);
    }
    ''' : ''}
    .leyenda-alergenos {
      margin: 16px;
      padding: 14px 18px;
      background: #FFFFFF;
      border-radius: 16px;
      box-shadow: 0 2px 12px rgba(0,0,0,0.06);
    }
    .leyenda-alergenos-titulo {
      font-size: 13px;
      color: #616161;
      margin-bottom: 10px;
      font-weight: 600;
      text-align: center;
    }
    .leyenda-alergenos-grid {
      display: flex;
      flex-wrap: wrap;
      gap: 8px 14px;
      justify-content: center;
      align-items: center;
    }
    .leyenda-alergenos-item {
      display: flex;
      align-items: center;
      gap: 6px;
      padding: 6px 10px;
      background: #FAFAFA;
      border-radius: 20px;
      color: #616161;
      font-size: 12px;
      font-weight: 500;
      border: 1px solid #EEEEEE;
    }
    .leyenda-alergenos-item .icono { font-size: 16px; }
    .leyenda-alergenos-item.vegano { color: #2E7D32; border-color: #E8F5E9; background: #E8F5E9; }
    .leyenda-alergenos-item.picante { color: #C62828; border-color: #FFEBEE; background: #FFEBEE; }
    .productos {
      padding: 16px;
      display: flex;
      flex-direction: column;
      gap: 12px;
    }
    .producto {
      background: #FFFFFF;
      border-radius: 16px;
      display: flex;
      flex-direction: column;
      align-items: stretch;
      border: none;
      cursor: pointer;
      box-shadow: 0 2px 12px rgba(0,0,0,0.06);
      transition: box-shadow 0.2s ease;
      overflow: hidden;
    }
    .producto:hover { box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
    .producto.agotado {
      opacity: 0.5;
      box-shadow: 0 1px 6px rgba(0,0,0,0.06);
    }
    .producto.agotado:hover { box-shadow: 0 1px 6px rgba(0,0,0,0.06); }
    .producto-foto {
      width: 100%;
      height: 120px;
      object-fit: cover;
      display: block;
      border-radius: 12px 12px 0 0;
      background: #eee;
    }
    .producto-fila {
      display: flex;
      align-items: center;
      padding: 12px 16px;
      min-height: 72px;
    }
    .producto-info {
      display: flex;
      flex-direction: column;
      gap: 4px;
      flex: 1;
      min-width: 0;
    }
    .nombre { font-family: 'Poppins', sans-serif; font-weight: 700; font-size: 16px; color: #212121; }
    .descripcion {
      font-size: 12px;
      color: #616161;
      display: -webkit-box;
      -webkit-line-clamp: 3;
      -webkit-box-orient: vertical;
      overflow: hidden;
      line-height: 1.35;
    }
    .precio { color: #2E7D32; font-weight: 700; font-size: 18px; }
    .producto.agotado .precio { color: #9E9E9E; font-weight: 600; }
    .producto.agotado .descripcion { color: #424242; }
    .btn-agregar {
      /* Rojo vino (botón +) */
      background: #8B1E2D;
      border: none;
      color: white;
      width: 44px;
      height: 44px;
      border-radius: 50%;
      font-size: 24px;
      font-weight: bold;
      cursor: pointer;
      flex-shrink: 0;
      margin-left: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      line-height: 1;
      box-shadow: 0 2px 10px rgba(139, 30, 45, 0.35);
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
      /* Terracota (botón carrito) */
      background: #C65D3A;
      border: none;
      color: white;
      box-shadow: 0 4px 20px rgba(198, 93, 58, 0.4);
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
      background: #C41E3A;
      color: white;
      font-size: 12px;
      font-weight: bold;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 0 5px;
      border: 2px solid #FFFFFF;
    }
    .btn-carrito-flotante .carrito-badge.oculto { display: none; }
    .btn-carrito-flotante.bump {
      animation: carrito-bump 0.4s ease;
    }
    @keyframes carrito-bump {
      0%   { transform: scale(1); }
      35%  { transform: scale(1.25); }
      70%  { transform: scale(1.1); }
      100% { transform: scale(1); }
    }
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
      background: #FFFFFF;
      box-shadow: -4px 0 24px rgba(0,0,0,0.12);
      z-index: 160;
      display: flex;
      flex-direction: column;
      transform: translateX(100%);
      transition: transform 0.3s ease-out;
    }
    .carrito-drawer.abierto { transform: translateX(0); }
    .carrito-drawer-header {
      padding: 20px;
      border-bottom: 1px solid #EEEEEE;
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-shrink: 0;
    }
    .carrito-drawer-header h2 { margin: 0; font-size: 20px; font-weight: 700; color: #212121; }
    .btn-cerrar-drawer {
      background: transparent;
      border: none;
      color: #757575;
      font-size: 24px;
      cursor: pointer;
      padding: 0 8px;
      line-height: 1;
    }
    .btn-cerrar-drawer:active { color: #212121; }
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
      background: #FAFAFA;
      border-radius: 12px;
      font-size: 15px;
      border: 1px solid #EEEEEE;
    }
    .carrito-drawer-item .nombre { color: #212121; flex: 1; min-width: 0; font-weight: 500; }
    .carrito-drawer-item .cantidad { color: #2E7D32; font-weight: 700; margin: 0 6px; min-width: 20px; text-align: center; }
    .carrito-drawer-item .controles {
      display: flex;
      align-items: center;
      gap: 4px;
      flex-shrink: 0;
    }
    .btn-carrito-ctrl {
      width: 28px;
      height: 28px;
      border-radius: 50%;
      border: none;
      color: #fff;
      font-size: 16px;
      line-height: 1;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 0;
      transition: opacity 0.15s, transform 0.1s;
    }
    .btn-carrito-ctrl:active { transform: scale(0.92); }
    .btn-carrito-mas { background: #E65100; color: #fff; }
    .btn-carrito-mas:hover { opacity: 0.9; }
    .btn-carrito-menos {
      background: #FFFFFF;
      color: #616161;
      border: 1px solid #E0E0E0;
    }
    .btn-carrito-menos:hover { opacity: 0.9; }
    .btn-carrito-quitar { background: #F5F5F5; color: #C62828; font-size: 14px; border: 1px solid #FFCDD2; }
    .btn-carrito-quitar:hover { opacity: 0.9; }
    .carrito-drawer-vacio {
      color: #757575;
      text-align: center;
      padding: 24px 16px;
      font-size: 15px;
    }
    .carrito-drawer-footer {
      padding: 16px 20px;
      border-top: 1px solid #EEEEEE;
      flex-shrink: 0;
    }
    .carrito-drawer-total {
      color: #2E7D32;
      font-size: 14px;
      font-weight: 600;
      margin-bottom: 12px;
      text-align: center;
    }
    .carrito-envio-cuenta-atras {
      text-align: center;
      padding: 10px 12px;
      margin: 0 12px 10px 12px;
      font-size: 14px;
      font-weight: 600;
      color: #5D4037;
      background: #FFF3E0;
      border-radius: 10px;
      border: 1px solid #FFCC80;
    }
    .carrito-envio-cuenta-atras.oculto { display: none; }
    .btn-enviar {
      background: #C41E3A;
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
      box-shadow: 0 2px 10px rgba(196, 30, 58, 0.3);
    }
    .btn-enviar:disabled { background: #BDBDBD; cursor: not-allowed; box-shadow: none; }
    .btn-enviar:active:not(:disabled) { transform: scale(0.98); }
    .mensaje {
      position: fixed;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      background: #FFFFFF;
      padding: 32px;
      border-radius: 20px;
      text-align: center;
      z-index: 200;
      display: none;
      box-shadow: 0 8px 32px rgba(0,0,0,0.12);
      max-width: 300px;
    }
    .mensaje.visible { display: block; }
    .mensaje h2 { color: #2E7D32; margin-bottom: 16px; font-weight: 700; }
    .mensaje p { margin-bottom: 20px; color: #616161; }
    .btn-aceptar-mensaje {
      background: #C41E3A;
      color: #FFFFFF;
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
    
    /* Modal detalle plato */
    .modal-plato-overlay {
      position: fixed;
      inset: 0;
      background: rgba(0,0,0,0.75);
      z-index: 250;
      display: none;
      align-items: center;
      justify-content: center;
      padding: 16px;
      animation: fadeIn 0.25s ease-out;
    }
    .modal-plato-overlay.visible {
      display: flex;
    }
    .modal-plato {
      background: #FFFFFF;
      border-radius: 20px;
      border: none;
      max-width: 400px;
      width: 100%;
      max-height: 90vh;
      overflow: hidden;
      display: flex;
      flex-direction: column;
      box-shadow: 0 12px 40px rgba(0,0,0,0.15);
    }
    .modal-plato-header {
      padding: 16px 20px;
      border-bottom: 1px solid #EEEEEE;
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      flex-shrink: 0;
    }
    .modal-plato-header h2 {
      margin: 0;
      font-size: 22px;
      font-weight: 700;
      color: #212121;
      line-height: 1.3;
      flex: 1;
      padding-right: 12px;
    }
    .modal-plato-cerrar {
      background: transparent;
      border: none;
      color: #757575;
      font-size: 28px;
      line-height: 1;
      cursor: pointer;
      padding: 0 4px;
      flex-shrink: 0;
    }
    .modal-plato-cerrar:hover, .modal-plato-cerrar:active { color: #212121; }
    .modal-plato-body {
      padding: 16px 20px;
      overflow-y: auto;
      -webkit-overflow-scrolling: touch;
    }
    .modal-plato-imagen {
      width: 100%;
      max-height: 220px;
      object-fit: cover;
      border-radius: 12px;
      margin-bottom: 16px;
      background: #F5F5F5;
    }
    .modal-plato-alergenos {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      margin-bottom: 16px;
      align-items: center;
    }
    .modal-plato-alergeno {
      padding: 6px 10px;
      border-radius: 20px;
      background: #FAFAFA;
      border: 1px solid #EEEEEE;
      display: inline-flex;
      align-items: center;
      gap: 6px;
      font-size: 12px;
      font-weight: 500;
      color: #616161;
      cursor: default;
    }
    .modal-plato-alergeno.vegano { color: #2E7D32; border-color: #E8F5E9; background: #E8F5E9; }
    .modal-plato-alergeno.picante { color: #C62828; border-color: #FFEBEE; background: #FFEBEE; }
    .modal-plato-alergeno[title] { cursor: help; }
    .modal-plato-alergeno .alergeno-icon { font-size: 14px; }
    .modal-plato-alergeno .alergeno-nombre { font-size: 12px; }
    .modal-plato-desc {
      font-size: 15px;
      color: #616161;
      line-height: 1.5;
      white-space: pre-wrap;
    }
    
    /* Estilos para productos marcados como agotados durante el envío */
    .producto.marcado-error {
      border: 2px solid #FFCDD2 !important;
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
      background: #FFFFFF;
      padding: 28px;
      border-radius: 20px;
      text-align: center;
      max-width: 350px;
      margin: 16px;
      box-shadow: 0 12px 40px rgba(0,0,0,0.15);
    }
    .dialog-icon {
      font-size: 48px;
      margin-bottom: 16px;
    }
    .dialog-error h2 {
      color: #C41E3A;
      margin-bottom: 12px;
      font-size: 22px;
      font-weight: 700;
    }
    .dialog-error p {
      color: #616161;
      font-size: 14px;
      margin-bottom: 16px;
    }
    .lista-agotados {
      list-style: none;
      padding: 12px;
      background: #FFEBEE;
      border-radius: 10px;
      margin-bottom: 16px;
      text-align: left;
      max-height: 150px;
      overflow-y: auto;
    }
    .lista-agotados li {
      color: #C62828;
      padding: 8px 0;
      border-bottom: 1px solid #FFCDD2;
      font-weight: 500;
    }
    .lista-agotados li:last-child {
      border-bottom: none;
    }
    .lista-ajustes {
      list-style: none;
      padding: 12px;
      background: #FFF8E1;
      border-radius: 10px;
      margin-bottom: 16px;
      text-align: left;
      max-height: 150px;
      overflow-y: auto;
    }
    .lista-ajustes li {
      color: #E65100;
      padding: 8px 0;
      border-bottom: 1px solid #FFECB3;
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
      color: #757575;
      font-size: 12px;
      font-style: italic;
    }
    .btn-dialog {
      background: #C41E3A;
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
      opacity: 0.9;
    }
    /* Mis Pedidos realizados */
    .mis-pedidos-section {
      padding: 16px;
      background: #FFFFFF;
      margin: 0 16px 16px;
      border-radius: 16px;
      box-shadow: 0 2px 12px rgba(0,0,0,0.06);
    }
    .mis-pedidos-section h2 {
      color: #212121;
      font-size: 16px;
      font-weight: 700;
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
      color: #757575;
      font-size: 14px;
      padding: 12px 0;
      text-align: center;
    }
    .item-pedido-realizado {
      background: #FAFAFA;
      padding: 12px 14px;
      border-radius: 12px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 8px;
      border: 1px solid #EEEEEE;
      border-left: 4px solid #2E7D32;
    }
    .item-pedido-realizado .nombre-cantidad {
      color: #212121;
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
      background: #FFF3E0;
      color: #E65100;
    }
    .item-pedido-realizado .estado-servido {
      background: #E8F5E9;
      color: #2E7D32;
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
  
  <div class="leyenda-alergenos">
    <div class="leyenda-alergenos-titulo">📋 Guía de alérgenos y características</div>
    <div class="leyenda-alergenos-grid">
      <div class="leyenda-alergenos-item"><span class="icono">🌾</span><span>Gluten</span></div>
      <div class="leyenda-alergenos-item"><span class="icono">🥛</span><span>Lácteos</span></div>
      <div class="leyenda-alergenos-item"><span class="icono">🥜</span><span>Frutos secos</span></div>
      <div class="leyenda-alergenos-item"><span class="icono">🥚</span><span>Huevo</span></div>
      <div class="leyenda-alergenos-item picante"><span class="icono">🌶</span><span>Picante</span></div>
      <div class="leyenda-alergenos-item vegano"><span class="icono">🌱</span><span>Vegano</span></div>
    </div>
  </div>
  
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
    <div class="carrito-envio-cuenta-atras oculto" id="carrito-envio-cuenta-atras" aria-live="polite"></div>
    <div class="carrito-drawer-footer">
      <div class="carrito-drawer-total" id="carrito-drawer-total">0 productos</div>
      <button class="btn-enviar" id="btn-enviar" disabled onclick="enviarPedido()">Enviar Pedido</button>
    </div>
  </div>
  
  <div class="overlay" id="overlay"></div>
  <div class="mensaje" id="mensaje">
    <h2>✅ ¡Pedido Enviado!</h2>
    <p>Tu pedido llegará pronto a tu mesa.</p>
    <button class="btn-aceptar-mensaje" onclick="cerrarMensajeYRecargar()">Aceptar</button>
  </div>
  
  <div class="modal-plato-overlay" id="modal-plato-overlay" onclick="if(event.target===this) cerrarModalPlato()">
    <div class="modal-plato" id="modal-plato" onclick="event.stopPropagation()">
      <div class="modal-plato-header">
        <h2 id="modal-plato-nombre"></h2>
        <button type="button" class="modal-plato-cerrar" onclick="cerrarModalPlato()" aria-label="Cerrar">×</button>
      </div>
      <div class="modal-plato-body">
        <img class="modal-plato-imagen" id="modal-plato-imagen" alt="" style="display: none;">
        <div class="modal-plato-alergenos" id="modal-plato-alergenos"></div>
        <p class="modal-plato-desc" id="modal-plato-desc"></p>
      </div>
    </div>
  </div>
  
  <script>
    const mesa = $mesa;
    const token = ${jsonEncode(token)};
    const esBuffet = $esHorarioBuffet;
    let carrito = [];
    let _pollCarrito = null;
    let _tickEnvio = null;
    let segundosHastaPoderEnviar = 0;

    function actualizarCuentaAtrasEnvio() {
      const el = document.getElementById('carrito-envio-cuenta-atras');
      if (!el) return;
      if (segundosHastaPoderEnviar <= 0) {
        el.classList.add('oculto');
        el.textContent = '';
        return;
      }
      el.classList.remove('oculto');
      const m = Math.floor(segundosHastaPoderEnviar / 60);
      const s = segundosHastaPoderEnviar % 60;
      const ss = s < 10 ? '0' + s : String(s);
      el.textContent = 'Podrás enviar en ' + (m > 0 ? m + ':' + ss : ss + ' s');
    }

    async function cargarCarritoServidor() {
      try {
        const res = await fetch('/api/qr/carrito/' + encodeURIComponent(token));
        if (!res.ok) return;
        const data = await res.json();
        carrito = (data.items || []).map(function(it) {
          return {
            productoId: it.productoId,
            nombreProducto: it.nombreProducto,
            precioUnitario: it.precioUnitario,
            cantidad: it.cantidad,
            destinoId: it.destinoId
          };
        });
        segundosHastaPoderEnviar = parseInt(data.segundosHastaPoderEnviar, 10) || 0;
        if (segundosHastaPoderEnviar < 0) segundosHastaPoderEnviar = 0;
        actualizarCuentaAtrasEnvio();
        actualizarUI();
      } catch (e) {
        console.error('Error cargando carrito servidor:', e);
      }
    }
    
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
    
    async function _postCarrito(url, payload) {
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload || {})
      });
      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        if (res.status === 403 && data && data.error === 'limite_tipos_distintos') {
          alert('Has alcanzado el límite de tipos distintos permitido para esta mesa. Si estás en modo buffet, revisa el número de menús (adulto/niño) de la mesa.');
        } else if (data && data.mensaje) {
          alert(data.mensaje);
        }
      }
      return res;
    }

    async function agregarAlCarrito(id, nombre, precio, destinoId) {
      try {
        await _postCarrito(
          '/api/qr/carrito/' + encodeURIComponent(token) + '/add',
          { productoId: id, delta: 1 }
        );
        await cargarCarritoServidor();
      } catch (e) {
        console.error('Error agregando al carrito:', e);
      }
      var btn = document.getElementById('btn-carrito-flotante');
      if (btn) {
        btn.classList.remove('bump');
        void btn.offsetWidth;
        btn.classList.add('bump');
        btn.addEventListener('animationend', function once() {
          btn.classList.remove('bump');
          btn.removeEventListener('animationend', once);
        });
      }
    }
    
    function actualizarUI() {
      const totalItems = carrito.reduce((sum, item) => sum + item.cantidad, 0);
      const badge = document.getElementById('carrito-badge');
      if (badge) {
        badge.textContent = totalItems > 99 ? '99+' : totalItems;
        badge.classList.toggle('oculto', totalItems === 0);
      }
      const btnEnviar = document.getElementById('btn-enviar');
      if (btnEnviar) {
        btnEnviar.disabled = totalItems === 0 || segundosHastaPoderEnviar > 0;
      }
      actualizarCuentaAtrasEnvio();
      renderCarritoEnDrawer();
    }
    
    function actualizarTotalDrawer() {
      const totalEl = document.getElementById('carrito-drawer-total');
      if (!totalEl) return;
      const n = carrito.reduce(function(s, item) { return s + item.cantidad; }, 0);
      totalEl.textContent = n === 0 ? '0 productos' : (n === 1 ? '1 producto' : n + ' productos');
    }
    
    async function incrementarCantidad(productoId) {
      try {
        await _postCarrito(
          '/api/qr/carrito/' + encodeURIComponent(token) + '/add',
          { productoId: productoId, delta: 1 }
        );
        await cargarCarritoServidor();
      } catch (e) {
        console.error('Error incrementando cantidad:', e);
      }
    }
    
    async function decrementarCantidad(productoId) {
      const item = carrito.find(function(i) { return i.productoId === productoId; });
      if (!item) return;
      const nueva = (item.cantidad || 1) - 1;
      if (nueva <= 0) return;
      try {
        await _postCarrito(
          '/api/qr/carrito/' + encodeURIComponent(token) + '/set',
          { productoId: productoId, cantidad: nueva }
        );
        await cargarCarritoServidor();
      } catch (e) {
        console.error('Error decrementando cantidad:', e);
      }
    }
    
    async function quitarDelCarrito(productoId) {
      try {
        await fetch('/api/qr/carrito/' + encodeURIComponent(token) + '/remove', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ productoId: productoId })
        });
        await cargarCarritoServidor();
      } catch (e) {
        console.error('Error quitando del carrito:', e);
      }
    }
    
    function renderCarritoEnDrawer() {
      const lista = document.getElementById('carrito-drawer-lista');
      if (!lista) return;
      actualizarTotalDrawer();
      if (carrito.length === 0) {
        lista.innerHTML = '<div class="carrito-drawer-vacio">Añade productos desde la carta y pulsa Enviar pedido cuando termines.</div>';
        return;
      }
      lista.innerHTML = carrito.map(function(item) {
        const nombre = (item.nombreProducto || 'Producto').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
        const linea = item.cantidad > 1 ? nombre + ' x' + item.cantidad : nombre;
        const id = item.productoId;
        return '<div class="carrito-drawer-item"><span class="nombre">' + linea + '</span><span class="cantidad">' + item.cantidad + '</span><div class="controles"><button type="button" class="btn-carrito-ctrl btn-carrito-mas" onclick="incrementarCantidad(' + id + ')" aria-label="Añadir">+</button><button type="button" class="btn-carrito-ctrl btn-carrito-menos" onclick="decrementarCantidad(' + id + ')" aria-label="Quitar uno">−</button><button type="button" class="btn-carrito-ctrl btn-carrito-quitar" onclick="quitarDelCarrito(' + id + ')" aria-label="Eliminar">×</button></div></div>';
      }).join('');
    }
    
    function toggleCarritoDrawer() {
      const drawer = document.getElementById('carrito-drawer');
      const overlay = document.getElementById('carrito-drawer-overlay');
      if (drawer.classList.contains('abierto')) {
        cerrarCarritoDrawer();
      } else {
        cargarCarritoServidor();
        renderCarritoEnDrawer();
        drawer.classList.add('abierto');
        overlay.classList.add('visible');
      }
    }
    
    function cerrarCarritoDrawer() {
      document.getElementById('carrito-drawer').classList.remove('abierto');
      document.getElementById('carrito-drawer-overlay').classList.remove('visible');
    }
    
    var ALERGENOS_MAP = {
      gluten:     { label: 'Gluten',           icon: '🌾', clase: '' },
      lacteos:    { label: 'Lácteos',          icon: '🥛', clase: '' },
      frutos_secos: { label: 'Frutos secos',   icon: '🥜', clase: '' },
      huevo:      { label: 'Huevo',             icon: '🥚', clase: '' },
      picante:    { label: 'Picante',           icon: '🌶', clase: 'picante' },
      vegano:     { label: 'Vegano',            icon: '🌱', clase: 'vegano' }
    };
    
    function abrirModalPlato(card) {
      var nombre = card.getAttribute('data-nombre') || '';
      var descripcion = card.getAttribute('data-descripcion') || '';
      var imagen = card.getAttribute('data-imagen') || '';
      var alergenosStr = card.getAttribute('data-alergenos') || '[]';
      var alergenos = [];
      try { alergenos = JSON.parse(alergenosStr); } catch (e) {}
      document.getElementById('modal-plato-nombre').textContent = nombre;
      document.getElementById('modal-plato-desc').textContent = descripcion || 'Sin descripción.';
      var imgEl = document.getElementById('modal-plato-imagen');
      if (imagen) {
        imgEl.src = imagen;
        imgEl.style.display = '';
        imgEl.onerror = function() { imgEl.style.display = 'none'; };
      } else {
        imgEl.style.display = 'none';
      }
      var contAlergenos = document.getElementById('modal-plato-alergenos');
      contAlergenos.innerHTML = '';
      alergenos.forEach(function(key) {
        var info = ALERGENOS_MAP[key];
        if (!info) return;
        var span = document.createElement('span');
        span.className = 'modal-plato-alergeno' + (info.clase ? ' ' + info.clase : '');
        span.title = info.label;
        span.setAttribute('aria-label', info.label);
        span.innerHTML = '<span class="alergeno-icon">' + info.icon + '</span><span class="alergeno-nombre">' + info.label + '</span>';
        contAlergenos.appendChild(span);
      });
      document.getElementById('modal-plato-overlay').classList.add('visible');
      document.body.style.overflow = 'hidden';
      document.addEventListener('keydown', _cerrarModalPlatoEscape);
    }
    
    function _cerrarModalPlatoEscape(e) {
      if (e.key === 'Escape') {
        cerrarModalPlato();
      }
    }
    
    function cerrarModalPlato() {
      document.getElementById('modal-plato-overlay').classList.remove('visible');
      document.body.style.overflow = '';
      document.removeEventListener('keydown', _cerrarModalPlatoEscape);
    }
    
    async function enviarPedido() {
      await cargarCarritoServidor();
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
          
          var totVal = carrito.reduce(function(s, x) { return s + x.cantidad; }, 0);
          btn.disabled = totVal === 0 || segundosHastaPoderEnviar > 0;
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
            token: token,
            mesaNumero: mesa,
            esBuffet: esBuffet
          })
        });
        
        if (response.ok) {
          cerrarCarritoDrawer();
          // El servidor limpia el carrito al enviar; refrescar para sincronizar
          await cargarCarritoServidor();
          refrescarMisPedidos();
          document.getElementById('overlay').classList.add('visible');
          document.getElementById('mensaje').classList.add('visible');
        } else {
          const errorData = await response.json().catch(() => ({}));
          if (response.status === 429 && errorData.segundosRestantes != null) {
            segundosHastaPoderEnviar = parseInt(errorData.segundosRestantes, 10) || 0;
            await cargarCarritoServidor();
            return;
          }
          if (errorData.productos_agotados) {
            mostrarDialogoAgotados(errorData.productos_agotados);
          } else {
            alert(errorData.mensaje || 'Error al enviar el pedido. Inténtalo de nuevo.');
          }
        }
      } catch (e) {
        console.error('Error:', e);
        alert('Error de conexión. Verifica tu conexión WiFi.');
      } finally {
        var tot = carrito.reduce(function(s, x) { return s + x.cantidad; }, 0);
        btn.disabled = tot === 0 || segundosHastaPoderEnviar > 0;
        btn.textContent = 'Enviar Pedido';
      }
    }

    // Inicial: cargar carrito comunitario y refrescar periódicamente para ver cambios de otros móviles
    (function iniciarCarritoComunitario() {
      cargarCarritoServidor();
      if (_pollCarrito) clearInterval(_pollCarrito);
      _pollCarrito = setInterval(cargarCarritoServidor, 4000);
      if (_tickEnvio) clearInterval(_tickEnvio);
      _tickEnvio = setInterval(function() {
        if (segundosHastaPoderEnviar > 0) {
          segundosHastaPoderEnviar--;
          actualizarCuentaAtrasEnvio();
          var btnE = document.getElementById('btn-enviar');
          if (btnE) {
            var tot = carrito.reduce(function(s, x) { return s + x.cantidad; }, 0);
            btnE.disabled = tot === 0 || segundosHastaPoderEnviar > 0;
          }
        }
      }, 1000);
    })();
    
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

  /// Indica si la ruta es de la app web (SPA) y debe protegerse / servir index.html
  bool _isAppPath(String path) {
    if (path.startsWith('/api') || path.startsWith('/qr') || path == '/health' || path == '/login') return false;
    return true;
  }

  /// Extrae el ID de sesión de la cookie de la petición
  String? _getSessionFromRequest(Request request) {
    final cookie = request.headers['cookie'];
    if (cookie == null || cookie.isEmpty) return null;
    for (final part in cookie.split(';')) {
      final t = part.trim().split('=');
      if (t.length == 2 && t[0].trim() == _cookieSessionName) {
        return t[1].trim();
      }
    }
    return null;
  }

  /// Comprueba si la sesión es válida y no ha expirado
  bool _isValidSession(String? sessionId) {
    if (sessionId == null || sessionId.isEmpty) return false;
    final expiry = _sessions[sessionId];
    if (expiry == null) return false;
    if (expiry.isBefore(DateTime.now())) {
      _sessions.remove(sessionId);
      return false;
    }
    return true;
  }

  /// Genera un ID de sesión aleatorio
  String _generateSessionId() {
    final r = Random.secure();
    final bytes = List<int>.generate(32, (_) => r.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  /// Obtiene la contraseña de acceso a la app web (cocina). Por defecto "cocina" si no existe fichero.
  Future<String> _getCocinaPassword() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File(p.join(dir.path, 'programa_caja', 'cocina_password.txt'));
      if (await file.exists()) {
        final content = await file.readAsString();
        return content.trim();
      }
      await file.parent.create(recursive: true);
      await file.writeAsString('cocina');
      debugPrint('Contraseña de cocina por defecto creada en: ${file.path} (cambia el fichero para usar otra).');
      return 'cocina';
    } catch (e) {
      debugPrint('Error leyendo contraseña de cocina: $e');
      return 'cocina';
    }
  }

  /// Genera la página HTML de login para la app web
  String _loginPageHtml(String redirect, {String? error}) {
    final redirectAttr = _escapeHtmlAttr(redirect);
    final errorHtml = error != null
        ? '<p class="login-error">${_escapeHtmlContent(error)}</p>'
        : '';
    return '''
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Acceso - Cocina</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: linear-gradient(135deg, #1A1A2E 0%, #16213E 100%);
      color: white;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }
    .login-box {
      background: #16213E;
      border: 2px solid #0F3460;
      border-radius: 16px;
      padding: 32px;
      max-width: 360px;
      width: 100%;
      box-shadow: 0 8px 32px rgba(0,0,0,0.3);
    }
    .login-box h1 {
      color: #FFD700;
      margin-bottom: 8px;
      font-size: 22px;
    }
    .login-box p.sub {
      color: #888;
      margin-bottom: 24px;
      font-size: 14px;
    }
    .login-error {
      color: #E94560;
      margin-bottom: 16px;
      font-size: 14px;
    }
    .login-box label {
      display: block;
      margin-bottom: 8px;
      color: #ccc;
      font-size: 14px;
    }
    .login-box input[type="password"] {
      width: 100%;
      padding: 12px 16px;
      border: 2px solid #0F3460;
      border-radius: 12px;
      background: #0F3460;
      color: white;
      font-size: 16px;
      margin-bottom: 20px;
    }
    .login-box input:focus {
      outline: none;
      border-color: #E94560;
    }
    .login-box button {
      width: 100%;
      padding: 14px;
      background: linear-gradient(135deg, #E94560, #FF6B6B);
      border: none;
      border-radius: 12px;
      color: white;
      font-size: 16px;
      font-weight: bold;
      cursor: pointer;
    }
    .login-box button:active { opacity: 0.9; }
  </style>
</head>
<body>
  <div class="login-box">
    <h1>Acceso al panel</h1>
    <p class="sub">Introduce la contraseña para continuar</p>
    $errorHtml
    <form method="post" action="/login">
      <input type="hidden" name="redirect" value="$redirectAttr">
      <label for="password">Contraseña</label>
      <input type="password" id="password" name="password" required autofocus placeholder="Contraseña">
      <button type="submit">Entrar</button>
    </form>
  </div>
</body>
</html>''';
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
