import 'package:shared_preferences/shared_preferences.dart';

/// Destino de impresión para la lista automática de reservas («Lista paellas»).

const String _destinoListaPaellasIdKey = 'reservas_destino_lista_paellas_id';

Future<int?> getDestinoListaPaellasId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_destinoListaPaellasIdKey);
}

Future<void> saveDestinoListaPaellasId(int? id) async {
  final prefs = await SharedPreferences.getInstance();
  if (id == null) {
    await prefs.remove(_destinoListaPaellasIdKey);
  } else {
    await prefs.setInt(_destinoListaPaellasIdKey, id);
  }
}
