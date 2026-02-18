/// Configuración de impresión para tickets térmicos 80mm.
/// Se persiste en JSON; no es una colección Isar.
class ConfiguracionImpresion {
  /// Modo de tamaño: 'presets' (ESC !, compatible) o 'numerico' (GS !, escala 1-8)
  String modoTamanio;

  /// Tamaño de la cabecera (MESA X, Ticket #N): normal, doble altura, doble ancho, doble ambos (solo si modoTamanio == presets)
  String tamanioCabecera;

  /// Tamaño del cuerpo (solo si modoTamanio == presets): pequeno, normal, grande
  String tamanioCuerpo;

  /// Escala ancho cabecera 1-8 (solo si modoTamanio == numerico)
  int escalaAnchoCabecera;

  /// Escala alto cabecera 1-8
  int escalaAltoCabecera;

  /// Escala ancho cuerpo 1-8
  int escalaAnchoCuerpo;

  /// Escala alto cuerpo 1-8
  int escalaAltoCuerpo;

  bool negritaCabecera;
  bool negritaCuerpo;

  /// Margen izquierdo en mm (0-10)
  int margenIzquierdoMm;

  /// Líneas en blanco al inicio del ticket
  int margenSuperiorLineas;

  /// Líneas en blanco antes del corte
  int margenInferiorLineas;

  /// Texto opcional arriba (ej. nombre del local)
  String? textoCabecera;

  /// Texto opcional abajo (ej. "Gracias por su visita")
  String? textoPie;

  /// Carácter para las líneas separadoras (=, -, *, etc.)
  String caracterSeparador;

  bool mostrarFechaHora;

  /// Ancho útil en caracteres (32, 42, 48 típico para 80mm)
  int anchoCaracteres;

  /// Tipo de corte al final: completo, parcial, ninguno
  String tipoCorte;

  ConfiguracionImpresion({
    this.modoTamanio = 'presets',
    this.tamanioCabecera = 'normal',
    this.tamanioCuerpo = 'normal',
    this.escalaAnchoCabecera = 2,
    this.escalaAltoCabecera = 2,
    this.escalaAnchoCuerpo = 1,
    this.escalaAltoCuerpo = 1,
    this.negritaCabecera = true,
    this.negritaCuerpo = false,
    this.margenIzquierdoMm = 2,
    this.margenSuperiorLineas = 0,
    this.margenInferiorLineas = 1,
    this.textoCabecera,
    this.textoPie,
    this.caracterSeparador = '=',
    this.mostrarFechaHora = true,
    this.anchoCaracteres = 48,
    this.tipoCorte = 'completo',
  });

  factory ConfiguracionImpresion.fromJson(Map<String, dynamic> json) {
    return ConfiguracionImpresion(
      modoTamanio: json['modoTamanio'] as String? ?? 'presets',
      tamanioCabecera: json['tamanioCabecera'] as String? ?? 'normal',
      tamanioCuerpo: _normalizarTamanioCuerpo(json['tamanioCuerpo'] as String?),
      escalaAnchoCabecera: _clampEscala((json['escalaAnchoCabecera'] as num?)?.toInt()),
      escalaAltoCabecera: _clampEscala((json['escalaAltoCabecera'] as num?)?.toInt()),
      escalaAnchoCuerpo: _clampEscala((json['escalaAnchoCuerpo'] as num?)?.toInt()),
      escalaAltoCuerpo: _clampEscala((json['escalaAltoCuerpo'] as num?)?.toInt()),
      negritaCabecera: json['negritaCabecera'] as bool? ?? true,
      negritaCuerpo: json['negritaCuerpo'] as bool? ?? false,
      margenIzquierdoMm: (json['margenIzquierdoMm'] as num?)?.toInt() ?? 2,
      margenSuperiorLineas: (json['margenSuperiorLineas'] as num?)?.toInt() ?? 0,
      margenInferiorLineas: (json['margenInferiorLineas'] as num?)?.toInt() ?? 1,
      textoCabecera: json['textoCabecera'] as String?,
      textoPie: json['textoPie'] as String?,
      caracterSeparador: (json['caracterSeparador'] as String?) ?? '=',
      mostrarFechaHora: json['mostrarFechaHora'] as bool? ?? true,
      anchoCaracteres: (json['anchoCaracteres'] as num?)?.toInt() ?? 48,
      tipoCorte: json['tipoCorte'] as String? ?? 'completo',
    );
  }

  static int _clampEscala(int? v) {
    if (v == null) return 1;
    return v.clamp(1, 8);
  }

  Map<String, dynamic> toJson() {
    return {
      'modoTamanio': modoTamanio,
      'tamanioCabecera': tamanioCabecera,
      'tamanioCuerpo': tamanioCuerpo,
      'escalaAnchoCabecera': escalaAnchoCabecera,
      'escalaAltoCabecera': escalaAltoCabecera,
      'escalaAnchoCuerpo': escalaAnchoCuerpo,
      'escalaAltoCuerpo': escalaAltoCuerpo,
      'negritaCabecera': negritaCabecera,
      'negritaCuerpo': negritaCuerpo,
      'margenIzquierdoMm': margenIzquierdoMm,
      'margenSuperiorLineas': margenSuperiorLineas,
      'margenInferiorLineas': margenInferiorLineas,
      'textoCabecera': textoCabecera,
      'textoPie': textoPie,
      'caracterSeparador': caracterSeparador,
      'mostrarFechaHora': mostrarFechaHora,
      'anchoCaracteres': anchoCaracteres,
      'tipoCorte': tipoCorte,
    };
  }

  /// Valores posibles para tamanioCabecera
  static const List<String> opcionesTamanioCabecera = [
    'normal',
    'doble_altura',
    'doble_ancho',
    'doble_ambos',
  ];

  /// Pequeño = condensado (más caracteres por línea), Normal = estándar, Grande = doble altura
  static const List<String> opcionesTamanioCuerpo = ['pequeno', 'normal', 'grande'];

  static String _normalizarTamanioCuerpo(String? v) {
    if (v == null || v.isEmpty) return 'normal';
    if (v == 'condensado') return 'pequeno'; // compatibilidad
    if (opcionesTamanioCuerpo.contains(v)) return v;
    return 'normal';
  }

  static const List<int> opcionesAnchoCaracteres = [32, 42, 48];

  static const List<String> opcionesTipoCorte = ['completo', 'parcial', 'ninguno'];

  static const List<String> opcionesModoTamanio = ['presets', 'numerico'];
}
