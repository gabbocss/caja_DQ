import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_endpoints.dart';

/// URL del servidor de reservas 24/7 (p. ej. nodo Lightning / VPS en casa).
const String reservasCentralUrlKey = 'reservas_central_url';

Future<void> saveReservasCentralUrl(String url) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    reservasCentralUrlKey,
    ApiEndpoints.normalizeBaseUrl(url),
  );
}

Future<String?> getReservasCentralUrl() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(reservasCentralUrlKey);
}

/// URL efectiva: dedicada a reservas o, si no hay, la del servidor guardada (si no es localhost).
Future<String?> getReservasCentralUrlEfectiva() async {
  final dedicada = await getReservasCentralUrl();
  if (dedicada != null && dedicada.isNotEmpty) return dedicada;
  final general = await SharedPreferences.getInstance()
      .then((p) => p.getString('server_url'));
  if (general == null || general.isEmpty) return null;
  if (general == 'http://localhost:8080') return null;
  return general;
}
