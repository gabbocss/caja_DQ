/// Denominaciones de euro usadas en el arqueo de caja.
class DenominacionEuro {
  DenominacionEuro._();

  /// Billetes y monedas de 50 € hasta 0,50 €.
  static const List<double> valores = [
    50,
    20,
    10,
    5,
    2,
    1,
    0.5,
  ];

  static String etiqueta(double valor) {
    if (valor >= 1) {
      return '${valor.toStringAsFixed(valor == valor.roundToDouble() ? 0 : 1)} €';
    }
    final centimos = (valor * 100).round();
    return '${centimos}c';
  }

  static String clave(double valor) => valor.toString();
}
