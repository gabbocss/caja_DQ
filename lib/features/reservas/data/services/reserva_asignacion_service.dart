import 'package:flutter/foundation.dart';

import '../../../../core/core.dart';
import '../../../../core/prefs/reservas_central_prefs.dart';
import '../../../../core/services/registro_pago_service.dart';
import '../../../../core/services/reserva_persistence_service.dart';

/// Asignación atómica: mesa + pedido + impresión + estado sentada.
class ReservaAsignacionService {
  static final ReservaAsignacionService instance = ReservaAsignacionService._();
  ReservaAsignacionService._();

  final _persistencia = ReservaPersistenceService.instance;

  /// Abre la mesa, crea pedido con menús de buffet o cubiertos e ítems reservados,
  /// imprime y marca sentada.
  ///
  /// En horario de buffet: N menús «Buffet - Adulto» (no cubiertos).
  /// Fuera de horario: N cubiertos, como hasta ahora.
  Future<void> asignarMesa({
    required Reserva reserva,
    required int mesaNumero,
  }) async {
    if (reserva.id == null) {
      throw StateError('La reserva debe tener id antes de asignar mesa');
    }
    if (!reserva.estaPendiente) {
      throw StateError('Solo se pueden asignar reservas pendientes');
    }

    final db = DatabaseService.instance;
    final config = await db.obtenerConfiguracionBuffetActiva();
    final esBuffet = config?.esHorarioBuffet() ?? false;

    // Platos pre-reservados: precio actual del desktop, no el del móvil.
    await db.asignarPreciosOficialesAItemsReserva(reserva.itemsReservados);

    final itemsPedido = <ItemPedido>[
      if (esBuffet)
        ItemPedido.crear(
          productoId: 0,
          nombreProducto: 'Buffet - Adulto',
          precioUnitario: _precioBuffetAdulto(config),
          cantidad: reserva.numeroPersonas,
        )
      else
        ItemPedido.crear(
          productoId: 0,
          nombreProducto: 'Cubiertos',
          precioUnitario: config?.precioCubierto ?? 2.0,
          cantidad: reserva.numeroPersonas,
        ),
    ];

    for (final item in reserva.itemsReservados) {
      int? destinoId;
      String? nombreDestino;
      if (item.productoId > 0) {
        final producto = await db.obtenerProductoPorId(item.productoId);
        destinoId = producto?.destinoId;
        if (destinoId != null) {
          final destino = await db.obtenerDestinoPorId(destinoId);
          nombreDestino = destino?.nombre;
        }
      }
      itemsPedido.add(
        ItemPedido.crear(
          productoId: item.productoId,
          nombreProducto: item.nombreProducto,
          precioUnitario: item.precioUnitario,
          cantidad: item.cantidad,
          destinoId: destinoId,
          nombreDestino: nombreDestino,
        ),
      );
    }

    final pedido = Pedido.crear(
      mesaNumero: mesaNumero,
      usuarioCamarero: 'Reserva',
      items: itemsPedido,
      esBuffet: esBuffet,
      numeroComensales: reserva.numeroPersonas,
      notas: reserva.alergiasNotas.isEmpty ? null : reserva.alergiasNotas,
      // Enlace CRM / analítica (fase 2).
      reservaId: reserva.id,
      clienteId: reserva.clienteId,
    );
    pedido.calcularTotal();

    await db.guardarPedido(pedido);
    await db.actualizarEstadoMesa(mesaNumero, EstadoMesa.ocupada);

    await ImprimirPedidoService.instance.imprimirTicketReservaCocina(
      mesaNumero: mesaNumero,
      reserva: reserva,
    );

    reserva.estado = EstadoReserva.sentada;
    reserva.mesaAsignada = mesaNumero;
    await _persistencia.guardarReserva(reserva);

    await _notificarRemotaSentada(reserva.id!, mesaNumero);
  }

  /// Mueve una reserva ya sentada (y su cuenta abierta) a otra mesa libre.
  /// No reimprime cocina ni crea cubiertos/platos nuevos.
  Future<void> cambiarMesa({
    required Reserva reserva,
    required int mesaNueva,
  }) async {
    if (reserva.id == null) {
      throw StateError('La reserva debe tener id antes de cambiar de mesa');
    }
    if (reserva.estado != EstadoReserva.sentada) {
      throw StateError('Solo se puede cambiar mesa de una reserva sentada');
    }
    final mesaOrigen = reserva.mesaAsignada;
    if (mesaOrigen == null) {
      throw StateError('La reserva no tiene mesa asignada');
    }
    if (mesaOrigen == mesaNueva) {
      throw StateError('La mesa de destino debe ser distinta a la actual');
    }

    final db = DatabaseService.instance;

    // Evitar dos reservas sentadas en la misma mesa.
    final delDia = await _persistencia.obtenerReservasDelDia(
      reserva.fechaHoraLlegada,
    );
    final conflicto = delDia.any(
      (r) =>
          r.id != reserva.id &&
          r.estado == EstadoReserva.sentada &&
          r.mesaAsignada == mesaNueva,
    );
    if (conflicto) {
      throw StateError(
        'Ya hay otra reserva sentada en la mesa $mesaNueva',
      );
    }

    await db.moverCuentaEntreMesas(
      mesaOrigen: mesaOrigen,
      mesaDestino: mesaNueva,
    );

    await RegistroPagoService.instance.reasignarPagosMesa(
      mesaOrigen,
      mesaNueva,
    );

    reserva.mesaAsignada = mesaNueva;
    await _persistencia.guardarReserva(reserva);

    await _notificarRemotaSentada(reserva.id!, mesaNueva);
  }

  double _precioBuffetAdulto(ConfiguracionBuffet? config) {
    final precio = config?.precioAdulto ?? 18.0;
    if (precio.isNaN || precio < 0) return 18.0;
    return precio;
  }

  Future<void> _notificarRemotaSentada(int reservaId, int mesaNumero) async {
    final url = await getReservasCentralUrlEfectiva();
    if (url == null || url.isEmpty) return;
    try {
      final client = ApiClient(url);
      await client.actualizarEstadoReserva(
        id: reservaId,
        estado: EstadoReserva.sentada,
        mesaAsignada: mesaNumero,
      );
      client.dispose();
    } catch (e, st) {
      debugPrint(
        'Reserva sentada en local; no se pudo sincronizar con servidor remoto: $e\n$st',
      );
    }
  }
}
