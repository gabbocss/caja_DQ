/// Agregación pura de cobros para el arqueo de caja (sin I/O).
///
/// Regla de caja física: el esperado incluye **efectivo** y **otros**.
/// La **tarjeta** se registra para el desglose de mesa, pero no entra en el
/// cajón (no suma al total esperado).
class AgregacionCobros {
  AgregacionCobros._();

  /// Totales por método a partir de registros ya filtrados (misma sesión, no archivados).
  static Map<String, double> totalesPorMetodo(
    Iterable<({String metodo, double importeCobrado})> registros,
  ) {
    const metodos = ['efectivo', 'tarjeta', 'otros'];
    final totales = {for (final m in metodos) m: 0.0};
    for (final r in registros) {
      final metodo = r.metodo.toLowerCase();
      if (totales.containsKey(metodo)) {
        totales[metodo] = totales[metodo]! + r.importeCobrado;
      }
    }
    return totales;
  }

  /// Efectivo + otros (lo que debe haber en caja además del fondo, menos retiros).
  static double cobrosQueEntranEnCaja(Map<String, double> totalesPorMetodo) {
    return (totalesPorMetodo['efectivo'] ?? 0) +
        (totalesPorMetodo['otros'] ?? 0);
  }

  /// Total esperado en cajón: fondo + efectivo + otros − retiros.
  static double totalEsperadoCaja({
    required double fondoInicial,
    required Map<String, double> totalesPorMetodo,
    required double totalRetiros,
  }) {
    return fondoInicial +
        cobrosQueEntranEnCaja(totalesPorMetodo) -
        totalRetiros;
  }
}
