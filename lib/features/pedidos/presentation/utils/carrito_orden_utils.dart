import '../pages/pedidos_page.dart' show ItemCarrito;
import '../widgets/dialogo_orden_plato.dart';

/// Grupo visual del carrito: mismas líneas con igual producto, orden y notas.
class GrupoCarritoUi {
  /// Índices en la lista original (orden de inserción).
  final List<int> indices;
  final ItemCarrito representativo;
  final int cantidad;

  const GrupoCarritoUi({
    required this.indices,
    required this.representativo,
    required this.cantidad,
  });

  double get subtotal => representativo.producto.precio * cantidad;

  /// Índice a eliminar con swipe (una unidad del grupo).
  int get indiceParaEliminar => indices.last;
}

/// Operaciones de turno/variantes sobre el carrito (líneas de cantidad 1).
class CarritoOrdenUtils {
  CarritoOrdenUtils._();

  static String claveGrupo(ItemCarrito item) {
    final id = item.producto.id;
    final productoKey = (id != null && id > 0) ? 'id:$id' : 'n:${item.producto.nombre}';
    final notas = item.notas?.trim() ?? '';
    return '$productoKey|${item.orden}|$notas';
  }

  /// Agrupa líneas idénticas para mostrar una sola fila con cantidad.
  static List<GrupoCarritoUi> agruparParaUi(List<ItemCarrito> items) {
    final ordenClaves = <String>[];
    final porClave = <String, List<int>>{};
    for (var i = 0; i < items.length; i++) {
      final key = claveGrupo(items[i]);
      if (!porClave.containsKey(key)) {
        ordenClaves.add(key);
        porClave[key] = [];
      }
      porClave[key]!.add(i);
    }
    return [
      for (final key in ordenClaves)
        GrupoCarritoUi(
          indices: porClave[key]!,
          representativo: items[porClave[key]!.first],
          cantidad: porClave[key]!.fold<int>(
            0,
            (sum, i) => sum + items[i].cantidad,
          ),
        ),
    ];
  }

  /// Cuenta unidades de un plato por turno (1º / 2º / 3º).
  static ({int primero, int segundo, int tercero, int total}) distribucion(
    List<ItemCarrito> carrito,
    int productoId,
  ) {
    var primero = 0;
    var segundo = 0;
    var tercero = 0;
    for (final item in carrito) {
      if (item.producto.id != productoId) continue;
      switch (item.orden) {
        case 2:
          segundo += item.cantidad;
          break;
        case 3:
          tercero += item.cantidad;
          break;
        default:
          primero += item.cantidad;
          break;
      }
    }
    return (
      primero: primero,
      segundo: segundo,
      tercero: tercero,
      total: primero + segundo + tercero,
    );
  }

  /// Agrupa notas/variantes de un plato por turno.
  static List<VariantePlato> variantes(
    List<ItemCarrito> carrito,
    int productoId,
  ) {
    final porClave = <String, ({int orden, String texto, int cantidad})>{};
    for (final item in carrito) {
      if (item.producto.id != productoId) continue;
      final texto = item.notas?.trim() ?? '';
      if (texto.isEmpty) continue;
      final orden = switch (item.orden) {
        2 => 2,
        3 => 3,
        _ => 1,
      };
      final key = '$orden|$texto';
      final prev = porClave[key];
      if (prev == null) {
        porClave[key] = (orden: orden, texto: texto, cantidad: item.cantidad);
      } else {
        porClave[key] = (
          orden: orden,
          texto: texto,
          cantidad: prev.cantidad + item.cantidad,
        );
      }
    }
    return [
      for (final e in porClave.values)
        VariantePlato(
          orden: e.orden,
          texto: e.texto,
          cantidad: e.cantidad,
        ),
    ];
  }

  /// Deja exactamente [total] unidades del producto, con [segundo] en 2º y
  /// [tercero] en 3º; asigna variantes por turno. Si [total] es menor que las
  /// unidades actuales, elimina el exceso (prioridad: líneas de 1º).
  static void aplicarDistribucion({
    required List<ItemCarrito> carrito,
    required int productoId,
    required int total,
    required int segundo,
    required int tercero,
    List<VariantePlato> variantes = const [],
  }) {
    var indices = <int>[];
    for (var i = 0; i < carrito.length; i++) {
      if (carrito[i].producto.id == productoId) indices.add(i);
    }
    if (indices.isEmpty && total <= 0) return;

    var actual = indices.fold<int>(0, (sum, i) => sum + carrito[i].cantidad);
    final deseado = total.clamp(0, actual);

    // Eliminar exceso priorizando líneas de 1º (orden distinto de 2 y 3).
    while (actual > deseado && indices.isNotEmpty) {
      int? idxEliminar;
      for (var k = indices.length - 1; k >= 0; k--) {
        final orden = carrito[indices[k]].orden;
        if (orden != 2 && orden != 3) {
          idxEliminar = indices[k];
          break;
        }
      }
      idxEliminar ??= indices.last;
      actual -= carrito[idxEliminar].cantidad;
      carrito.removeAt(idxEliminar);
      indices = [
        for (var i = 0; i < carrito.length; i++)
          if (carrito[i].producto.id == productoId) i,
      ];
    }

    if (indices.isEmpty) return;

    final nTotal =
        indices.fold<int>(0, (sum, i) => sum + carrito[i].cantidad);
    final n2 = segundo.clamp(0, nTotal);
    final n3 = tercero.clamp(0, nTotal - n2);

    var asignados2 = 0;
    var asignados3 = 0;
    for (final i in indices) {
      if (asignados2 < n2) {
        carrito[i].orden = 2;
        asignados2 += carrito[i].cantidad;
      } else if (asignados3 < n3) {
        carrito[i].orden = 3;
        asignados3 += carrito[i].cantidad;
      } else {
        carrito[i].orden = 1;
      }
      carrito[i].notas = null;
    }

    final porOrden = <int, List<int>>{1: [], 2: [], 3: []};
    for (final i in indices) {
      final o = switch (carrito[i].orden) {
        2 => 2,
        3 => 3,
        _ => 1,
      };
      porOrden[o]!.add(i);
    }

    for (final orden in [1, 2, 3]) {
      final indicesTurno = porOrden[orden]!;
      if (indicesTurno.isEmpty) continue;
      var cursor = 0;
      var usados = 0;
      final cupo = indicesTurno.fold<int>(
        0,
        (sum, i) => sum + carrito[i].cantidad,
      );
      for (final variante in variantes.where((v) => v.orden == orden)) {
        final texto = variante.texto.trim();
        if (texto.isEmpty || variante.cantidad <= 0) continue;
        final n = variante.cantidad.clamp(0, cupo - usados);
        if (n <= 0) break;
        var asignados = 0;
        while (asignados < n && cursor < indicesTurno.length) {
          final i = indicesTurno[cursor++];
          carrito[i].notas = texto;
          asignados += carrito[i].cantidad;
        }
        usados += asignados;
      }
    }
  }
}
