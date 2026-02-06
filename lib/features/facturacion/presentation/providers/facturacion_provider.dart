import 'package:flutter/foundation.dart';

import '../../../../core/core.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/repositories/facturacion_repository.dart';
import '../../data/repositories/facturacion_repository_impl.dart';
import '../../data/services/printer_service.dart';

/// Provider para manejar el estado de Facturación
class FacturacionProvider extends ChangeNotifier {
  final FacturacionRepository _repository;
  final PrinterService _printer = PrinterService.instance;

  List<Ticket> _historial = [];
  double _ventasDelDia = 0;
  Map<FormaPago, double> _resumenFormaPago = {};
  bool _cargando = false;
  String? _error;
  bool _impresoraDisponible = false;

  /// Historial de tickets
  List<Ticket> get historial => _historial;

  /// Total de ventas del día
  double get ventasDelDia => _ventasDelDia;

  /// Resumen por forma de pago
  Map<FormaPago, double> get resumenFormaPago => _resumenFormaPago;

  /// Indica si hay operación en progreso
  bool get cargando => _cargando;

  /// Mensaje de error
  String? get error => _error;

  /// Indica si la impresora está disponible
  bool get impresoraDisponible => _impresoraDisponible;

  /// Nombre de la impresora configurada
  String? get nombreImpresora => _printer.printerName;

  FacturacionProvider({FacturacionRepository? repository})
      : _repository =
            repository ?? FacturacionRepositoryImpl(DatabaseService.instance) {
    _cargarDatos();
    _verificarImpresora();
  }

  /// Carga los datos iniciales
  Future<void> _cargarDatos() async {
    _cargando = true;
    notifyListeners();

    try {
      _historial = await _repository.obtenerHistorial();
      _ventasDelDia = await _repository.obtenerVentasDelDia();
      _resumenFormaPago = await _repository.obtenerResumenPorFormaPago();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Verifica si la impresora está disponible
  Future<void> _verificarImpresora() async {
    _impresoraDisponible = await _repository.verificarImpresora();
    notifyListeners();
  }

  /// Recarga los datos
  Future<void> recargar() async {
    await _cargarDatos();
    await _verificarImpresora();
  }

  /// Genera y opcionalmente imprime un ticket
  Future<Ticket?> generarTicket({
    required Pedido pedido,
    required FormaPago formaPago,
    double? montoRecibido,
    bool imprimir = true,
  }) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final ticket = await _repository.generarTicket(
        pedido: pedido,
        formaPago: formaPago,
        montoRecibido: montoRecibido,
      );

      if (imprimir) {
        await _repository.imprimirTicket(ticket);
      }

      // Actualizar datos
      await _cargarDatos();

      return ticket;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Reimprime un ticket existente
  Future<bool> reimprimirTicket(String folio) async {
    try {
      final ticket = await _repository.obtenerTicketPorFolio(folio);
      if (ticket == null) {
        _error = 'Ticket no encontrado: $folio';
        notifyListeners();
        return false;
      }

      return await _repository.imprimirTicket(ticket);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Configura la impresora
  Future<void> configurarImpresora(String nombreImpresora) async {
    await _printer.configurar(nombreImpresora);
    await _verificarImpresora();
  }

  /// Lista las impresoras disponibles
  Future<List<String>> listarImpresoras() async {
    return await _printer.listarImpresoras();
  }

  /// Realiza una prueba de impresión
  Future<bool> pruebaImpresion() async {
    return await _printer.pruebaImpresion();
  }

  /// Abre el cajón de dinero
  Future<bool> abrirCajon() async {
    return await _printer.abrirCajon();
  }

  /// Obtiene historial filtrado por fechas
  Future<List<Ticket>> obtenerHistorialFiltrado({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    return await _repository.obtenerHistorial(desde: desde, hasta: hasta);
  }

  /// Limpia el error
  void limpiarError() {
    _error = null;
    notifyListeners();
  }
}
