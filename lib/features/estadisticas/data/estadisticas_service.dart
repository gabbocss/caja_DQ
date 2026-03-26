import '../../../../core/core.dart';

/// Resultado: plato con cantidad total pedida
class PlatoMasPedido {
  final int productoId;
  final String nombreProducto;
  final String? categoria;
  final int cantidadTotal;

  PlatoMasPedido({
    required this.productoId,
    required this.nombreProducto,
    this.categoria,
    required this.cantidadTotal,
  });
}

/// Resultado: tiempo de preparación en minutos (desde Empezar hasta Listo) por pedido/mesa.
class TiempoPreparacion {
  final int pedidoId;
  final int mesaNumero;
  final double minutos;

  TiempoPreparacion({
    required this.pedidoId,
    required this.mesaNumero,
    required this.minutos,
  });
}

/// Resultado: tiempo medio por plato (desde que empiezas el plato hasta que das Hecho).
class TiempoMedioPlato {
  final int productoId;
  final String nombreProducto;
  final int cantidadRegistros;
  final double tiempoMedioMinutos;

  TiempoMedioPlato({
    required this.productoId,
    required this.nombreProducto,
    required this.cantidadRegistros,
    required this.tiempoMedioMinutos,
  });
}

/// Servicio para consultas de estadísticas (platos más pedidos, tiempos de preparación).
/// Usa solo DatabaseService (UI servidor/desktop).
class EstadisticasService {
  static Future<List<PlatoMasPedido>> obtenerPlatosMasPedidos({
    required DateTime desde,
    required DateTime hasta,
    String? categoria,
  }) async {
    final hastaEndOfDay = DateTime(hasta.year, hasta.month, hasta.day, 23, 59, 59, 999);
    final pedidos = await DatabaseService.instance.obtenerPedidosEntreFechas(desde, hastaEndOfDay);
    final productos = await DatabaseService.instance.obtenerProductos();
    final mapProductoIdCategoria = {for (final p in productos) p.id: p.categoria};

    final map = <String, PlatoMasPedido>{};
    for (final pedido in pedidos) {
      for (final item in pedido.items) {
        final cat = mapProductoIdCategoria[item.productoId];
        if (categoria != null && categoria.isNotEmpty && cat != categoria) continue;
        final key = '${item.productoId}_${item.nombreProducto}';
        if (map.containsKey(key)) {
          final exist = map[key]!;
          map[key] = PlatoMasPedido(
            productoId: exist.productoId,
            nombreProducto: exist.nombreProducto,
            categoria: exist.categoria,
            cantidadTotal: exist.cantidadTotal + item.cantidad,
          );
        } else {
          map[key] = PlatoMasPedido(
            productoId: item.productoId,
            nombreProducto: item.nombreProducto,
            categoria: cat,
            cantidadTotal: item.cantidad,
          );
        }
      }
    }
    final list = map.values.toList();
    list.sort((a, b) => b.cantidadTotal.compareTo(a.cantidadTotal));
    return list;
  }

  static Future<List<TiempoPreparacion>> obtenerTiemposPreparacion({
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final hastaEndOfDay = DateTime(hasta.year, hasta.month, hasta.day, 23, 59, 59, 999);
    final pedidos = await DatabaseService.instance.obtenerPedidosEntreFechas(desde, hastaEndOfDay);
    final list = <TiempoPreparacion>[];
    for (final p in pedidos) {
      if (p.fechaInicioPreparacion == null || p.fechaListo == null) continue;
      final duracion = p.fechaListo!.difference(p.fechaInicioPreparacion!);
      final minutos = duracion.inSeconds / 60.0;
      list.add(TiempoPreparacion(
        pedidoId: p.id ?? 0,
        mesaNumero: p.mesaNumero,
        minutos: minutos,
      ));
    }
    return list;
  }

  /// Tiempo medio por plato: desde que se empieza el plato (preparando) hasta que se marca Hecho (listo).
  /// Agrupa por producto y devuelve la media de minutos por plato.
  static Future<List<TiempoMedioPlato>> obtenerTiemposMediosPorPlato({
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final hastaEndOfDay = DateTime(hasta.year, hasta.month, hasta.day, 23, 59, 59, 999);
    final pedidos = await DatabaseService.instance.obtenerPedidosEntreFechas(desde, hastaEndOfDay);
    // Por cada plato (productoId + nombreProducto): lista de duraciones en minutos
    final map = <String, List<double>>{};
    const sep = '\x01'; // Separador que no aparece en nombres
    for (final p in pedidos) {
      for (final item in p.items) {
        if (item.fechaInicioPreparacionItem == null || item.fechaListoItem == null) continue;
        final duracion = item.fechaListoItem!.difference(item.fechaInicioPreparacionItem!);
        final minutos = duracion.inSeconds / 60.0;
        final key = '${item.productoId}$sep${item.nombreProducto}';
        map.putIfAbsent(key, () => []).add(minutos);
      }
    }
    final list = <TiempoMedioPlato>[];
    for (final entry in map.entries) {
      final idx = entry.key.indexOf(sep);
      if (idx < 0) continue;
      final productoId = int.tryParse(entry.key.substring(0, idx)) ?? 0;
      final nombreProducto = entry.key.substring(idx + sep.length);
      final tiempos = entry.value;
      final media = tiempos.reduce((a, b) => a + b) / tiempos.length;
      list.add(TiempoMedioPlato(
        productoId: productoId,
        nombreProducto: nombreProducto,
        cantidadRegistros: tiempos.length,
        tiempoMedioMinutos: media,
      ));
    }
    list.sort((a, b) => b.cantidadRegistros.compareTo(a.cantidadRegistros));
    return list;
  }

  static Future<List<String>> obtenerCategoriasDisponibles() async {
    final categorias = await DatabaseService.instance.obtenerCategorias();
    final nombres = categorias.map((c) => c.nombre).toList();
    nombres.sort();
    return nombres;
  }

  /// Suma de unidades pedidas por [productoId] en el rango (para ordenar grid en UI servidor).
  /// Por defecto últimos 365 días hasta hoy.
  static Future<Map<int, int>> obtenerMapaCantidadPedidaPorProducto({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final ahora = DateTime.now();
    final h = hasta ?? ahora;
    final d = desde ?? h.subtract(const Duration(days: 365));
    final hastaEndOfDay = DateTime(h.year, h.month, h.day, 23, 59, 59, 999);
    final pedidos = await DatabaseService.instance.obtenerPedidosEntreFechas(d, hastaEndOfDay);
    final map = <int, int>{};
    for (final pedido in pedidos) {
      for (final item in pedido.items) {
        map[item.productoId] = (map[item.productoId] ?? 0) + item.cantidad;
      }
    }
    return map;
  }
}
