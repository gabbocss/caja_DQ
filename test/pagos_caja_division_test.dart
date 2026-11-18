import 'package:flutter_test/flutter_test.dart';
import 'package:programa_caja/features/caja/domain/agregacion_cobros.dart';
import 'package:programa_caja/features/pedidos/domain/division_cuenta.dart';

import 'helpers/pagos_test_helpers.dart';

void main() {
  group('DivisionCuenta — personas originales', () {
    test('prioriza Buffet - Adulto sobre cubiertos', () {
      final n = DivisionCuenta.personasOriginalesDesdeItems(
        items: [
          (nombre: 'Cubiertos', cantidad: 5),
          (nombre: 'Buffet - Adulto', cantidad: 3),
          (nombre: 'Buffet - Niño', cantidad: 2),
        ],
      );
      expect(n, 3); // niños no cuentan
    });

    test('usa cubiertos si no hay buffet adulto', () {
      final n = DivisionCuenta.personasOriginalesDesdeItems(
        items: [
          (nombre: 'Cubiertos', cantidad: 4),
          (nombre: 'Paella', cantidad: 2),
        ],
      );
      expect(n, 4);
    });

    test('suma varias líneas de cubiertos / adultos', () {
      expect(
        DivisionCuenta.personasOriginalesDesdeItems(
          items: [
            (nombre: 'Cubiertos', cantidad: 2),
            (nombre: 'Cubiertos', cantidad: 2),
          ],
        ),
        4,
      );
      expect(
        DivisionCuenta.personasOriginalesDesdeItems(
          items: [
            (nombre: 'Buffet - Adulto', cantidad: 1),
            (nombre: 'Buffet - Adulto', cantidad: 2),
          ],
        ),
        3,
      );
    });

    test('fallback a locales y comensales', () {
      expect(
        DivisionCuenta.personasOriginalesDesdeItems(
          items: [(nombre: 'Café', cantidad: 1)],
          adultosBuffetLocal: 2,
        ),
        2,
      );
      expect(
        DivisionCuenta.personasOriginalesDesdeItems(
          items: [(nombre: 'Café', cantidad: 1)],
          cubiertosLocal: 6,
        ),
        6,
      );
      expect(
        DivisionCuenta.personasOriginalesDesdeItems(
          items: [(nombre: 'Café', cantidad: 1)],
          numeroComensalesMax: 3,
        ),
        3,
      );
      expect(
        DivisionCuenta.personasOriginalesDesdeItems(
          items: [(nombre: 'Café', cantidad: 1)],
        ),
        1,
      );
    });
  });

  group('DivisionCuenta — cuotas y personas restantes', () {
    test('mesa de 3: una cuota baja a 2; otra a 1; total cierra', () {
      const total = 300.0;
      var personas = 3;
      var pendiente = total;

      // Persona 1 paga cuota
      final p1 = DivisionCuenta.partePorPersona(pendiente, personas);
      expectCasi(p1, 100);
      expect(
        DivisionCuenta.esImporteCuota(importeCobrado: 100, partePorPersona: p1),
        isTrue,
      );
      personas = DivisionCuenta.personasTrasCobro(
        importeCobrado: 100,
        partePorPersona: p1,
        personasAntes: personas,
      );
      expect(personas, 2);
      pendiente = 200;

      // Persona 2
      final p2 = DivisionCuenta.partePorPersona(pendiente, personas);
      expectCasi(p2, 100);
      personas = DivisionCuenta.personasTrasCobro(
        importeCobrado: 100,
        partePorPersona: p2,
        personasAntes: personas,
      );
      expect(personas, 1);
      pendiente = 100;

      // Última cierra
      final p3 = DivisionCuenta.partePorPersona(pendiente, personas);
      expectCasi(p3, 100);
      personas = DivisionCuenta.personasTrasCobro(
        importeCobrado: 100,
        partePorPersona: p3,
        personasAntes: personas,
      );
      expect(personas, 1); // mínimo 1
    });

    test('tras cuota, nuevo pedido: se divide lo pendiente entre restantes', () {
      var personas = 3;
      var pendiente = 300.0;

      final cuota = DivisionCuenta.partePorPersona(pendiente, personas);
      personas = DivisionCuenta.personasTrasCobro(
        importeCobrado: cuota,
        partePorPersona: cuota,
        personasAntes: personas,
      );
      pendiente = 200;

      // Siguen comiendo: +40
      pendiente += 40; // 240 entre 2
      expect(personas, 2);
      expectCasi(DivisionCuenta.partePorPersona(pendiente, personas), 120);
    });

    test('pago parcial que NO es cuota no baja personas', () {
      final personas = DivisionCuenta.personasTrasCobro(
        importeCobrado: 50,
        partePorPersona: 100,
        personasAntes: 3,
      );
      expect(personas, 3);
    });

    test('mesa de 4 quiere dividir en 2 (manual) y paga cuota', () {
      const pendiente = 200.0;
      const personasManual = 2;
      final parte = DivisionCuenta.partePorPersona(pendiente, personasManual);
      expectCasi(parte, 100);
      final restantes = DivisionCuenta.personasTrasCobro(
        importeCobrado: 100,
        partePorPersona: parte,
        personasAntes: personasManual,
      );
      expect(restantes, 1);
    });

    test('personasParaDividir respeta guardadas', () {
      expect(
        DivisionCuenta.personasParaDividir(
          originales: 4,
          restantesGuardadas: 2,
        ),
        2,
      );
      expect(
        DivisionCuenta.personasParaDividir(
          originales: 4,
          restantesGuardadas: null,
        ),
        4,
      );
    });

    test('tolerancia de redondeo en cuota (±0.05)', () {
      expect(
        DivisionCuenta.esImporteCuota(
          importeCobrado: 33.33,
          partePorPersona: 33.333333,
        ),
        isTrue,
      );
      expect(
        DivisionCuenta.esImporteCuota(
          importeCobrado: 33.20,
          partePorPersona: 33.33,
        ),
        isFalse,
      );
    });
  });

  group('División + aplicarPagoSobreCuenta (flujo real de cuenta)', () {
    test('3 cuotas mixtas cierran 287€ y cuadran cobrado', () {
      final cuenta = [pedidoCon(precio: 287, cantidad: 1)];
      var personas = 3;
      var pendiente = pendienteTotal(cuenta);

      for (var i = 0; i < 2; i++) {
        final parte = DivisionCuenta.partePorPersona(pendiente, personas);
        final metodo = i == 0 ? 'efectivo' : 'tarjeta';
        expect(metodo, isNotEmpty);
        expectCasi(aplicarPagoSobreCuenta(cuenta, parte), pendiente - parte);
        personas = DivisionCuenta.personasTrasCobro(
          importeCobrado: parte,
          partePorPersona: parte,
          personasAntes: personas,
        );
        pendiente = pendienteTotal(cuenta);
      }

      expect(personas, 1);
      expectCasi(pendiente, 287 / 3, eps: 0.02);
      expectCasi(aplicarPagoSobreCuenta(cuenta, pendiente), 0);
      expectCasi(cobradoTotal(cuenta), 287);
    });

    test('cuota + más platos + 2 restantes cierran', () {
      final t0 = DateTime(2026, 3, 1, 20);
      final cuenta = [pedidoCon(precio: 90, cantidad: 1, fecha: t0)];
      var personas = 3;

      final c1 = DivisionCuenta.partePorPersona(90, 3); // 30
      aplicarPagoSobreCuenta(cuenta, c1);
      personas = DivisionCuenta.personasTrasCobro(
        importeCobrado: c1,
        partePorPersona: c1,
        personasAntes: personas,
      );
      expect(personas, 2);

      cuenta.add(
        pedidoCon(
          precio: 20,
          cantidad: 1,
          fecha: t0.add(const Duration(minutes: 15)),
          nombre: 'Postre',
        ),
      );
      // pendiente 60+20=80 → /2 = 40
      expectCasi(pendienteTotal(cuenta), 80);
      final c2 = DivisionCuenta.partePorPersona(80, 2);
      expectCasi(c2, 40);
      aplicarPagoSobreCuenta(cuenta, c2);
      personas = DivisionCuenta.personasTrasCobro(
        importeCobrado: c2,
        partePorPersona: c2,
        personasAntes: personas,
      );
      expect(personas, 1);
      expectCasi(aplicarPagoSobreCuenta(cuenta, pendienteTotal(cuenta)), 0);
      expectCasi(cobradoTotal(cuenta), 110);
    });
  });

  group('Caja — agregación y combinaciones de métodos', () {
    const metodos = ['efectivo', 'tarjeta', 'otros'];

    test('tarjeta no entra en el cajón; efectivo y otros sí', () {
      final totales = AgregacionCobros.totalesPorMetodo([
        (metodo: 'efectivo', importeCobrado: 40),
        (metodo: 'tarjeta', importeCobrado: 100),
        (metodo: 'otros', importeCobrado: 25),
      ]);
      expectCasi(totales['efectivo']!, 40);
      expectCasi(totales['tarjeta']!, 100);
      expectCasi(totales['otros']!, 25);
      expectCasi(AgregacionCobros.cobrosQueEntranEnCaja(totales), 65);
      expectCasi(
        AgregacionCobros.totalEsperadoCaja(
          fondoInicial: 150,
          totalesPorMetodo: totales,
          totalRetiros: 20,
        ),
        195, // 150+40+25-20
      );
    });

    test('parciales de la misma mesa suman en caja por método', () {
      final regs = <({String metodo, double importeCobrado})>[
        (metodo: 'efectivo', importeCobrado: 33.33),
        (metodo: 'efectivo', importeCobrado: 33.33),
        (metodo: 'tarjeta', importeCobrado: 33.34),
      ];
      final t = AgregacionCobros.totalesPorMetodo(regs);
      expectCasi(t['efectivo']!, 66.66);
      expectCasi(t['tarjeta']!, 33.34);
      expectCasi(AgregacionCobros.cobrosQueEntranEnCaja(t), 66.66);
    });

    test('todas las secuencias de 2 métodos: pendiente 0 y caja coherente', () {
      for (final a in metodos) {
        for (final b in metodos) {
          final cuenta = [pedidoCon(precio: 100, cantidad: 1)];
          final regs = <({String metodo, double importeCobrado})>[];

          aplicarPagoSobreCuenta(cuenta, 60);
          regs.add((metodo: a, importeCobrado: 60));
          aplicarPagoSobreCuenta(cuenta, 40);
          regs.add((metodo: b, importeCobrado: 40));

          expectCasi(pendienteTotal(cuenta), 0);
          expectCasi(cobradoTotal(cuenta), 100);

          final t = AgregacionCobros.totalesPorMetodo(regs);
          final sumaMetodos =
              (t['efectivo']! + t['tarjeta']! + t['otros']!);
          expectCasi(sumaMetodos, 100);

          final enCaja = AgregacionCobros.cobrosQueEntranEnCaja(t);
          final esperadoTarjeta = (a == 'tarjeta' ? 60.0 : 0.0) +
              (b == 'tarjeta' ? 40.0 : 0.0);
          expectCasi(enCaja, 100.0 - esperadoTarjeta);
        }
      }
    });

    test('todas las ternas A→B→C con cuotas 30+30+30', () {
      for (final a in metodos) {
        for (final b in metodos) {
          for (final c in metodos) {
            final cuenta = [pedidoCon(precio: 90, cantidad: 1)];
            final regs = <({String metodo, double importeCobrado})>[];
            var personas = 3;
            var pendiente = 90.0;

            for (final m in [a, b, c]) {
              final parte =
                  DivisionCuenta.partePorPersona(pendiente, personas);
              aplicarPagoSobreCuenta(cuenta, parte);
              regs.add((metodo: m, importeCobrado: parte));
              personas = DivisionCuenta.personasTrasCobro(
                importeCobrado: parte,
                partePorPersona: parte,
                personasAntes: personas,
              );
              pendiente = pendienteTotal(cuenta);
            }

            expectCasi(pendienteTotal(cuenta), 0);
            expectCasi(cobradoTotal(cuenta), 90);
            final t = AgregacionCobros.totalesPorMetodo(regs);
            expectCasi(
              t['efectivo']! + t['tarjeta']! + t['otros']!,
              90,
            );
            // Etiqueta de traza
            expect('$a->$b->$c', isNotEmpty);
          }
        }
      }
    });

    test('vuelto: en caja solo cuenta importeCobrado, no lo recibido', () {
      // Cliente da 50€ por una cuenta de 42€ en efectivo (total)
      final t = AgregacionCobros.totalesPorMetodo([
        (metodo: 'efectivo', importeCobrado: 42),
      ]);
      expectCasi(
        AgregacionCobros.totalEsperadoCaja(
          fondoInicial: 100,
          totalesPorMetodo: t,
          totalRetiros: 0,
        ),
        142,
      );
    });

    test('retiro reduce el esperado; tarjeta no lo compensa', () {
      final t = AgregacionCobros.totalesPorMetodo([
        (metodo: 'efectivo', importeCobrado: 80),
        (metodo: 'tarjeta', importeCobrado: 200),
        (metodo: 'otros', importeCobrado: 20),
      ]);
      expectCasi(
        AgregacionCobros.totalEsperadoCaja(
          fondoInicial: 200,
          totalesPorMetodo: t,
          totalRetiros: 50,
        ),
        250, // 200+80+20-50
      );
    });

    test('matriz: cuota mixtas en mesa 3 + cierre caja esperado', () {
      // Escenario: 3 personas, 150€. Cuotas: efectivo, tarjeta, otros.
      final cuenta = [pedidoCon(precio: 150, cantidad: 1)];
      final regs = <({String metodo, double importeCobrado})>[];
      var personas = 3;
      var pendiente = 150.0;
      const secuencia = ['efectivo', 'tarjeta', 'otros'];

      for (final m in secuencia) {
        final parte = DivisionCuenta.partePorPersona(pendiente, personas);
        aplicarPagoSobreCuenta(cuenta, parte);
        regs.add((metodo: m, importeCobrado: parte));
        personas = DivisionCuenta.personasTrasCobro(
          importeCobrado: parte,
          partePorPersona: parte,
          personasAntes: personas,
        );
        pendiente = pendienteTotal(cuenta);
      }

      expectCasi(pendiente, 0);
      final t = AgregacionCobros.totalesPorMetodo(regs);
      expectCasi(t['efectivo']!, 50);
      expectCasi(t['tarjeta']!, 50);
      expectCasi(t['otros']!, 50);
      expectCasi(AgregacionCobros.cobrosQueEntranEnCaja(t), 100);
      expectCasi(
        AgregacionCobros.totalEsperadoCaja(
          fondoInicial: 300,
          totalesPorMetodo: t,
          totalRetiros: 0,
        ),
        400,
      );
    });
  });

  group('Caja — coherencia cobrado cuenta vs registros', () {
    test('suma registros = cobrado cuenta en todas parejas método', () {
      const metodos = ['efectivo', 'tarjeta', 'otros'];
      for (final a in metodos) {
        for (final b in metodos) {
          for (final c in metodos) {
            // Tres pagos irregulares
            final importes = [12.5, 7.25, 30.25]; // 50
            final cuenta = [pedidoCon(precio: 50, cantidad: 1)];
            final regs = <({String metodo, double importeCobrado})>[];
            final seq = [a, b, c];
            for (var i = 0; i < 3; i++) {
              aplicarPagoSobreCuenta(cuenta, importes[i]);
              regs.add((metodo: seq[i], importeCobrado: importes[i]));
            }
            expectCasi(cobradoTotal(cuenta), 50);
            final t = AgregacionCobros.totalesPorMetodo(regs);
            expectCasi(
              t['efectivo']! + t['tarjeta']! + t['otros']!,
              cobradoTotal(cuenta),
            );
          }
        }
      }
    });
  });
}
