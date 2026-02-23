import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// Cliente para comunicarse con el servidor local del restaurante
/// 
/// Proporciona métodos para todas las operaciones CRUD necesarias
class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient(this.baseUrl, {http.Client? client}) 
      : _client = client ?? http.Client();

  /// Cierra el cliente HTTP
  void dispose() {
    _client.close();
  }

  // ==================== PRODUCTOS ====================

  /// Obtiene todos los productos del servidor
  Future<List<Producto>> obtenerProductos() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/productos'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Producto.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener productos: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error en obtenerProductos: $e');
      rethrow;
    }
  }

  /// Obtiene los productos del buffet
  Future<List<Producto>> obtenerProductosBuffet() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/productos/buffet'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Producto.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener productos buffet: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error en obtenerProductosBuffet: $e');
      rethrow;
    }
  }

  /// Guarda un producto
  Future<int> guardarProducto(Producto producto) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/productos'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(producto.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['id'] as int? ?? 0;
      } else {
        throw Exception('Error al guardar producto: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error en guardarProducto: $e');
      rethrow;
    }
  }

  /// Elimina un producto
  Future<bool> eliminarProducto(int id) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/api/productos/$id'),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error en eliminarProducto: $e');
      return false;
    }
  }

  // ==================== MESAS ====================

  /// Obtiene todas las mesas
  Future<List<Mesa>> obtenerMesas() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/mesas'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Mesa.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener mesas: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error en obtenerMesas: $e');
      rethrow;
    }
  }

  /// Obtiene una mesa por número
  Future<Mesa?> obtenerMesaPorNumero(int numero) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/mesas/$numero'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        return Mesa.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('Error en obtenerMesaPorNumero: $e');
      return null;
    }
  }

  /// Actualiza el estado de una mesa
  Future<void> actualizarEstadoMesa(int numero, EstadoMesa estado) async {
    try {
      await _client.put(
        Uri.parse('$baseUrl/api/mesas/$numero/estado'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'estado': estado.name}),
      );
    } catch (e) {
      debugPrint('Error en actualizarEstadoMesa: $e');
      rethrow;
    }
  }

  /// Libera una mesa: cierra la cuenta (marca pedidos como pagados) y deja la mesa libre
  Future<void> liberarMesa(int numeroMesa, {bool isBuffetClose = false}) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/mesas/liberar'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'numero': numeroMesa, 'isBuffetClose': isBuffetClose}),
      );
      if (response.statusCode != 200) {
        throw Exception('Error al liberar mesa: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error en liberarMesa: $e');
      rethrow;
    }
  }

  /// Cuenta por mesa: pedidos no pagados de la mesa
  Future<List<Pedido>> obtenerCuentaMesa(int numeroMesa) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/mesas/$numeroMesa/cuenta'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Pedido.fromJson(item)).toList();
      }
      throw Exception('Error al obtener cuenta: ${response.statusCode}');
    } catch (e) {
      debugPrint('Error en obtenerCuentaMesa: $e');
      rethrow;
    }
  }

  /// Mesas que tienen al menos un pedido no pagado (cuenta abierta)
  Future<List<int>> obtenerMesasConCuentaAbierta() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/mesas/cuentas-abiertas'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<int>();
      }
      return [];
    } catch (e) {
      debugPrint('Error en obtenerMesasConCuentaAbierta: $e');
      return [];
    }
  }

  /// Obtiene la configuración de buffet activa del servidor (precio cubierto, horarios, etc.)
  Future<ConfiguracionBuffet?> obtenerConfiguracionBuffetActiva() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/configuracion-buffet'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return ConfiguracionBuffet.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error en obtenerConfiguracionBuffetActiva: $e');
      return null;
    }
  }

  // ==================== PEDIDOS ====================

  /// Obtiene todos los pedidos activos
  Future<List<Pedido>> obtenerPedidosActivos() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/pedidos/activos'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Pedido.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener pedidos: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error en obtenerPedidosActivos: $e');
      rethrow;
    }
  }

  /// Obtiene pedidos de una mesa específica
  Future<List<Pedido>> obtenerPedidosDeMesa(int mesaNumero) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/pedidos/mesa/$mesaNumero'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Pedido.fromJson(item)).toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error en obtenerPedidosDeMesa: $e');
      return [];
    }
  }

  /// Obtiene pedidos para la cocina (pendientes + preparando)
  Future<List<Pedido>> obtenerPedidosCocina() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/pedidos/cocina'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Pedido.fromJson(item)).toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error en obtenerPedidosCocina: $e');
      rethrow;
    }
  }

  /// Guarda un nuevo pedido
  Future<int> guardarPedido(Pedido pedido) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/pedidos'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(pedido.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['id'] as int? ?? 0;
      } else {
        throw Exception('Error al guardar pedido: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error en guardarPedido: $e');
      rethrow;
    }
  }

  /// Actualiza el estado de un pedido
  Future<void> actualizarEstadoPedido(int pedidoId, EstadoPedido estado) async {
    try {
      await _client.put(
        Uri.parse('$baseUrl/api/pedidos/$pedidoId/estado'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'estado': estado.name}),
      );
    } catch (e) {
      debugPrint('Error en actualizarEstadoPedido: $e');
      rethrow;
    }
  }

  /// Actualiza el estado de un ítem de un pedido
  Future<void> actualizarEstadoItem(
    int pedidoId,
    int itemIndex,
    EstadoPedido estado,
  ) async {
    try {
      await _client.put(
        Uri.parse('$baseUrl/api/pedidos/$pedidoId/item/$itemIndex/estado'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'estado': estado.name}),
      );
    } catch (e) {
      debugPrint('Error en actualizarEstadoItem: $e');
      rethrow;
    }
  }

  /// Verifica la conexión con el servidor
  Future<bool> verificarConexion() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/health'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error verificando conexión: $e');
      return false;
    }
  }
}
