import '../../../core/models/reserva.dart';
import '../../../core/prefs/horarios_reservas_prefs.dart';

/// Franjas de la agenda de reservas.
enum FranjaReserva { comida, cena, asporto }

extension FranjaReservaX on FranjaReserva {
  String get etiqueta {
    switch (this) {
      case FranjaReserva.comida:
        return 'comida';
      case FranjaReserva.cena:
        return 'cena';
      case FranjaReserva.asporto:
        return 'asporto';
    }
  }
}

/// Clasifica una reserva: asporto si 0 cubiertos; si no, por horario.
FranjaReserva clasificarReserva(Reserva reserva, HorariosReservas horarios) {
  if (reserva.numeroPersonas <= 0) return FranjaReserva.asporto;

  final minutos =
      reserva.fechaHoraLlegada.hour * 60 + reserva.fechaHoraLlegada.minute;

  if (_enRango(minutos, horarios.comidaInicioMin, horarios.comidaFinMin)) {
    return FranjaReserva.comida;
  }
  if (_enRango(minutos, horarios.cenaInicioMin, horarios.cenaFinMin)) {
    return FranjaReserva.cena;
  }

  // Fuera de ambos rangos: antes del inicio de cena → comida; si no → cena.
  if (minutos < horarios.cenaInicioMin) return FranjaReserva.comida;
  return FranjaReserva.cena;
}

bool _enRango(int minutos, int inicio, int fin) {
  if (inicio <= fin) {
    return minutos >= inicio && minutos <= fin;
  }
  // Rango que cruza medianoche (p. ej. 22:00–02:00).
  return minutos >= inicio || minutos <= fin;
}
