import 'package:flutter/foundation.dart';

import '../../../../core/core.dart';
import '../../../../core/prefs/reservas_central_prefs.dart';
import '../../../../core/services/reserva_persistence_service.dart';

/// Asignación atómica: mesa + pedido + impresión + estado sentada.
class ReservaAsignacionService {
  static final ReservaAsignacionService instance = ReservaAsignacionService._();
  ReservaAsignacionService._();

  final _persistencia = ReservaPersistenceService.instance;

  /// Abre la mesa, crea pedido con cubiertos e ítems reservados, imprime y marca sentada.
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
    final precioCubierto = config?.precioCubierto ?? 2.0;

    final itemsPedido = <ItemPedido>[
      ItemPedido.crear(
        productoId: 0,
        nombreProducto: 'Cubiertos',
        precioUnitario: precioCubierto,
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
      numeroComensales: reserva.numeroPersonas,
      notas: reserva.alergiasNotas.isEmpty ? null : reserva.alergiasNotas,
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
