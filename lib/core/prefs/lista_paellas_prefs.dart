import 'package:shared_preferences/shared_preferences.dart';

/// IDs de reservas ya enviados a cocina en listas/asporto automáticos (por día y servicio).

String _claveMesas(DateTime dia, {required bool esComida}) =>
    'lista_paellas_ids_mesas_${esComida ? 'comida' : 'cena'}_'
    '${dia.year}-${dia.month}-${dia.day}';

String _claveAsportos(DateTime dia, {required bool esComida}) =>
    'lista_paellas_ids_asporto_${esComida ? 'comida' : 'cena'}_'
    '${dia.year}-${dia.month}-${dia.day}';

Future<Set<int>> idsMesasYaEnviados(
  DateTime dia, {
  required bool esComida,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getStringList(_claveMesas(dia, esComida: esComida)) ?? [];
  return raw.map(int.tryParse).whereType<int>().toSet();
}

Future<Set<int>> idsAsportoYaEnviados(
  DateTime dia, {
  required bool esComida,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final raw =
      prefs.getStringList(_claveAsportos(dia, esComida: esComida)) ?? [];
  return raw.map(int.tryParse).whereType<int>().toSet();
}

Future<void> marcarMesasEnviadas(
  DateTime dia, {
  required bool esComida,
  required Iterable<int> ids,
}) async {
  if (ids.isEmpty) return;
  final prefs = await SharedPreferences.getInstance();
  final clave = _claveMesas(dia, esComida: esComida);
  final actual = {...(prefs.getStringList(clave) ?? [])};
  for (final id in ids) {
    actual.add('$id');
  }
  await prefs.setStringList(clave, actual.toList()..sort());
}

Future<void> marcarAsportosEnviados(
  DateTime dia, {
  required bool esComida,
  required Iterable<int> ids,
}) async {
  if (ids.isEmpty) return;
  final prefs = await SharedPreferences.getInstance();
  final clave = _claveAsportos(dia, esComida: esComida);
  final actual = {...(prefs.getStringList(clave) ?? [])};
  for (final id in ids) {
    actual.add('$id');
  }
  await prefs.setStringList(clave, actual.toList()..sort());
}
