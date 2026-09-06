/// Unidad de comparación del producto (€/kg, €/L o €/ud).
enum UnidadBase {
  kilo,
  litro,
  unidad;

  String get etiqueta {
    switch (this) {
      case UnidadBase.kilo:
        return 'Kilo';
      case UnidadBase.litro:
        return 'Litro';
      case UnidadBase.unidad:
        return 'Unidad';
    }
  }

  String get etiquetaPrecio {
    switch (this) {
      case UnidadBase.kilo:
        return '€/kg';
      case UnidadBase.litro:
        return '€/L';
      case UnidadBase.unidad:
        return '€/ud';
    }
  }

  static UnidadBase fromString(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'kilo':
        return UnidadBase.kilo;
      case 'litro':
        return UnidadBase.litro;
      default:
        return UnidadBase.unidad;
    }
  }

  String get apiValue => name;
}

/// Unidad del envase (ml, g, etc.).
enum ContenidoUnidad {
  ml,
  l,
  g,
  kg,
  ud;

  String get etiqueta => name;

  /// Etiqueta legible para la UI (evita confundir con «Ud.» genérico).
  String get etiquetaLarga {
    switch (this) {
      case ContenidoUnidad.ml:
        return 'ml';
      case ContenidoUnidad.l:
        return 'litros';
      case ContenidoUnidad.g:
        return 'g';
      case ContenidoUnidad.kg:
        return 'kg';
      case ContenidoUnidad.ud:
        return 'unidades';
    }
  }

  static ContenidoUnidad fromString(String? value, UnidadBase base) {
    switch ((value ?? '').toLowerCase()) {
      case 'ml':
        return ContenidoUnidad.ml;
      case 'l':
        return ContenidoUnidad.l;
      case 'g':
        return ContenidoUnidad.g;
      case 'kg':
        return ContenidoUnidad.kg;
      case 'ud':
        return ContenidoUnidad.ud;
      default:
        return base == UnidadBase.litro
            ? ContenidoUnidad.ml
            : base == UnidadBase.kilo
                ? ContenidoUnidad.g
                : ContenidoUnidad.ud;
    }
  }

  static List<ContenidoUnidad> paraBase(UnidadBase base) {
    switch (base) {
      case UnidadBase.litro:
        return [ContenidoUnidad.ml, ContenidoUnidad.l];
      case UnidadBase.kilo:
        return [ContenidoUnidad.g, ContenidoUnidad.kg];
      case UnidadBase.unidad:
        return [ContenidoUnidad.ud];
    }
  }
}

/// Calcula €/litro, €/kg o €/ud a partir del precio del envase.
double? calcularPrecioPorBase({
  required double precioEnvase,
  required double contenidoCantidad,
  required ContenidoUnidad contenidoUnidad,
  required UnidadBase unidadBase,
}) {
  if (precioEnvase < 0 || contenidoCantidad <= 0) return null;
  final enBase = _aCantidadBase(contenidoCantidad, contenidoUnidad, unidadBase);
  if (enBase == null || enBase <= 0) return null;
  return precioEnvase / enBase;
}

double? _aCantidadBase(
  double cantidad,
  ContenidoUnidad u,
  UnidadBase base,
) {
  switch (base) {
    case UnidadBase.litro:
      if (u == ContenidoUnidad.ml) return cantidad / 1000;
      if (u == ContenidoUnidad.l) return cantidad;
      return null;
    case UnidadBase.kilo:
      if (u == ContenidoUnidad.g) return cantidad / 1000;
      if (u == ContenidoUnidad.kg) return cantidad;
      return null;
    case UnidadBase.unidad:
      if (u == ContenidoUnidad.ud) return cantidad;
      return null;
  }
}

String formatearPrecioPorBase(double? valor, UnidadBase base) {
  if (valor == null) return '—';
  return '${valor.toStringAsFixed(2)} ${base.etiquetaPrecio}';
}

String formatearPrecioEnvase(double? valor) {
  if (valor == null) return '—';
  return '${valor.toStringAsFixed(2)} €';
}

/// Ejemplo: «Envase 1,49 € · 1,99 €/L»
String formatearPrecioCompleto({
  required double precioEnvase,
  required double precioPorBase,
  required UnidadBase unidadBase,
}) {
  return 'Envase ${formatearPrecioEnvase(precioEnvase)} · '
      '${formatearPrecioPorBase(precioPorBase, unidadBase)}';
}
