import '../../../core/network/api_client.dart';
import '../../../core/prefs/reservas_central_prefs.dart';
import '../domain/entities/supermercado.dart';

/// Acceso a supermercados en el VPS (sin caché local).
class SupermercadosRemoteService {
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

  Future<List<Supermercado>> obtenerLista() async {
    final client = await _cliente();
    try {
      final raw = await client.obtenerSupermercados();
      return raw.map(Supermercado.fromJson).toList();
    } finally {
      client.dispose();
    }
  }

  Future<Supermercado> guardar(Supermercado item) async {
    final client = await _cliente();
    try {
      final raw = await client.guardarSupermercado(item.toJson());
      return Supermercado.fromJson(raw);
    } finally {
      client.dispose();
    }
  }

  Future<List<Supermercado>> reordenar(List<int> ids) async {
    final client = await _cliente();
    try {
      final raw = await client.reordenarSupermercados(ids);
      return raw.map(Supermercado.fromJson).toList();
    } finally {
      client.dispose();
    }
  }

  Future<void> eliminar(int id) async {
    final client = await _cliente();
    try {
      await client.eliminarSupermercado(id);
    } finally {
      client.dispose();
    }
  }
}
