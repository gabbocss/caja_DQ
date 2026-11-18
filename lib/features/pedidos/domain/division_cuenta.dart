/// Lógica pura de división de cuenta por personas (cubiertos / menú adulto).
class DivisionCuenta {
  DivisionCuenta._();

  /// Tolerancia para considerar que un cobro es exactamente una cuota.
  static const toleranciaCuota = 0.05;

  /// Personas iniciales: menús adulto de buffet, o cubiertos.
  static int personasOriginalesDesdeItems({
    required Iterable<({String nombre, int cantidad})> items,
    int adultosBuffetLocal = 0,
    int cubiertosLocal = 0,
    int numeroComensalesMax = 0,
  }) {
    var adultosBuffet = 0;
    var cubiertos = 0;
    for (final item in items) {
      if (item.nombre == 'Buffet - Adulto') {
        adultosBuffet += item.cantidad;
      } else if (item.nombre == 'Cubiertos') {
        cubiertos += item.cantidad;
      }
    }
    if (adultosBuffet > 0) return adultosBuffet;
    if (cubiertos > 0) return cubiertos;
    if (adultosBuffetLocal > 0) return adultosBuffetLocal;
    if (cubiertosLocal > 0) return cubiertosLocal;
    return numeroComensalesMax > 0 ? numeroComensalesMax : 1;
  }

  /// Personas con las que dividir ahora (restantes guardadas o originales).
  static int personasParaDividir({
    required int originales,
    int? restantesGuardadas,
  }) {
    if (restantesGuardadas != null && restantesGuardadas >= 1) {
      return restantesGuardadas.clamp(1, 99);
    }
    return originales.clamp(1, 99);
  }

  /// Importe de una cuota (pendiente / personas).
  static double partePorPersona(double pendiente, int personas) {
    if (!pendiente.isFinite || pendiente <= 0 || personas < 1) return 0;
    return pendiente / personas;
  }

  /// ¿El cobro coincide con una cuota por persona?
  static bool esImporteCuota({
    required double importeCobrado,
    required double partePorPersona,
  }) {
    return (importeCobrado - partePorPersona).abs() <= toleranciaCuota;
  }

  /// Personas restantes tras un cobro (baja 1 si fue cuota).
  static int personasTrasCobro({
    required double importeCobrado,
    required double partePorPersona,
    required int personasAntes,
  }) {
    if (personasAntes <= 1) return 1;
    if (!esImporteCuota(
      importeCobrado: importeCobrado,
      partePorPersona: partePorPersona,
    )) {
      return personasAntes.clamp(1, 99);
    }
    return (personasAntes - 1).clamp(1, 99);
  }
}
