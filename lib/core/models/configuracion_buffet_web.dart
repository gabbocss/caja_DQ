/// Versión del modelo ConfiguracionBuffet para compilación Web (sin Isar).

enum TipoPrecioBuffet {
  adulto,
  nino,
  menorGratis,
}

class ConfiguracionBuffet {
  int? id;
  late String nombre;
  String? descripcion;
  int? diaSemana;
  late String horaInicio;
  late String horaFin;
  late double precioAdulto;
  late double precioNino;
  late int edadMinimaInfantil;
  late int edadMaximaInfantil;
  late double precioMenor;
  late double precioCubierto;
  late bool activo;
  String? mensajePromocion;
  String? colorTema;
  late DateTime fechaCreacion;
  DateTime? fechaModificacion;

  /// Activa límite QR (tipos distintos + espera entre envíos).
  late bool limiteBuffetQrActivo;

  /// Tipos distintos por comensal por ventana.
  late int buffetTiposDistintosPorPersonaPorVentana;

  /// Minutos de ventana y espera entre envíos.
  late int buffetMinutosVentana;

  ConfiguracionBuffet();

  ConfiguracionBuffet.sabadoDefault()
      : nombre = 'Buffet Sábado',
        descripcion = 'All You Can Eat - Sábados de 11:30 a 14:45',
        diaSemana = DateTime.saturday,
        horaInicio = '11:30',
        horaFin = '14:45',
        precioAdulto = 18.0,
        precioNino = 9.0,
        edadMinimaInfantil = 6,
        edadMaximaInfantil = 10,
        precioMenor = 0.0,
        precioCubierto = 2.0,
        activo = true,
        mensajePromocion = '¡Buffet All You Can Eat!',
        colorTema = '#FFD700',
        limiteBuffetQrActivo = false,
        buffetTiposDistintosPorPersonaPorVentana = 5,
        buffetMinutosVentana = 5,
        fechaCreacion = DateTime.now();

  ConfiguracionBuffet.crear({
    required this.nombre,
    this.descripcion,
    this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
    required this.precioAdulto,
    required this.precioNino,
    this.edadMinimaInfantil = 6,
    this.edadMaximaInfantil = 10,
    this.precioMenor = 0.0,
    this.precioCubierto = 2.0,
    this.activo = true,
    this.mensajePromocion,
    this.colorTema,
    this.limiteBuffetQrActivo = false,
    this.buffetTiposDistintosPorPersonaPorVentana = 5,
    this.buffetMinutosVentana = 5,
  }) : fechaCreacion = DateTime.now();

  bool esHorarioBuffet() {
    final ahora = DateTime.now();
    if (diaSemana != null && ahora.weekday != diaSemana) {
      return false;
    }
    final partsInicio = horaInicio.split(':');
    final partsFin = horaFin.split(':');
    final inicioMinutos = int.parse(partsInicio[0]) * 60 + int.parse(partsInicio[1]);
    final finMinutos = int.parse(partsFin[0]) * 60 + int.parse(partsFin[1]);
    final ahoraMinutos = ahora.hour * 60 + ahora.minute;
    return ahoraMinutos >= inicioMinutos && ahoraMinutos <= finMinutos;
  }

  double obtenerPrecioPorEdad(int edad) {
    if (edad < edadMinimaInfantil) {
      return precioMenor;
    } else if (edad <= edadMaximaInfantil) {
      return precioNino;
    } else {
      return precioAdulto;
    }
  }

  String obtenerDescripcionPrecio(int edad) {
    if (edad < edadMinimaInfantil) {
      return 'Menores de $edadMinimaInfantil años: ${precioMenor > 0 ? '${precioMenor.toStringAsFixed(0)}€' : 'GRATIS'}';
    } else if (edad <= edadMaximaInfantil) {
      return 'Niños ($edadMinimaInfantil-$edadMaximaInfantil años): ${precioNino.toStringAsFixed(0)}€';
    } else {
      return 'Adultos: ${precioAdulto.toStringAsFixed(0)}€';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'diaSemana': diaSemana,
      'horaInicio': horaInicio,
      'horaFin': horaFin,
      'precioAdulto': precioAdulto,
      'precioNino': precioNino,
      'edadMinimaInfantil': edadMinimaInfantil,
      'edadMaximaInfantil': edadMaximaInfantil,
      'precioMenor': precioMenor,
      'precioCubierto': precioCubierto,
      'activo': activo,
      'mensajePromocion': mensajePromocion,
      'colorTema': colorTema,
      'limiteBuffetQrActivo': limiteBuffetQrActivo,
      'buffetTiposDistintosPorPersonaPorVentana': buffetTiposDistintosPorPersonaPorVentana,
      'buffetMinutosVentana': buffetMinutosVentana,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaModificacion': fechaModificacion?.toIso8601String(),
    };
  }

  factory ConfiguracionBuffet.fromJson(Map<String, dynamic> json) {
    final config = ConfiguracionBuffet()
      ..nombre = json['nombre'] as String
      ..descripcion = json['descripcion'] as String?
      ..diaSemana = json['diaSemana'] as int?
      ..horaInicio = json['horaInicio'] as String? ?? '11:30'
      ..horaFin = json['horaFin'] as String? ?? '14:45'
      ..precioAdulto = (json['precioAdulto'] as num?)?.toDouble() ?? 18.0
      ..precioNino = (json['precioNino'] as num?)?.toDouble() ?? 9.0
      ..edadMinimaInfantil = json['edadMinimaInfantil'] as int? ?? 6
      ..edadMaximaInfantil = json['edadMaximaInfantil'] as int? ?? 10
      ..precioMenor = (json['precioMenor'] as num?)?.toDouble() ?? 0.0
      ..precioCubierto = (json['precioCubierto'] as num?)?.toDouble() ?? 2.0
      ..activo = json['activo'] as bool? ?? true
      ..mensajePromocion = json['mensajePromocion'] as String?
      ..colorTema = json['colorTema'] as String?
      ..limiteBuffetQrActivo = json['limiteBuffetQrActivo'] as bool? ?? false
      ..buffetTiposDistintosPorPersonaPorVentana =
          (json['buffetTiposDistintosPorPersonaPorVentana'] as num?)?.toInt() ?? 5
      ..buffetMinutosVentana = (json['buffetMinutosVentana'] as num?)?.toInt() ?? 5
      ..fechaCreacion = json['fechaCreacion'] != null
          ? DateTime.parse(json['fechaCreacion'] as String)
          : DateTime.now()
      ..fechaModificacion = json['fechaModificacion'] != null
          ? DateTime.parse(json['fechaModificacion'] as String)
          : null;

    if (json['id'] != null) {
      config.id = (json['id'] as num).toInt();
    }

    return config;
  }

  @override
  String toString() => 'ConfiguracionBuffet(nombre: $nombre, dia: $diaSemana, horario: $horaInicio-$horaFin)';
}
