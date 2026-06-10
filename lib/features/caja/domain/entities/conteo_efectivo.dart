import 'denominacion_euro.dart';

/// Cantidad de billetes/monedas por denominación.
class ConteoEfectivo {
  final Map<String, int> cantidades;

  const ConteoEfectivo([this.cantidades = const {}]);

  factory ConteoEfectivo.vacio() {
    final map = <String, int>{};
    for (final v in DenominacionEuro.valores) {
      map[DenominacionEuro.clave(v)] = 0;
    }
    return ConteoEfectivo(map);
  }

  factory ConteoEfectivo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ConteoEfectivo.vacio();
    final map = Map<String, int>.from(ConteoEfectivo.vacio().cantidades);
    for (final entry in json.entries) {
      map[entry.key] = (entry.value as num?)?.toInt() ?? 0;
    }
    return ConteoEfectivo(map);
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(cantidades);

  int cantidadDe(double denominacion) =>
      cantidades[DenominacionEuro.clave(denominacion)] ?? 0;

  ConteoEfectivo conCantidad(double denominacion, int cantidad) {
    final copia = Map<String, int>.from(cantidades);
    copia[DenominacionEuro.clave(denominacion)] = cantidad.clamp(0, 99999);
    return ConteoEfectivo(copia);
  }

  double get total {
    var suma = 0.0;
    for (final valor in DenominacionEuro.valores) {
      final cant = cantidadDe(valor);
      suma += valor * cant;
    }
    return suma;
  }

  bool get estaVacio => total < 0.001;
}
