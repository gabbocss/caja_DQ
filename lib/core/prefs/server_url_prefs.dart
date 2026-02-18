import 'package:shared_preferences/shared_preferences.dart';

/// Clave para guardar la URL del servidor en SharedPreferences
const String serverUrlKey = 'server_url';

/// Guarda la URL del servidor
Future<void> saveServerUrl(String url) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(serverUrlKey, url);
}

/// Obtiene la URL guardada (null si no hay)
Future<String?> getSavedServerUrl() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(serverUrlKey);
}

/// True si hay una URL válida (no vacía y no solo localhost)
Future<bool> hasValidServerUrl() async {
  final url = await getSavedServerUrl();
  if (url == null || url.isEmpty) return false;
  if (url == 'http://localhost:8080') return false;
  return true;
}
