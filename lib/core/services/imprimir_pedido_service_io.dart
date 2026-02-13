import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../database/database_service.dart';
import '../models/models.dart';
import 'ticket_numero_service.dart';

/// Imprime pedidos en impresoras térmicas por red (IP:puerto).
class ImprimirPedidoService {
  static final ImprimirPedidoService _instance = ImprimirPedidoService._();
  static ImprimirPedidoService get instance => _instance;

  ImprimirPedidoService._();

  static const int _puertoPorDefecto = 9100;
  static const Duration _timeout = Duration(seconds: 5);

  // ESC/POS: Inicializar, corte total
  static final List<int> _escInit = [0x1B, 0x40];
  static final List<int> _escCut = [0x1D, 0x56, 0x00];

  /// Agrupa ítems por nombre de producto y suma cantidades.
  Map<String, int> _agruparCantidades(List<ItemPedido> items) {
    final map = <String, int>{};
    for (final item in items) {
      final nombre = item.nombreProducto.trim();
      map[nombre] = (map[nombre] ?? 0) + item.cantidad;
    }
    return map;
  }

  /// Genera el texto del ticket: mesa, número de ticket, ítems apilados.
  String _generarContenidoTicket(int mesaNumero, int numeroTicket, List<ItemPedido> items) {
    final lineas = <String>[];
    lineas.add('==============================');
    lineas.add('      MESA $mesaNumero');
    lineas.add('   Ticket #$numeroTicket');
    lineas.add('==============================');
    lineas.add('');
    final agrupado = _agruparCantidades(items);
    for (final e in agrupado.entries) {
      lineas.add('${e.value}x ${e.key}');
    }
    lineas.add('');
    lineas.add('==============================');
    lineas.add('');
    return lineas.join('\n');
  }

  /// Envía el ticket por TCP a la impresora en IP:puerto.
  Future<bool> _enviarAImpresora(String host, int port, String contenido) async {
    Socket? socket;
    try {
      socket = await Socket.connect(host, port, timeout: _timeout);
      final bytes = utf8.encode(contenido);
      socket.add(_escInit);
      socket.add(bytes);
      socket.add(_escCut);
      await socket.flush();
      await socket.close();
      return true;
    } catch (e) {
      debugPrint('Error enviando a $host:$port: $e');
      await socket?.close();
      return false;
    }
  }

  /// Imprime el pedido: un ticket por cada destino con impresora configurada (IP).
  Future<void> imprimirPedido(Pedido pedido) async {
    if (pedido.items.isEmpty) return;
    final db = DatabaseService.instance;
    final destinos = await db.obtenerDestinosActivos();
    final numeroTicket = await TicketNumeroService.instance.obtenerSiguienteNumero();

    final itemsPorDestino = <int?, List<ItemPedido>>{};
    for (final item in pedido.items) {
      itemsPorDestino.putIfAbsent(item.destinoId, () => []).add(item);
    }

    for (final entry in itemsPorDestino.entries) {
      final destinoId = entry.key;
      final items = entry.value;
      if (destinoId == null || items.isEmpty) continue;
      final destino = await db.obtenerDestinoPorId(destinoId);
      if (destino == null) continue;
      final tipo = destino.tipo;
      if (tipo != TipoDestino.impresora && tipo != TipoDestino.ambos) continue;
      final ip = destino.direccionImpresora?.trim();
      if (ip == null || ip.isEmpty) continue;
      final port = destino.puertoImpresora ?? _puertoPorDefecto;
      final contenido = _generarContenidoTicket(
        pedido.mesaNumero,
        numeroTicket,
        items,
      );
      final ok = await _enviarAImpresora(ip, port, contenido);
      if (!ok && destino.nombre != null) {
        debugPrint('No se pudo imprimir en ${destino.nombre} ($ip:$port)');
      }
    }
  }
}
