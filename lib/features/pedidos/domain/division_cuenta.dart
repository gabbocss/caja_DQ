/// Ámbito de un descuento manual en el cobro.
enum TipoDescuentoCuenta {
  /// Se resta una vez del pendiente de la mesa (queda en caja como descuento).
  total,

  /// Se resta de la cuota por persona y fija esa cuota para el resto.
  porPersona,
}

/// Resultado de calcular un descuento manual (sin I/O).
class ResultadoDescuentoManual {
  /// Importe de descuento validado (acotado al máximo posible).
  final double descuentoAplicado;

  /// Nueva cuota por persona (solo en [TipoDescuentoCuenta.porPersona]).
  final double? cuotaAcordada;

  /// Cuota teórica antes del descuento por persona.
  final double? cuotaTeorica;

  const ResultadoDescuentoManual({
    required this.descuentoAplicado,
    this.cuotaAcordada,
    this.cuotaTeorica,
  });
}

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

  /// Calcula un descuento manual sobre el total o por persona.
  ///
  /// - **Total:** [descuentoAplicado] ≤ pendiente.
  /// - **Por persona:** nueva cuota = teórica − descuento (≥ 0); fija [cuotaAcordada].
  ///
  /// Devuelve `null` si el importe no es válido.
  static ResultadoDescuentoManual? calcularDescuentoManual({
    required TipoDescuentoCuenta tipo,
    required double importeDescuento,
    required double pendiente,
    required int personas,
  }) {
    if (!importeDescuento.isFinite || importeDescuento <= 0.009) return null;
    if (!pendiente.isFinite || pendiente <= 0.009) return null;

    if (tipo == TipoDescuentoCuenta.total) {
      final aplicado =
          importeDescuento < pendiente ? importeDescuento : pendiente;
      if (aplicado <= 0.009) return null;
      return ResultadoDescuentoManual(descuentoAplicado: aplicado);
    }

    if (personas < 1) return null;
    final teorica = partePorPersona(pendiente, personas);
    if (teorica <= 0.009) return null;
    final descuento =
        importeDescuento < teorica ? importeDescuento : teorica;
    final cuota = (teorica - descuento).clamp(0.0, teorica);
    // Debe quedar algo cobrable, o al menos un descuento claro.
    if (descuento <= 0.009) return null;
    return ResultadoDescuentoManual(
      descuentoAplicado: descuento,
      cuotaAcordada: cuota,
      cuotaTeorica: teorica,
    );
  }

  /// Importe a sugerir en el diálogo: cuota fijada a mano, o división real.
  ///
  /// La cuota acordada solo aplica mientras no haya pedidos nuevos (la UI la
  /// invalida al crecer la cuenta). Nunca sugiere más que el pendiente.
  static double importeSugerido({
    required double pendiente,
    required int personas,
    double? cuotaAcordada,
  }) {
    if (!pendiente.isFinite || pendiente <= 0.009) return 0;
    if (cuotaAcordada != null &&
        cuotaAcordada.isFinite &&
        cuotaAcordada > 0.009) {
      return cuotaAcordada < pendiente ? cuotaAcordada : pendiente;
    }
    return partePorPersona(pendiente, personas);
  }

  /// ¿El cobro coincide con una cuota por persona?
  static bool esImporteCuota({
    required double importeCobrado,
    required double partePorPersona,
  }) {
    return (importeCobrado - partePorPersona).abs() <= toleranciaCuota;
  }

  /// ¿El cobro corresponde a la cuota acordada (descuento manual)?
  static bool esImporteCuotaAcordada({
    required double importeCobrado,
    required double? cuotaAcordada,
  }) {
    if (cuotaAcordada == null || !cuotaAcordada.isFinite) return false;
    if (cuotaAcordada <= 0.009) return false;
    return (importeCobrado - cuotaAcordada).abs() <= toleranciaCuota;
  }

  /// Personas restantes tras un cobro (baja 1 si fue cuota teórica o acordada).
  static int personasTrasCobro({
    required double importeCobrado,
    required double partePorPersona,
    required int personasAntes,
    double? cuotaAcordada,
    bool forzarCuota = false,
  }) {
    if (personasAntes <= 1) return 1;
    final esCuota = forzarCuota ||
        esImporteCuota(
          importeCobrado: importeCobrado,
          partePorPersona: partePorPersona,
        ) ||
        esImporteCuotaAcordada(
          importeCobrado: importeCobrado,
          cuotaAcordada: cuotaAcordada,
        );
    if (!esCuota) return personasAntes.clamp(1, 99);
    return (personasAntes - 1).clamp(1, 99);
  }

  /// Resto a condonar tras cobrar la cuota acordada al último comensal.
  ///
  /// Si no hay cuota fijada o no es el último, devuelve 0 (los céntimos siguen
  /// en pendiente por si piden más o pagan el resto).
  static double restoACondonarAlCerrarConCuota({
    required double pendienteAntes,
    required double importeCobrado,
    required int personasAntes,
    required bool usandoCuotaAcordada,
  }) {
    if (!usandoCuotaAcordada || personasAntes != 1) return 0;
    if (!pendienteAntes.isFinite || !importeCobrado.isFinite) return 0;
    final resto = pendienteAntes - importeCobrado;
    if (resto <= 0.009) return 0;
    return resto;
  }
}
