import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias de la pantalla Cocina (KDS), persistidas en el dispositivo/navegador.

const String cocinaSonidoActivadoKey = 'cocina_sonido_activado';

Future<bool> getCocinaSonidoActivado() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(cocinaSonidoActivadoKey) ?? false;
}

Future<void> setCocinaSonidoActivado(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(cocinaSonidoActivadoKey, value);
}
