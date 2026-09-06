import '../../../core/network/api_client.dart';
import '../../../core/prefs/reservas_central_prefs.dart';
import '../domain/entities/item_lista_compra.dart';
import '../domain/entities/precio_producto.dart';
import '../domain/entities/supermercado.dart';

/// Acceso a la lista de la compra / precios / súpers en el VPS.
class ListaCompraRemoteService {
  Future<ApiClient> _cliente() async {
    final url = await getReservasCentralUrlEfectiva();
    if (url == null || url.isEmpty) {
      throw Exception(
        'Sin URL del servidor central (VPS). '
        'Usa la misma URL que reservas (servidor central).',
      );
    }
    return ApiClient(url);
  }

  Future<List<ItemListaCompra>> obtenerLista() async {
    final client = await _cliente();
    try {
      final raw = await client.obtenerListaCompra();
      return raw.map(ItemListaCompra.fromJson).toList();
    } finally {
      client.dispose();
    }
  }

  Future<ItemListaCompra> guardar(ItemListaCompra item) async {
    final client = await _cliente();
    try {
      final raw = await client.guardarItemListaCompra(item.toJson());
      return ItemListaCompra.fromJson(raw);
    } finally {
      client.dispose();
    }
  }

  Future<ItemListaCompra> actualizar(int id, Map<String, dynamic> cambios) async {
    final client = await _cliente();
    try {
      final raw = await client.actualizarItemListaCompra(id, cambios);
      return ItemListaCompra.fromJson(raw);
    } finally {
      client.dispose();
    }
  }

  Future<void> vaciarCompra() async {
    final client = await _cliente();
    try {
      await client.vaciarCompraListaCompra();
    } finally {
      client.dispose();
    }
  }

  Future<List<ItemListaCompra>> reordenar(List<int> ids) async {
    final client = await _cliente();
    try {
      final raw = await client.reordenarListaCompra(ids);
      return raw.map(ItemListaCompra.fromJson).toList();
    } finally {
      client.dispose();
    }
  }

  Future<List<PrecioProducto>> obtenerPrecios({
    int? productoId,
    int? supermercadoId,
  }) async {
    final client = await _cliente();
    try {
      final raw = await client.obtenerPreciosListaCompra(
        productoId: productoId,
        supermercadoId: supermercadoId,
      );
      return raw.map(PrecioProducto.fromJson).toList();
    } finally {
      client.dispose();
    }
  }

  Future<PrecioProducto> guardarPrecio(PrecioProducto precio) async {
    final client = await _cliente();
    try {
      final raw = await client.guardarPrecioListaCompra(precio.toJson());
      return PrecioProducto.fromJson(raw);
    } finally {
      client.dispose();
    }
  }

  Future<List<Supermercado>> obtenerSupermercados() async {
    final client = await _cliente();
    try {
      final raw = await client.obtenerSupermercados();
      return raw.map(Supermercado.fromJson).toList();
    } finally {
      client.dispose();
    }
  }
}
