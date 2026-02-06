import 'package:isar/isar.dart';

part 'configuracion_buffet.g.dart';

/// Tipo de precio para el buffet
enum TipoPrecioBuffet {
  adulto,
  nino,
  menorGratis,
}

/// Configuración del servicio de Buffet del restaurante
/// Almacena horarios, precios y reglas del "All You Can Eat"
@collection
class ConfiguracionBuffet {
  /// Identificador único
  Id? id;

  /// Nombre de la configuración (ej: "Buffet Sábado")
  @Index(unique: true)
  late String nombre;

  /// Descripción del buffet
  String? descripcion;

  /// Día de la semana para el buffet (1=lunes, 7=domingo)
  /// Si es null, el buffet está disponible todos los días dentro del horario
  int? diaSemana;

  /// Hora de inicio del buffet (en formato HH:mm)
  late String horaInicio;

  /// Hora de fin del buffet (en formato HH:mm)
  late String horaFin;

  /// Precio para adultos (€)
  late double precioAdulto;

  /// Precio para niños (6-10 años) (€)
  late double precioNino;

  /// Edad mínima para el precio de niño
  late int edadMinimaInfantil;

  /// Edad máxima para el precio de niño (mayores pagan como adulto)
  late int edadMaximaInfantil;

  /// Precio para menores de edadMinimaInfantil (normalmente gratis)
  late double precioMenor;

  /// Indica si la configuración está activa
  late bool activo;

  /// Mensaje personalizado para mostrar durante el buffet
  String? mensajePromocion;

  /// Color del tema para el buffet (hex)
  String? colorTema;

  /// Fecha de creación
  late DateTime fechaCreacion;

  /// Fecha de última modificación
  DateTime? fechaModificacion;

  /// Constructor por defecto
  ConfiguracionBuffet();

  /// Constructor con valores por defecto para buffet de sábados
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
        activo = true,
        mensajePromocion = '¡Buffet All You Can Eat!',
        colorTema = '#FFD700',
        fechaCreacion = DateTime.now();

  /// Constructor con parámetros personalizados
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
    this.activo = true,
    this.mensajePromocion,
    this.colorTema,
  }) : fechaCreacion = DateTime.now();

  /// Verifica si actualmente estamos dentro del horario del buffet
  bool esHorarioBuffet() {
    final ahora = DateTime.now();
    
    // Verificar día de la semana si está configurado
    if (diaSemana != null && ahora.weekday != diaSemana) {
      return false;
    }

    // Parsear horas de inicio y fin
    final partsInicio = horaInicio.split(':');
    final partsFin = horaFin.split(':');
    
    final inicioMinutos = int.parse(partsInicio[0]) * 60 + int.parse(partsInicio[1]);
    final finMinutos = int.parse(partsFin[0]) * 60 + int.parse(partsFin[1]);
    final ahoraMinutos = ahora.hour * 60 + ahora.minute;

    return ahoraMinutos >= inicioMinutos && ahoraMinutos <= finMinutos;
  }

  /// Obtiene el precio según la edad del comensal
  double obtenerPrecioPorEdad(int edad) {
    if (edad < edadMinimaInfantil) {
      return precioMenor; // Gratis o precio reducido para los más pequeños
    } else if (edad <= edadMaximaInfantil) {
      return precioNino;
    } else {
      return precioAdulto;
    }
  }

  /// Obtiene el texto descriptivo del precio según la edad
  String obtenerDescripcionPrecio(int edad) {
    if (edad < edadMinimaInfantil) {
      return 'Menores de $edadMinimaInfantil años: ${precioMenor > 0 ? '${precioMenor.toStringAsFixed(0)}€' : 'GRATIS'}';
    } else if (edad <= edadMaximaInfantil) {
      return 'Niños ($edadMinimaInfantil-$edadMaximaInfantil años): ${precioNino.toStringAsFixed(0)}€';
    } else {
      return 'Adultos: ${precioAdulto.toStringAsFixed(0)}€';
    }
  }

  /// Convierte a JSON para serialización
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
      'activo': activo,
      'mensajePromocion': mensajePromocion,
      'colorTema': colorTema,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaModificacion': fechaModificacion?.toIso8601String(),
    };
  }

  /// Crea desde JSON
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
      ..activo = json['activo'] as bool? ?? true
      ..mensajePromocion = json['mensajePromocion'] as String?
      ..colorTema = json['colorTema'] as String?
      ..fechaCreacion = json['fechaCreacion'] != null
          ? DateTime.parse(json['fechaCreacion'] as String)
          : DateTime.now()
      ..fechaModificacion = json['fechaModificacion'] != null
          ? DateTime.parse(json['fechaModificacion'] as String)
          : null;

    if (json['id'] != null) {
      config.id = json['id'] as int;
    }

    return config;
  }

  @override
  String toString() => 'ConfiguracionBuffet(nombre: $nombre, dia: $diaSemana, horario: $horaInicio-$horaFin)';
}
