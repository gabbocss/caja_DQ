import '../../../../core/models/models.dart';
import '../entities/ticket.dart';

/// Interfaz del repositorio de Facturación
abstract class FacturacionRepository {
  /// Genera un ticket para un pedido
  Future<Ticket> generarTicket({
    required Pedido pedido,
    required FormaPago formaPago,
    double? montoRecibido,
  });

  /// Obtiene el historial de tickets
  Future<List<Ticket>> obtenerHistorial({
    DateTime? desde,
    DateTime? hasta,
  });

  /// Obtiene un ticket por folio
  Future<Ticket?> obtenerTicketPorFolio(String folio);

  /// Marca un ticket como impreso
  Future<void> marcarComoImpreso(String folio);

  /// Obtiene el total de ventas del día
  Future<double> obtenerVentasDelDia();

  /// Obtiene el resumen de ventas por forma de pago
  Future<Map<FormaPago, double>> obtenerResumenPorFormaPago({
    DateTime? desde,
    DateTime? hasta,
  });

  /// Imprime un ticket
  Future<bool> imprimirTicket(Ticket ticket);

  /// Verifica si la impresora está disponible
  Future<bool> verificarImpresora();
}
