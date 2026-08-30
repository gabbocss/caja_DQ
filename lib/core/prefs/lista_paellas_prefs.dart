import 'package:shared_preferences/shared_preferences.dart';

/// IDs de reservas ya enviados a cocina en listas/asporto automáticos (por día).
///
/// Una sola clave por día evita imprimir dos veces la misma reserva cuando
/// [ListaPaellasAutoService] evalúa comida y cena en la misma pasada.

String _claveMesas(DateTime dia) =>
    'lista_paellas_ids_mesas_${dia.year}-${dia.month}-${dia.day}';

String _claveAsportos(DateTime dia) =>
    'lista_paellas_ids_asporto_${dia.year}-${dia.month}-${dia.day}';

String _claveBarra(DateTime dia) =>
    'lista_paellas_ids_barra_${dia.year}-${dia.month}-${dia.day}';

Future<Set<int>> idsMesasYaEnviados(DateTime dia) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getStringList(_claveMesas(dia)) ?? [];
  return raw.map(int.tryParse).whereType<int>().toSet();
}

Future<Set<int>> idsAsportoYaEnviados(DateTime dia) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getStringList(_claveAsportos(dia)) ?? [];
  return raw.map(int.tryParse).whereType<int>().toSet();
}

Future<void> marcarMesasEnviadas(
  DateTime dia, {
  required Iterable<int> ids,
}) async {
  if (ids.isEmpty) return;
  final prefs = await SharedPreferences.getInstance();
  final clave = _claveMesas(dia);
  final actual = {...(prefs.getStringList(clave) ?? [])};
  for (final id in ids) {
    actual.add('$id');
  }
  await prefs.setStringList(clave, actual.toList()..sort());
}

Future<void> marcarAsportosEnviados(
  DateTime dia, {
  required Iterable<int> ids,
}) async {
  if (ids.isEmpty) return;
  final prefs = await SharedPreferences.getInstance();
  final clave = _claveAsportos(dia);
  final actual = {...(prefs.getStringList(clave) ?? [])};
  for (final id in ids) {
    actual.add('$id');
  }
  await prefs.setStringList(clave, actual.toList()..sort());
}

Future<Set<int>> idsBarraYaAvisados(DateTime dia) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getStringList(_claveBarra(dia)) ?? [];
  return raw.map(int.tryParse).whereType<int>().toSet();
}

Future<void> marcarBarraAvisados(
  DateTime dia, {
  required Iterable<int> ids,
}) async {
  if (ids.isEmpty) return;
  final prefs = await SharedPreferences.getInstance();
  final clave = _claveBarra(dia);
  final actual = {...(prefs.getStringList(clave) ?? [])};
  for (final id in ids) {
    actual.add('$id');
  }
  await prefs.setStringList(clave, actual.toList()..sort());
}
