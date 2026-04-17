import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../database/database_service.dart';
import '../models/models.dart';
import 'configuracion_impresion_service.dart';
import 'ticket_numero_service.dart';

/// Imprime pedidos en impresoras térmicas por red (IP:puerto).
/// Usa [ConfiguracionImpresion] para márgenes, tipografía y contenido.
class ImprimirPedidoService {
  static final ImprimirPedidoService _instance = ImprimirPedidoService._();
  static ImprimirPedidoService get instance => _instance;

  ImprimirPedidoService._();

  static const int _puertoPorDefecto = 9100;
  static const Duration _timeout = Duration(seconds: 5);

  // ESC/POS
  static const List<int> _escInit = [0x1B, 0x40];
  static const List<int> _escBoldOn = [0x1B, 0x45, 0x01];
  static const List<int> _escBoldOff = [0x1B, 0x45, 0x00];
  static const List<int> _escCondensedOn = [0x1B, 0x0F];
  static const List<int> _escCondensedOff = [0x1B, 0x12];
  static const List<int> _escSizeNormal = [0x1B, 0x21, 0x00];
  static const List<int> _escSizeDoubleHeight = [0x1B, 0x21, 0x10];
  static const List<int> _escSizeDoubleWidth = [0x1B, 0x21, 0x20];
  static const List<int> _escSizeDoubleBoth = [0x1B, 0x21, 0x30];
  static const List<int> _escCutFull = [0x1D, 0x56, 0x00];
  static const List<int> _escCutPartial = [0x1D, 0x56, 0x01];

  /// GS ! n - Tamaño por escala numérica (1-8 ancho, 1-8 alto). No todas las impresoras lo soportan.
  static List<int> _gsSize(int widthScale, int heightScale) {
    final w = (widthScale.clamp(1, 8) - 1) & 7;
    final h = (heightScale.clamp(1, 8) - 1) & 7;
    return [0x1D, 0x21, (w << 4) | h];
  }

  /// Agrupa ítems por nombre y suma cantidades (dentro de un mismo turno).
  Map<String, int> _agruparCantidades(List<ItemPedido> items) {
    final map = <String, int>{};
    for (final item in items) {
      final nombre = item.nombreProducto.trim();
      map[nombre] = (map[nombre] ?? 0) + item.cantidad;
    }
    return map;
  }

  /// Agrupa ítems por producto (manteniendo precio unitario) y suma cantidades.
  /// La clave se basa en productoId + precioUnitario para evitar mezclar precios distintos.
  Map<String, ({int productoId, String nombre, int cantidad, double precioUnitario})>
      _agruparCantidadesConPrecio(List<ItemPedido> items) {
    final map =
        <String, ({int productoId, String nombre, int cantidad, double precioUnitario})>{};
    for (final item in items) {
      final nombre = item.nombreProducto.trim();
      final key = '${item.productoId}_${item.precioUnitario.toStringAsFixed(6)}';
      final existente = map[key];
      if (existente == null) {
        map[key] = (
          productoId: item.productoId,
          nombre: nombre,
          cantidad: item.cantidad,
          precioUnitario: item.precioUnitario,
        );
      } else {
        map[key] = (
          productoId: existente.productoId,
          nombre: existente.nombre,
          cantidad: existente.cantidad + item.cantidad,
          precioUnitario: existente.precioUnitario,
        );
      }
    }
    return map;
  }

  String _formatearLineaCuentaConPrecio({
    required ConfiguracionImpresion config,
    required int margenEsp,
    required int cantidad,
    required String nombre,
    required double precioUnitario,
  }) {
    final ancho = config.anchoCaracteres.clamp(24, 80);
    // Dejamos el margen para _aplicarMargen, aquí formateamos el contenido.
    // Formato: "<cant>x <nombre>" + (unit y subtotal alineados a la derecha)
    final subtotal = precioUnitario * cantidad;
    final right = '${precioUnitario.toStringAsFixed(2)}€  ${subtotal.toStringAsFixed(2)}€';

    // Reservar columna derecha. Si el ticket es estrecho, priorizar subtotal.
    final minRight = max(10, right.length);
    final rightW = min(minRight, (ancho * 0.45).floor().clamp(10, 24));
    final leftW = max(0, (ancho - 1 - rightW));

    var left = '${cantidad}x $nombre';
    if (left.length > leftW) {
      if (leftW <= 1) {
        left = '';
      } else if (leftW == 2) {
        left = '…';
      } else {
        left = left.substring(0, leftW - 1) + '…';
      }
    }
    final line = left.padRight(leftW) + ' ' + right.padLeft(rightW);
    return _aplicarMargen('$line\n', margenEsp);
  }

  /// Agrupa ítems por orden (1º, 2º, 3º...) y devuelve los turnos ordenados.
  Map<int, List<ItemPedido>> _agruparPorOrden(List<ItemPedido> items) {
    final map = <int, List<ItemPedido>>{};
    for (final item in items) {
      final o = item.orden;
      map.putIfAbsent(o, () => []).add(item);
    }
    final ordenados = map.keys.toList()..sort();
    return {for (final k in ordenados) k: map[k]!};
  }

  int _espaciosMargenIzq(ConfiguracionImpresion c) {
    if (c.margenIzquierdoMm <= 0) return 0;
    final n = (c.margenIzquierdoMm * c.anchoCaracteres / 80).round();
    return n.clamp(0, 10);
  }

  String _lineaSeparadora(ConfiguracionImpresion c) {
    final ch = c.caracterSeparador.isEmpty ? '=' : c.caracterSeparador.substring(0, 1);
    return ch * c.anchoCaracteres;
  }

  String _aplicarMargen(String texto, int espacios) {
    if (espacios <= 0) return texto;
    final pre = ' ' * espacios;
    return texto.split('\n').map((l) => pre + l).join('\n');
  }

  List<int> _escTamanioCabecera(ConfiguracionImpresion c) {
    switch (c.tamanioCabecera) {
      case 'doble_altura':
        return _escSizeDoubleHeight;
      case 'doble_ancho':
        return _escSizeDoubleWidth;
      case 'doble_ambos':
        return _escSizeDoubleBoth;
      default:
        return _escSizeNormal;
    }
  }

  /// Aplica el tamaño del cuerpo (ítems) y devuelve los bytes ESC/POS a enviar antes del texto.
  void _aplicarTamanioCuerpo(ConfiguracionImpresion c, void Function(List<int>) add) {
    switch (c.tamanioCuerpo) {
      case 'pequeno':
        add(_escCondensedOn);
        add(_escSizeNormal);
        break;
      case 'grande':
        add(_escCondensedOff);
        add(_escSizeDoubleHeight);
        break;
      default:
        add(_escCondensedOff);
        add(_escSizeNormal);
    }
  }

  /// Restablece tamaño y condensado después del cuerpo.
  void _resetTamanioCuerpo(void Function(List<int>) add) {
    add(_escSizeNormal);
    add(_escCondensedOff);
  }

  /// Genera el payload completo del ticket (ESC/POS + texto) según la configuración.
  Future<List<int>> _generarPayloadTicket(
    ConfiguracionImpresion config,
    int mesaNumero,
    int numeroTicket,
    List<ItemPedido> items,
  ) async {
    final out = <int>[];
    void add(List<int> bytes) => out.addAll(bytes);
    void addStr(String s) => out.addAll(utf8.encode(s));

    final margenEsp = _espaciosMargenIzq(config);
    final sep = _lineaSeparadora(config);

    add(_escInit);

    for (var i = 0; i < config.margenSuperiorLineas; i++) addStr('\n');

    final usarNumerico = config.modoTamanio == 'numerico';

    if (config.textoCabecera != null && config.textoCabecera!.isNotEmpty) {
      if (config.negritaCabecera) add(_escBoldOn);
      if (usarNumerico) {
        add(_gsSize(config.escalaAnchoCabecera, config.escalaAltoCabecera));
      } else {
        add(_escTamanioCabecera(config));
      }
      addStr(_aplicarMargen('${config.textoCabecera!.trim()}\n', margenEsp));
      if (!usarNumerico) add(_escSizeNormal);
      add(_escBoldOff);
    }

    addStr(_aplicarMargen('$sep\n', margenEsp));

    if (config.negritaCabecera) add(_escBoldOn);
    if (usarNumerico) {
      add(_gsSize(config.escalaAnchoCabecera, config.escalaAltoCabecera));
    } else {
      add(_escTamanioCabecera(config));
    }
    addStr(_aplicarMargen('      MESA $mesaNumero\n', margenEsp));
    addStr(_aplicarMargen('   Ticket #$numeroTicket\n', margenEsp));
    if (usarNumerico) {
      add(_gsSize(1, 1));
    } else {
      add(_escSizeNormal);
    }
    add(_escBoldOff);

    addStr(_aplicarMargen('$sep\n', margenEsp));
    addStr(_aplicarMargen('\n', margenEsp));

    if (usarNumerico) {
      add(_gsSize(config.escalaAnchoCuerpo, config.escalaAltoCuerpo));
    } else {
      _aplicarTamanioCuerpo(config, add);
    }
    if (config.negritaCuerpo) add(_escBoldOn);

    final itemsPorOrden = _agruparPorOrden(items);
    final chSep = config.caracterSeparador.isEmpty ? '=' : config.caracterSeparador.substring(0, 1);
    final sepCorta = chSep * (config.anchoCaracteres ~/ 2).clamp(12, 24);

    for (final entry in itemsPorOrden.entries) {
      final orden = entry.key;
      final itemsTurno = entry.value;
      addStr(_aplicarMargen('\n\n', margenEsp));
      addStr(_aplicarMargen('$orden Plato\n', margenEsp));
      addStr(_aplicarMargen('$sepCorta\n', margenEsp));
      final agrupado = _agruparCantidades(itemsTurno);
      for (final e in agrupado.entries) {
        addStr(_aplicarMargen('${e.value}x ${e.key}\n', margenEsp));
      }
    }

    if (config.negritaCuerpo) add(_escBoldOff);
    if (usarNumerico) {
      add(_gsSize(1, 1));
    } else {
      _resetTamanioCuerpo(add);
    }

    addStr(_aplicarMargen('\n', margenEsp));
    addStr(_aplicarMargen('$sep\n', margenEsp));

    if (config.mostrarFechaHora) {
      final now = DateTime.now();
      final fechaHora = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      addStr(_aplicarMargen('$fechaHora\n', margenEsp));
    }

    if (config.textoPie != null && config.textoPie!.isNotEmpty) {
      addStr(_aplicarMargen('${config.textoPie!.trim()}\n', margenEsp));
    }

    for (var i = 0; i < config.margenInferiorLineas; i++) addStr('\n');

    switch (config.tipoCorte) {
      case 'parcial':
        add(_escCutPartial);
        break;
      case 'ninguno':
        break;
      default:
        add(_escCutFull);
    }

    return out;
  }

  /// Genera el payload del ticket de cuenta de mesa (platos + total).
  Future<List<int>> _generarPayloadTicketCuenta(
    ConfiguracionImpresion config,
    int mesaNumero,
    List<ItemPedido> items,
    double total,
  ) async {
    final out = <int>[];
    void add(List<int> bytes) => out.addAll(bytes);
    void addStr(String s) => out.addAll(utf8.encode(s));

    final margenEsp = _espaciosMargenIzq(config);
    final sep = _lineaSeparadora(config);

    add(_escInit);

    for (var i = 0; i < config.margenSuperiorLineas; i++) addStr('\n');

    final usarNumerico = config.modoTamanio == 'numerico';

    if (config.textoCabecera != null && config.textoCabecera!.isNotEmpty) {
      if (config.negritaCabecera) add(_escBoldOn);
      if (usarNumerico) {
        add(_gsSize(config.escalaAnchoCabecera, config.escalaAltoCabecera));
      } else {
        add(_escTamanioCabecera(config));
      }
      addStr(_aplicarMargen('${config.textoCabecera!.trim()}\n', margenEsp));
      if (!usarNumerico) add(_escSizeNormal);
      add(_escBoldOff);
    }

    addStr(_aplicarMargen('$sep\n', margenEsp));

    if (config.negritaCabecera) add(_escBoldOn);
    if (usarNumerico) {
      add(_gsSize(config.escalaAnchoCabecera, config.escalaAltoCabecera));
    } else {
      add(_escTamanioCabecera(config));
    }
    addStr(_aplicarMargen('   CUENTA MESA $mesaNumero\n', margenEsp));
    if (usarNumerico) {
      add(_gsSize(1, 1));
    } else {
      add(_escSizeNormal);
    }
    add(_escBoldOff);

    addStr(_aplicarMargen('$sep\n', margenEsp));
    addStr(_aplicarMargen('\n', margenEsp));

    if (usarNumerico) {
      add(_gsSize(config.escalaAnchoCuerpo, config.escalaAltoCuerpo));
    } else {
      _aplicarTamanioCuerpo(config, add);
    }
    if (config.negritaCuerpo) add(_escBoldOn);

    final itemsPorOrden = _agruparPorOrden(items);
    final chSep = config.caracterSeparador.isEmpty ? '=' : config.caracterSeparador.substring(0, 1);
    final sepCorta = chSep * (config.anchoCaracteres ~/ 2).clamp(12, 24);

    for (final entry in itemsPorOrden.entries) {
      final orden = entry.key;
      final itemsTurno = entry.value;
      addStr(_aplicarMargen('\n\n', margenEsp));
      addStr(_aplicarMargen('$orden Plato\n', margenEsp));
      addStr(_aplicarMargen('$sepCorta\n', margenEsp));
      final agrupado = _agruparCantidadesConPrecio(itemsTurno);
      final valores = agrupado.values.toList()
        ..sort((a, b) => a.nombre.compareTo(b.nombre));
      for (final e in valores) {
        addStr(_formatearLineaCuentaConPrecio(
          config: config,
          margenEsp: margenEsp,
          cantidad: e.cantidad,
          nombre: e.nombre,
          precioUnitario: e.precioUnitario,
        ));
      }
    }

    if (config.negritaCuerpo) add(_escBoldOff);
    if (usarNumerico) {
      add(_gsSize(1, 1));
    } else {
      _resetTamanioCuerpo(add);
    }

    addStr(_aplicarMargen('\n', margenEsp));
    addStr(_aplicarMargen('$sep\n', margenEsp));
    if (config.negritaCabecera) add(_escBoldOn);
    addStr(_aplicarMargen('TOTAL: ${total.toStringAsFixed(2)}€\n', margenEsp));
    add(_escBoldOff);
    addStr(_aplicarMargen('$sep\n', margenEsp));

    if (config.mostrarFechaHora) {
      final now = DateTime.now();
      final fechaHora = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      addStr(_aplicarMargen('$fechaHora\n', margenEsp));
    }

    if (config.textoPie != null && config.textoPie!.isNotEmpty) {
      addStr(_aplicarMargen('${config.textoPie!.trim()}\n', margenEsp));
    }

    for (var i = 0; i < config.margenInferiorLineas; i++) addStr('\n');

    switch (config.tipoCorte) {
      case 'parcial':
        add(_escCutPartial);
        break;
      case 'ninguno':
        break;
      default:
        add(_escCutFull);
    }

    return out;
  }

  /// Imprime el ticket de cuenta de la mesa (platos + total) en la impresora configurada para cuenta.
  /// Si no hay impresora de cuenta configurada, no hace nada.
  Future<void> imprimirTicketCuentaMesa(
    int mesaNumero,
    List<ItemPedido> items,
    double total,
  ) async {
    if (items.isEmpty) return;
    final config = await ConfiguracionImpresionService.instance.cargar();
    if (!config.tieneImpresoraCuenta) return;
    final host = config.impresoraCuentaIp!.trim();
    final port = config.impresoraCuentaPuerto ?? _puertoPorDefecto;
    final payload = await _generarPayloadTicketCuenta(config, mesaNumero, items, total);
    await _enviarAImpresora(host, port, payload);
  }

  Future<bool> _enviarAImpresora(String host, int port, List<int> payload) async {
    Socket? socket;
    try {
      socket = await Socket.connect(host, port, timeout: _timeout);
      socket.add(payload);
      await socket.flush();
      await socket.close();
      return true;
    } catch (e) {
      debugPrint('Error enviando a $host:$port: $e');
      await socket?.close();
      return false;
    }
  }

  /// Imprime un pedido en una impresora específica (IP:puerto).
  /// Usado en modo buffet cuando está configurada la impresora buffet.
  Future<void> imprimirPedidoEnImpresora(
    Pedido pedido,
    String host,
    int port,
  ) async {
    if (pedido.items.isEmpty) return;
    final config = await ConfiguracionImpresionService.instance.cargar();
    final numeroTicket =
        await TicketNumeroService.instance.obtenerSiguienteNumero();
    final payload = await _generarPayloadTicket(
      config,
      pedido.mesaNumero,
      numeroTicket,
      pedido.items,
    );
    await _enviarAImpresora(host, port, payload);
  }

  Future<void> imprimirPedido(Pedido pedido) async {
    if (pedido.items.isEmpty) return;
    final db = DatabaseService.instance;
    final config = await ConfiguracionImpresionService.instance.cargar();
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
      final payload = await _generarPayloadTicket(config, pedido.mesaNumero, numeroTicket, items);
      final ok = await _enviarAImpresora(ip, port, payload);
      if (!ok) {
        debugPrint('No se pudo imprimir en ${destino.nombre} ($ip:$port)');
      }
    }
  }
}
