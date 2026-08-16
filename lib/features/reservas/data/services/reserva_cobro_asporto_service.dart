import 'package:flutter/foundation.dart';

import '../../../../core/core.dart';
import '../../../../core/services/registro_pago_service.dart';
import '../../../../core/services/reserva_persistence_service.dart';
import '../../../../core/prefs/reservas_central_prefs.dart';

/// Cobro de asporto: registro de caja + ticket de cuenta + estado cobrada.
class ReservaCobroAsportoService {
  static final ReservaCobroAsportoService instance =
      ReservaCobroAsportoService._();
  ReservaCobroAsportoService._();

  final _persistencia = ReservaPersistenceService.instance;

  /// Cobra el total de la reserva asporto (pago completo).
  Future<void> cobrar({
    required Reserva reserva,
    required String metodo,
    double? importeRecibido,
  }) async {
    if (reserva.id == null) {
      throw StateError('La reserva debe tener id');
    }
    if (reserva.numeroPersonas > 0) {
      throw StateError('Solo se pueden cobrar reservas asporto (0 cubiertos)');
    }
    if (!reserva.estaPendiente) {
      throw StateError('Solo se cobran asportos pendientes');
    }
    if (reserva.itemsReservados.isEmpty) {
      throw StateError('No hay productos para cobrar');
    }

    final total = reserva.totalItemsReservados;
    if (total <= 0) {
      throw StateError('El total a cobrar debe ser mayor que cero');
    }

    final vuelto = importeRecibido != null
        ? (importeRecibido - total).clamp(0, double.infinity).toDouble()
        : null;

    // mesaNumero 0 = asporto (sin mesa física); entra en el arqueo de caja.
    await RegistroPagoService.instance.registrar(
      RegistroPago(
        fecha: DateTime.now(),
        mesaNumero: 0,
        metodo: metodo,
        importeCobrado: total,
        esParcial: false,
        importeRecibido: importeRecibido,
        vuelto: vuelto,
        pendienteRestante: 0,
        cerrado: true,
      ),
    );

    final itemsPedido = reserva.itemsReservados
        .map(
          (i) => ItemPedido.crear(
            productoId: i.productoId,
            nombreProducto: i.nombreProducto,
            precioUnitario: i.precioUnitario,
            cantidad: i.cantidad,
          ),
        )
        .toList();

    try {
      await ImprimirPedidoService.instance.imprimirTicketCuentaMesa(
        0,
        itemsPedido,
        total,
        etiquetaCabecera: 'CUENTA ASPORTO',
      );
    } catch (e, st) {
      debugPrint('Cobro asporto registrado; error al imprimir cuenta: $e\n$st');
    }

    reserva.estado = EstadoReserva.cobrada;
    reserva.fechaActualizacion = DateTime.now();
    await _persistencia.guardarReserva(reserva);

    await _notificarRemotaCobrada(reserva.id!);
  }

  Future<void> _notificarRemotaCobrada(int reservaId) async {
    final url = await getReservasCentralUrlEfectiva();
    if (url == null || url.isEmpty) return;
    try {
      final client = ApiClient(url);
      await client.actualizarEstadoReserva(
        id: reservaId,
        estado: EstadoReserva.cobrada,
      );
      client.dispose();
    } catch (e, st) {
      debugPrint(
        'Asporto cobrado en local; no se pudo sincronizar remoto: $e\n$st',
      );
    }
  }
}
