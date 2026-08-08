import 'package:flutter/material.dart';

import '../../../../core/models/pedido.dart';

/// Diálogo de solo lectura: platos ya pedidos de la mesa (app móvil).
class DialogoConsumoActualLectura {
  DialogoConsumoActualLectura._();

  static Future<void> mostrar({
    required BuildContext context,
    required int mesaNumero,
    required List<Pedido> pedidos,
  }) {
    final items = <ItemPedido>[];
    for (final pedido in pedidos) {
      items.addAll(pedido.items);
    }

    // Agrupar por nombre + precio para mostrar cantidades acumuladas
    final agrupados = <String, ({String nombre, int cantidad, double precio})>{};
    for (final item in items) {
      final key = '${item.nombreProducto}|${item.precioUnitario}';
      final prev = agrupados[key];
      if (prev == null) {
        agrupados[key] = (
          nombre: item.nombreProducto,
          cantidad: item.cantidad,
          precio: item.precioUnitario,
        );
      } else {
        agrupados[key] = (
          nombre: prev.nombre,
          cantidad: prev.cantidad + item.cantidad,
          precio: prev.precio,
        );
      }
    }
    final lineas = agrupados.values.toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));

    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: Color(0xFF00D9A5)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Consumo actual · Mesa $mesaNumero',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: lineas.isEmpty
              ? const Text(
                  'No hay platos en la cuenta.',
                  style: TextStyle(color: Colors.white70),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: lineas.length,
                  separatorBuilder: (_, __) => Divider(
                    color: Colors.white.withValues(alpha: 0.1),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final linea = lineas[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            constraints: const BoxConstraints(minWidth: 28),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE94560).withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${linea.cantidad}×',
                              style: const TextStyle(
                                color: Color(0xFFE94560),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              linea.nombre,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00D9A5),
              foregroundColor: Colors.black87,
            ),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
