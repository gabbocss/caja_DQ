import 'package:flutter_test/flutter_test.dart';
import 'package:programa_caja/core/services/registro_pago_service.dart';
import 'package:programa_caja/features/caja/domain/entities/conteo_efectivo.dart';
import 'package:programa_caja/features/caja/domain/entities/retiro_caja.dart';
import 'package:programa_caja/features/caja/domain/entities/sesion_caja.dart';
import 'package:programa_caja/features/caja/domain/log_movimientos_caja.dart';

void main() {
  test('log incluye apertura, cobros, retiro y cierre en orden', () {
    final abierta = DateTime(2026, 3, 19, 10, 0);
    final sesion = SesionCaja(
      id: 's1',
      abiertaEn: abierta,
      fondoInicial: const ConteoEfectivo({'50.0': 2}),
      retiros: [
        RetiroCaja(
          id: 'r1',
          fecha: DateTime(2026, 3, 19, 14, 0),
          importe: 20,
          motivo: 'Cambio',
        ),
      ],
    );

    final cobros = [
      RegistroPago(
        fecha: DateTime(2026, 3, 19, 11, 0),
        mesaNumero: 3,
        metodo: 'efectivo',
        importeCobrado: 40,
        esParcial: false,
        sesionCajaId: 's1',
      ),
      RegistroPago(
        fecha: DateTime(2026, 3, 19, 12, 30),
        mesaNumero: 5,
        metodo: 'tarjeta',
        importeCobrado: 55,
        esParcial: true,
        sesionCajaId: 's1',
      ),
    ];

    final log = LogMovimientosCaja.construir(
      sesion: sesion,
      cobros: cobros,
      conteoFisico: const ConteoEfectivo({'50.0': 2, '20.0': 1}),
      totalEsperado: 120,
      diferencia: 0,
      cuadra: true,
      cerradoEn: DateTime(2026, 3, 19, 23, 0),
    );

    expect(log.map((m) => m.tipo).toList(), [
      'apertura',
      'cobro',
      'cobro',
      'retiro',
      'cierre',
    ]);
    expect(log.first.importe, 100); // 2x50
    expect(log[1].mesaNumero, 3);
    expect(log[2].descripcion, contains('no entra en cajón'));
    expect(log[3].importe, -20);
    expect(log.last.tipo, 'cierre');
  });
}
