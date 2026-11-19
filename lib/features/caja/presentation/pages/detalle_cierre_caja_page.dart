import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/cierre_caja.dart';
import '../../domain/entities/movimiento_caja.dart';

/// Detalle de un cierre: totales del día y log de todos los movimientos.
class DetalleCierreCajaPage extends StatelessWidget {
  final CierreCaja cierre;

  const DetalleCierreCajaPage({super.key, required this.cierre});

  @override
  Widget build(BuildContext context) {
    final fmtDia = DateFormat('dd/MM/yyyy');
    final fmtHora = DateFormat('HH:mm:ss');
    final fmtRango = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Row(
          children: [
            Icon(Icons.receipt_long, color: Color(0xFF00D9A5)),
            SizedBox(width: 12),
            Text(
              'DETALLE DEL DÍA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Cierre del ${fmtDia.format(cierre.cerradoEn)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            cierre.abiertaEn != null
                ? '${fmtRango.format(cierre.abiertaEn!)} → ${fmtRango.format(cierre.cerradoEn)}'
                : 'Cerrado: ${fmtRango.format(cierre.cerradoEn)}',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _estadoCuadre(),
          const SizedBox(height: 16),
          _tarjetaTotales(),
          const SizedBox(height: 28),
          const Text(
            'Movimientos',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            cierre.movimientos.isEmpty
                ? 'Este cierre no tiene log (cierres antiguos).'
                : '${cierre.movimientos.length} registro(s)',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (cierre.movimientos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No hay movimientos guardados para este día.',
                style: TextStyle(color: Colors.white38),
              ),
            )
          else
            ...cierre.movimientos.map(
              (m) => _filaMovimiento(m, fmtHora),
            ),
        ],
      ),
    );
  }

  Widget _estadoCuadre() {
    final ok = cierre.cuadra;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (ok ? const Color(0xFF00D9A5) : const Color(0xFFE94560))
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (ok ? const Color(0xFF00D9A5) : const Color(0xFFE94560))
              .withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.warning_amber,
            color: ok ? const Color(0xFF00D9A5) : const Color(0xFFE94560),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ok
                  ? 'Caja cuadrada'
                  : 'Descuadre: ${cierre.diferencia.toStringAsFixed(2)} €',
              style: TextStyle(
                color: ok ? const Color(0xFF00D9A5) : const Color(0xFFE94560),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaTotales() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _fila('Fondo inicial', cierre.fondoInicial),
          _fila('Cobros efectivo', cierre.totalEfectivo, signo: '+'),
          _fila('Cobros tarjeta', cierre.totalTarjeta, signo: '+', tenue: true),
          _fila('Cobros otros', cierre.totalOtros, signo: '+'),
          _fila('Retiros', cierre.totalRetiros, signo: '-'),
          const Divider(color: Colors.white24, height: 24),
          _fila('Esperado en cajón', cierre.totalEsperado, destacado: true),
          _fila('Contado físico', cierre.conteoFisico),
          _fila(
            'Diferencia',
            cierre.diferencia,
            destacado: true,
            color: cierre.cuadra
                ? const Color(0xFF00D9A5)
                : const Color(0xFFE94560),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nota: el esperado = fondo + cobros desde la apertura '
            '(efectivo + otros) − retiros. La tarjeta no entra en el cajón. '
            'Los cobros previos a abrir ya van incluidos en el fondo.',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _fila(
    String etiqueta,
    double valor, {
    String signo = '',
    bool destacado = false,
    bool tenue = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            etiqueta,
            style: TextStyle(
              color: destacado
                  ? Colors.white
                  : (tenue ? Colors.white38 : Colors.white70),
              fontWeight: destacado ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
          Text(
            '$signo${valor.toStringAsFixed(2)} €',
            style: TextStyle(
              color: color ??
                  (destacado
                      ? const Color(0xFF00D9A5)
                      : (tenue ? Colors.white38 : Colors.white)),
              fontWeight: destacado ? FontWeight.bold : FontWeight.w600,
              fontSize: destacado ? 16 : 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaMovimiento(MovimientoCaja m, DateFormat fmtHora) {
    final color = switch (m.tipo) {
      'apertura' => const Color(0xFF00D9A5),
      'cobro' => const Color(0xFF4FC3F7),
      'retiro' => const Color(0xFFE94560),
      'cierre' => const Color(0xFFFFB347),
      _ => Colors.white54,
    };
    final icono = switch (m.tipo) {
      'apertura' => Icons.lock_open,
      'cobro' => Icons.payments,
      'retiro' => Icons.money_off,
      'cierre' => Icons.lock,
      _ => Icons.circle,
    };
    final importeTxt = m.tipo == 'cierre'
        ? '${m.importe.toStringAsFixed(2)} €'
        : '${m.importe >= 0 ? '+' : ''}${m.importe.toStringAsFixed(2)} €';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: color, width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.descripcion,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  fmtHora.format(m.fecha),
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            importeTxt,
            style: TextStyle(
              color: m.importe < 0 && m.tipo != 'cierre'
                  ? const Color(0xFFE94560)
                  : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
