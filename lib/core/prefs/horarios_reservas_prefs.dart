import 'package:shared_preferences/shared_preferences.dart';

/// Horarios configurables para clasificar reservas (comida / cena).
/// Asporto se detecta por `numeroPersonas == 0`, no por horario.

const String _comidaInicioKey = 'reservas_comida_inicio_min';
const String _comidaFinKey = 'reservas_comida_fin_min';
const String _cenaInicioKey = 'reservas_cena_inicio_min';
const String _cenaFinKey = 'reservas_cena_fin_min';

/// Defaults: comida 12:00–17:00, cena 19:00–23:59.
const int defaultComidaInicioMin = 12 * 60;
const int defaultComidaFinMin = 17 * 60;
const int defaultCenaInicioMin = 19 * 60;
const int defaultCenaFinMin = 23 * 60 + 59;

class HorariosReservas {
  const HorariosReservas({
    required this.comidaInicioMin,
    required this.comidaFinMin,
    required this.cenaInicioMin,
    required this.cenaFinMin,
  });

  final int comidaInicioMin;
  final int comidaFinMin;
  final int cenaInicioMin;
  final int cenaFinMin;

  static const defaults = HorariosReservas(
    comidaInicioMin: defaultComidaInicioMin,
    comidaFinMin: defaultComidaFinMin,
    cenaInicioMin: defaultCenaInicioMin,
    cenaFinMin: defaultCenaFinMin,
  );

  HorariosReservas copyWith({
    int? comidaInicioMin,
    int? comidaFinMin,
    int? cenaInicioMin,
    int? cenaFinMin,
  }) {
    return HorariosReservas(
      comidaInicioMin: comidaInicioMin ?? this.comidaInicioMin,
      comidaFinMin: comidaFinMin ?? this.comidaFinMin,
      cenaInicioMin: cenaInicioMin ?? this.cenaInicioMin,
      cenaFinMin: cenaFinMin ?? this.cenaFinMin,
    );
  }
}

Future<HorariosReservas> getHorariosReservas() async {
  final prefs = await SharedPreferences.getInstance();
  return HorariosReservas(
    comidaInicioMin:
        prefs.getInt(_comidaInicioKey) ?? defaultComidaInicioMin,
    comidaFinMin: prefs.getInt(_comidaFinKey) ?? defaultComidaFinMin,
    cenaInicioMin: prefs.getInt(_cenaInicioKey) ?? defaultCenaInicioMin,
    cenaFinMin: prefs.getInt(_cenaFinKey) ?? defaultCenaFinMin,
  );
}

Future<void> saveHorariosReservas(HorariosReservas h) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_comidaInicioKey, h.comidaInicioMin);
  await prefs.setInt(_comidaFinKey, h.comidaFinMin);
  await prefs.setInt(_cenaInicioKey, h.cenaInicioMin);
  await prefs.setInt(_cenaFinKey, h.cenaFinMin);
}

String formatoMinutosDelDia(int minutos) {
  final m = minutos.clamp(0, 23 * 60 + 59);
  final h = m ~/ 60;
  final min = m % 60;
  return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
}

int minutosDesdeTimeOfDay({required int hour, required int minute}) =>
    hour * 60 + minute;
