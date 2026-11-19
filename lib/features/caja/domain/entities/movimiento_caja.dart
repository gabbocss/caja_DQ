/// Entrada del log de movimientos de una sesión de caja.
///
/// Se congela en el cierre para poder auditar el día desde el histórico.
class MovimientoCaja {
  /// apertura | cobro | retiro | cierre | nota
  final String tipo;
  final DateTime fecha;
  final String descripcion;
  /// Importe con signo: entrada positiva, salida negativa.
  final double importe;
  final String? metodo;
  final int? mesaNumero;
  final bool? esParcial;

  const MovimientoCaja({
    required this.tipo,
    required this.fecha,
    required this.descripcion,
    required this.importe,
    this.metodo,
    this.mesaNumero,
    this.esParcial,
  });

  Map<String, dynamic> toJson() => {
        'tipo': tipo,
        'fecha': fecha.toIso8601String(),
        'descripcion': descripcion,
        'importe': importe,
        if (metodo != null) 'metodo': metodo,
        if (mesaNumero != null) 'mesaNumero': mesaNumero,
        if (esParcial != null) 'esParcial': esParcial,
      };

  factory MovimientoCaja.fromJson(Map<String, dynamic> json) => MovimientoCaja(
        tipo: json['tipo'] as String? ?? 'nota',
        fecha: DateTime.parse(json['fecha'] as String),
        descripcion: json['descripcion'] as String? ?? '',
        importe: (json['importe'] as num?)?.toDouble() ?? 0,
        metodo: json['metodo'] as String?,
        mesaNumero: json['mesaNumero'] as int?,
        esParcial: json['esParcial'] as bool?,
      );
}
