import '../../../../core/core.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/repositories/facturacion_repository.dart';
import '../services/printer_service.dart';

/// Implementación del repositorio de Facturación
class FacturacionRepositoryImpl implements FacturacionRepository {
  final DatabaseService _db;
  final PrinterService _printer;

  /// Historial de tickets en memoria (podría persistirse)
  final List<Ticket> _historial = [];

  FacturacionRepositoryImpl(this._db) : _printer = PrinterService.instance;

  @override
  Future<Ticket> generarTicket({
    required Pedido pedido,
    required FormaPago formaPago,
    double? montoRecibido,
  }) async {
    // Generar folio único
    final folio = FolioGenerator.generar();

    // Crear el ticket
    final ticket = Ticket(
      folio: folio,
      pedido: pedido,
      formaPago: formaPago,
      montoRecibido: montoRecibido,
    );

    // Guardar en historial
    _historial.add(ticket);

    // Marcar el pedido como pagado
    if (pedido.id != null) {
      await _db.actualizarEstadoPedido(pedido.id!, EstadoPedido.pagado);
    }

    return ticket;
  }

  @override
  Future<List<Ticket>> obtenerHistorial({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    var resultado = _historial.toList();

    if (desde != null) {
      resultado = resultado.where(
        (t) => t.fechaEmision.isAfter(desde) || 
               t.fechaEmision.isAtSameMomentAs(desde)
      ).toList();
    }

    if (hasta != null) {
      resultado = resultado.where(
        (t) => t.fechaEmision.isBefore(hasta) || 
               t.fechaEmision.isAtSameMomentAs(hasta)
      ).toList();
    }

    // Ordenar por fecha descendente
    resultado.sort((a, b) => b.fechaEmision.compareTo(a.fechaEmision));

    return resultado;
  }

  @override
  Future<Ticket?> obtenerTicketPorFolio(String folio) async {
    try {
      return _historial.firstWhere((t) => t.folio == folio);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> marcarComoImpreso(String folio) async {
    final ticket = await obtenerTicketPorFolio(folio);
    if (ticket != null) {
      ticket.impreso = true;
      ticket.fechaImpresion = DateTime.now();
    }
  }

  @override
  Future<double> obtenerVentasDelDia() async {
    final hoy = DateTime.now();
    final inicioDelDia = DateTime(hoy.year, hoy.month, hoy.day);
    final finDelDia = inicioDelDia.add(const Duration(days: 1));

    final ticketsHoy = await obtenerHistorial(
      desde: inicioDelDia,
      hasta: finDelDia,
    );

    return ticketsHoy.fold<double>(0.0, (sum, ticket) => sum + ticket.total);
  }

  @override
  Future<Map<FormaPago, double>> obtenerResumenPorFormaPago({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final tickets = await obtenerHistorial(desde: desde, hasta: hasta);
    
    final resumen = <FormaPago, double>{
      FormaPago.efectivo: 0,
      FormaPago.tarjeta: 0,
      FormaPago.transferencia: 0,
    };

    for (final ticket in tickets) {
      resumen[ticket.formaPago] = 
          (resumen[ticket.formaPago] ?? 0) + ticket.total;
    }

    return resumen;
  }

  @override
  Future<bool> imprimirTicket(Ticket ticket) async {
    final resultado = await _printer.imprimir(ticket);
    
    if (resultado) {
      await marcarComoImpreso(ticket.folio);
    }
    
    return resultado;
  }

  @override
  Future<bool> verificarImpresora() async {
    return await _printer.verificarDisponibilidad();
  }
}
