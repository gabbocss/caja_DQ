import '../../../../core/models/models.dart';
import '../../../../core/constants/app_constants.dart';

/// Representa un ticket/factura generada
class Ticket {
  /// Número de folio único
  final String folio;

  /// Fecha y hora de emisión
  final DateTime fechaEmision;

  /// Pedido asociado
  final Pedido pedido;

  /// Subtotal antes de impuestos
  final double subtotal;

  /// Impuesto (IVA)
  final double impuesto;

  /// Total a pagar
  final double total;

  /// Forma de pago
  final FormaPago formaPago;

  /// Monto recibido (para cálculo de cambio)
  final double? montoRecibido;

  /// Indica si el ticket ya fue impreso
  bool impreso;

  /// Fecha de impresión
  DateTime? fechaImpresion;

  Ticket({
    required this.folio,
    required this.pedido,
    required this.formaPago,
    this.montoRecibido,
    this.impreso = false,
    this.fechaImpresion,
  })  : fechaEmision = DateTime.now(),
        subtotal = pedido.total / 1.16, // Suponiendo IVA incluido del 16%
        impuesto = pedido.total - (pedido.total / 1.16),
        total = pedido.total;

  /// Calcula el cambio a devolver
  double get cambio => 
      montoRecibido != null ? (montoRecibido! - total).clamp(0, double.infinity) : 0;

  /// Genera el contenido del ticket para impresión
  String generarContenido() {
    final buffer = StringBuffer();
    final ancho = AppConstants.anchoTicket;

    // Encabezado
    buffer.writeln(_centrar(AppConstants.nombreEstablecimiento, ancho));
    buffer.writeln(_centrar(AppConstants.direccionEstablecimiento, ancho));
    buffer.writeln(_centrar(AppConstants.telefonoEstablecimiento, ancho));
    buffer.writeln('=' * ancho);
    
    // Información del ticket
    buffer.writeln('Folio: $folio');
    buffer.writeln('Fecha: ${_formatearFecha(fechaEmision)}');
    buffer.writeln('Mesa: ${pedido.mesaNumero}');
    buffer.writeln('Atendió: ${pedido.usuarioCamarero}');
    buffer.writeln('-' * ancho);

    // Items
    for (final item in pedido.items) {
      final lineaItem = '${item.cantidad}x ${item.nombreProducto}';
      final precio = '\$${item.subtotal.toStringAsFixed(2)}';
      buffer.writeln(_formatearLinea(lineaItem, precio, ancho));
    }

    buffer.writeln('-' * ancho);

    // Totales
    buffer.writeln(_formatearLinea('Subtotal:', '\$${subtotal.toStringAsFixed(2)}', ancho));
    buffer.writeln(_formatearLinea('IVA (16%):', '\$${impuesto.toStringAsFixed(2)}', ancho));
    buffer.writeln('=' * ancho);
    buffer.writeln(_formatearLinea('TOTAL:', '\$${total.toStringAsFixed(2)}', ancho));
    
    if (montoRecibido != null) {
      buffer.writeln(_formatearLinea('Recibido:', '\$${montoRecibido!.toStringAsFixed(2)}', ancho));
      buffer.writeln(_formatearLinea('Cambio:', '\$${cambio.toStringAsFixed(2)}', ancho));
    }

    buffer.writeln('=' * ancho);
    buffer.writeln(_centrar('Forma de Pago: ${formaPago.nombre}', ancho));
    buffer.writeln('');
    buffer.writeln(_centrar('¡Gracias por su visita!', ancho));
    buffer.writeln(_centrar('Vuelva pronto', ancho));

    return buffer.toString();
  }

  /// Centra un texto en el ancho dado
  String _centrar(String texto, int ancho) {
    if (texto.length >= ancho) return texto.substring(0, ancho);
    final espacios = (ancho - texto.length) ~/ 2;
    return ' ' * espacios + texto;
  }

  /// Formatea una línea con texto a la izquierda y derecha
  String _formatearLinea(String izq, String der, int ancho) {
    final espaciosDisponibles = ancho - izq.length - der.length;
    if (espaciosDisponibles < 1) {
      return '$izq $der';
    }
    return izq + ' ' * espaciosDisponibles + der;
  }

  /// Formatea una fecha para mostrar
  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year} '
        '${fecha.hour.toString().padLeft(2, '0')}:'
        '${fecha.minute.toString().padLeft(2, '0')}';
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'folio': folio,
      'fechaEmision': fechaEmision.toIso8601String(),
      'pedidoId': pedido.id,
      'subtotal': subtotal,
      'impuesto': impuesto,
      'total': total,
      'formaPago': formaPago.name,
      'montoRecibido': montoRecibido,
      'impreso': impreso,
      'fechaImpresion': fechaImpresion?.toIso8601String(),
    };
  }
}

/// Formas de pago disponibles
enum FormaPago {
  efectivo('Efectivo'),
  tarjeta('Tarjeta'),
  transferencia('Transferencia');

  final String nombre;
  const FormaPago(this.nombre);
}

/// Generador de folios para tickets
class FolioGenerator {
  static int _contador = 0;

  /// Genera un folio único
  static String generar() {
    _contador++;
    final fecha = DateTime.now();
    return '${fecha.year}${fecha.month.toString().padLeft(2, '0')}'
        '${fecha.day.toString().padLeft(2, '0')}-'
        '${_contador.toString().padLeft(4, '0')}';
  }

  /// Reinicia el contador (usar al inicio del día)
  static void reiniciarContador() {
    _contador = 0;
  }
}
