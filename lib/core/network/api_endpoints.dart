/// Rutas HTTP compartidas entre [ApiClient] y [LocalServer] (deben coincidir al 100%).
abstract final class ApiEndpoints {
  static const String apiRoot = '/api';
  static const String reservas = '/api/reservas';
  static const String reservasMarcarSincronizadas =
      '/api/reservas/marcar-sincronizadas';
  static const String productos = '/api/productos';
  static const String health = '/health';
  static const String healthApi = '/api/health';

  /// Normaliza la URL base (sin barra final ni sufijo `/api` duplicado).
  static String normalizeBaseUrl(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    if (u.toLowerCase().endsWith('/api')) {
      u = u.substring(0, u.length - 4);
      while (u.endsWith('/')) {
        u = u.substring(0, u.length - 1);
      }
    }
    return u;
  }

  /// Construye la URI absoluta para un path de API (`/api/...` o `api/...`).
  static Uri uri(String baseUrl, String path) {
    final base = normalizeBaseUrl(baseUrl);
    final p = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse(base).resolve(p);
  }

  static Uri reservasEstado(String baseUrl, int id) =>
      uri(baseUrl, '/api/reservas/$id/estado');
}
