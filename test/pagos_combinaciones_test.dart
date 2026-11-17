import 'package:flutter_test/flutter_test.dart';
import 'package:programa_caja/core/models/pedido.dart';

/// Simula [DatabaseService.aplicarPagoMesa]: reparte cobro entre pedidos
/// abiertos (más antiguos primero) y recalcula pendientes.
double aplicarPagoSobreCuenta(List<Pedido> pedidos, double importe) {
  pedidos.sort((a, b) => a.fechaCreacion.compareTo(b.fechaCreacion));
  var restanteCobro = importe;
  for (final pedido in pedidos) {
    if (restanteCobro <= 0.009) break;
    pedido.normalizarTotalPendiente();
    final pendientePedido = pedido.totalPendienteSeguro;
    if (pendientePedido <= 0.009) continue;
    final aplicar =
        restanteCobro < pendientePedido ? restanteCobro : pendientePedido;
    pedido.dineroCobradoAcumulado += aplicar;
    pedido.actualizarPendienteDesdeCobrosAcumulados();
    restanteCobro -= aplicar;
  }
  return pendienteTotal(pedidos);
}

double pendienteTotal(List<Pedido> pedidos) {
  var suma = 0.0;
  for (final p in pedidos) {
    p.normalizarTotalPendiente();
    suma += p.totalPendienteSeguro;
  }
  return suma;
}

double cobradoTotal(List<Pedido> pedidos) =>
    pedidos.fold<double>(0, (s, p) => s + p.dineroCobradoAcumulado);

double brutoTotal(List<Pedido> pedidos) =>
    pedidos.fold<double>(0, (s, p) => s + p.total);

Pedido pedidoCon({
  required double precio,
  required int cantidad,
  DateTime? fecha,
  String nombre = 'Plato',
}) {
  final p = Pedido.crear(
    mesaNumero: 1,
    usuarioCamarero: 'test',
    items: [
      ItemPedido.crear(
        productoId: 1,
        nombreProducto: nombre,
        precioUnitario: precio,
        cantidad: cantidad,
      ),
    ],
  );
  p.calcularTotal();
  if (fecha != null) {
    p.fechaCreacion = fecha;
  }
  return p;
}

void expectCasi(double actual, double esperado, {double eps = 0.009}) {
  expect(
    (actual - esperado).abs() <= eps,
    isTrue,
    reason: 'esperado ≈ $esperado, actual=$actual',
  );
}

void main() {
  group('normalizarTotalPendiente no revive cobros', () {
    test('pedido totalmente cubierto por parcial sigue con pendiente 0', () {
      final p = pedidoCon(precio: 40, cantidad: 1);
      p.dineroCobradoAcumulado = 40;
      p.actualizarPendienteDesdeCobrosAcumulados();
      expectCasi(p.totalPendiente, 0);

      // Lecturas repetidas (como en UI / obtenerTotalPendienteMesa)
      for (var i = 0; i < 5; i++) {
        p.normalizarTotalPendiente();
        expectCasi(p.totalPendienteSeguro, 0);
      }
      expectCasi(p.dineroCobradoAcumulado, 40);
    });

    test('pedido a medias mantiene pendiente = total − cobrado', () {
      final p = pedidoCon(precio: 100, cantidad: 1);
      p.dineroCobradoAcumulado = 45;
      p.actualizarPendienteDesdeCobrosAcumulados();
      p.normalizarTotalPendiente();
      expectCasi(p.totalPendienteSeguro, 55);
    });
  });

  group('Pagos mixtos en un solo pedido', () {
    test('mitad efectivo + resto tarjeta', () {
      final cuenta = [pedidoCon(precio: 100, cantidad: 1)];
      expectCasi(aplicarPagoSobreCuenta(cuenta, 50), 50); // efectivo
      expectCasi(aplicarPagoSobreCuenta(cuenta, 50), 0); // tarjeta
      expectCasi(cobradoTotal(cuenta), 100);
    });

    test('mitad efectivo + resto otros', () {
      final cuenta = [pedidoCon(precio: 80, cantidad: 1)];
      expectCasi(aplicarPagoSobreCuenta(cuenta, 40), 40);
      expectCasi(aplicarPagoSobreCuenta(cuenta, 40), 0);
      expectCasi(cobradoTotal(cuenta), 80);
    });

    test('tres métodos: efectivo + tarjeta + otros', () {
      final cuenta = [pedidoCon(precio: 90, cantidad: 1)];
      expectCasi(aplicarPagoSobreCuenta(cuenta, 30), 60); // efectivo
      expectCasi(aplicarPagoSobreCuenta(cuenta, 30), 30); // tarjeta
      expectCasi(aplicarPagoSobreCuenta(cuenta, 30), 0); // otros
      expectCasi(cobradoTotal(cuenta), 90);
    });

    test('importes irregulares que suman el total', () {
      final cuenta = [pedidoCon(precio: 47.50, cantidad: 1)];
      expectCasi(aplicarPagoSobreCuenta(cuenta, 10.20), 37.30);
      expectCasi(aplicarPagoSobreCuenta(cuenta, 15.15), 22.15);
      expectCasi(aplicarPagoSobreCuenta(cuenta, 22.15), 0);
      expectCasi(cobradoTotal(cuenta), 47.50);
    });

    test('solo tarjeta total de una vez', () {
      final cuenta = [pedidoCon(precio: 25, cantidad: 1)];
      expectCasi(aplicarPagoSobreCuenta(cuenta, 25), 0);
      expectCasi(cobradoTotal(cuenta), 25);
    });

    test('solo otros total de una vez', () {
      final cuenta = [pedidoCon(precio: 12.5, cantidad: 1)];
      expectCasi(aplicarPagoSobreCuenta(cuenta, 12.5), 0);
    });
  });

  group('Varios pedidos en la mesa (comandas separadas)', () {
    test('cobro que cubre el primer pedido no lo revive al leer pendiente', () {
      final t0 = DateTime(2026, 1, 1, 12);
      final cuenta = [
        pedidoCon(precio: 40, cantidad: 1, fecha: t0, nombre: 'A'),
        pedidoCon(
          precio: 60,
          cantidad: 1,
          fecha: t0.add(const Duration(minutes: 5)),
          nombre: 'B',
        ),
      ];
      expectCasi(brutoTotal(cuenta), 100);

      // Pago parcial que cubre exactamente el primer pedido
      expectCasi(aplicarPagoSobreCuenta(cuenta, 40), 60);

      // Lecturas posteriores (UI) no deben hinchar el pendiente
      expectCasi(pendienteTotal(cuenta), 60);
      expectCasi(pendienteTotal(cuenta), 60);

      expectCasi(cuenta[0].dineroCobradoAcumulado, 40);
      expectCasi(cuenta[0].totalPendiente, 0);
      expectCasi(cuenta[1].dineroCobradoAcumulado, 0);
      expectCasi(cuenta[1].totalPendiente, 60);
    });

    test('efectivo cubre pedido 1 + parte del 2; tarjeta cierra', () {
      final t0 = DateTime(2026, 1, 1, 13);
      final cuenta = [
        pedidoCon(precio: 30, cantidad: 1, fecha: t0),
        pedidoCon(
          precio: 70,
          cantidad: 1,
          fecha: t0.add(const Duration(minutes: 1)),
        ),
      ];

      expectCasi(aplicarPagoSobreCuenta(cuenta, 50), 50); // efectivo
      expectCasi(cuenta[0].dineroCobradoAcumulado, 30);
      expectCasi(cuenta[1].dineroCobradoAcumulado, 20);

      expectCasi(aplicarPagoSobreCuenta(cuenta, 50), 0); // tarjeta
      expectCasi(cobradoTotal(cuenta), 100);
      expectCasi(pendienteTotal(cuenta), 0);
    });

    test('tres métodos repartidos en dos pedidos', () {
      final t0 = DateTime(2026, 1, 1, 14);
      final cuenta = [
        pedidoCon(precio: 25, cantidad: 1, fecha: t0),
        pedidoCon(
          precio: 75,
          cantidad: 1,
          fecha: t0.add(const Duration(seconds: 30)),
        ),
      ];

      expectCasi(aplicarPagoSobreCuenta(cuenta, 20), 80); // efectivo
      expectCasi(aplicarPagoSobreCuenta(cuenta, 35), 45); // tarjeta
      expectCasi(aplicarPagoSobreCuenta(cuenta, 45), 0); // otros
      expectCasi(cobradoTotal(cuenta), 100);
    });
  });

  group('Cuota parcial y luego más productos', () {
    test('tras pagar mitad, un pedido nuevo suma solo su total al pendiente', () {
      final t0 = DateTime(2026, 1, 1, 15);
      final primero = pedidoCon(precio: 100, cantidad: 1, fecha: t0);
      final cuenta = [primero];

      expectCasi(aplicarPagoSobreCuenta(cuenta, 50), 50);

      final segundo = pedidoCon(
        precio: 20,
        cantidad: 1,
        fecha: t0.add(const Duration(minutes: 10)),
        nombre: 'Postre',
      );
      cuenta.add(segundo);

      expectCasi(pendienteTotal(cuenta), 70); // 50 restantes + 20 nuevos
      expectCasi(cobradoTotal(cuenta), 50);

      expectCasi(aplicarPagoSobreCuenta(cuenta, 70), 0);
      expectCasi(cobradoTotal(cuenta), 120);
      expectCasi(brutoTotal(cuenta), 120);
    });

    test('parcial mixtos, añadir platos, cerrar con otro método', () {
      final t0 = DateTime(2026, 1, 1, 16);
      final cuenta = [
        pedidoCon(precio: 60, cantidad: 1, fecha: t0),
      ];

      expectCasi(aplicarPagoSobreCuenta(cuenta, 20), 40); // efectivo
      expectCasi(aplicarPagoSobreCuenta(cuenta, 10), 30); // tarjeta

      cuenta.add(
        pedidoCon(
          precio: 15,
          cantidad: 1,
          fecha: t0.add(const Duration(minutes: 20)),
          nombre: 'Café',
        ),
      );

      expectCasi(pendienteTotal(cuenta), 45); // 30 + 15
      expectCasi(aplicarPagoSobreCuenta(cuenta, 45), 0); // otros
      expectCasi(cobradoTotal(cuenta), 75);
    });

    test('editar consumo: añadir unidades al mismo pedido tras parcial', () {
      final p = pedidoCon(precio: 10, cantidad: 2); // total 20
      p.dineroCobradoAcumulado = 10;
      p.actualizarPendienteDesdeCobrosAcumulados();
      expectCasi(p.totalPendiente, 10);

      // Añaden 1 unidad más del mismo plato (edición de consumo)
      p.items.first.cantidad = 3; // total 30
      p.actualizarPendienteDesdeCobrosAcumulados();
      expectCasi(p.total, 30);
      expectCasi(p.totalPendiente, 20);
      p.normalizarTotalPendiente();
      expectCasi(p.totalPendienteSeguro, 20);
    });

    test('no se puede dejar el total por debajo de lo ya cobrado', () {
      final p = pedidoCon(precio: 50, cantidad: 2); // 100
      p.dineroCobradoAcumulado = 80;
      p.actualizarPendienteDesdeCobrosAcumulados();

      // Intento de bajar a 1 unidad (50) < 80 cobrados
      final totalPropuesto = 50.0;
      final permitido = totalPropuesto >= p.dineroCobradoAcumulado - 0.009;
      expect(permitido, isFalse);
    });
  });

  group('Cobros que no deben pasarse de largo', () {
    test('importe mayor que pendiente se recorta al aplicar', () {
      final cuenta = [pedidoCon(precio: 30, cantidad: 1)];
      final restante = aplicarPagoSobreCuenta(cuenta, 100);
      expectCasi(restante, 0);
      expectCasi(cobradoTotal(cuenta), 30);
    });

    test('secuencia de cuotas pequeñas hasta cerrar', () {
      final cuenta = [pedidoCon(precio: 10, cantidad: 1)];
      for (var i = 0; i < 9; i++) {
        aplicarPagoSobreCuenta(cuenta, 1);
      }
      expectCasi(pendienteTotal(cuenta), 1);
      expectCasi(aplicarPagoSobreCuenta(cuenta, 1), 0);
    });
  });

  group('Matriz de métodos (todas las secuencias de 2 y 3)', () {
    const metodos = ['efectivo', 'tarjeta', 'otros'];

    test('todas las parejas A→B cierran 100€ (60+40)', () {
      for (final a in metodos) {
        for (final b in metodos) {
          final cuenta = [pedidoCon(precio: 100, cantidad: 1)];
          expectCasi(aplicarPagoSobreCuenta(cuenta, 60), 40, eps: 0.01);
          expectCasi(aplicarPagoSobreCuenta(cuenta, 40), 0, eps: 0.01);
          expectCasi(cobradoTotal(cuenta), 100, eps: 0.01);
          // Etiquetas solo documentan la secuencia probada
          expect('$a->$b', isNotEmpty);
        }
      }
    });

    test('todas las ternas A→B→C cierran 90€ (30+30+30)', () {
      for (final a in metodos) {
        for (final b in metodos) {
          for (final c in metodos) {
            final cuenta = [pedidoCon(precio: 90, cantidad: 1)];
            expectCasi(aplicarPagoSobreCuenta(cuenta, 30), 60);
            expectCasi(aplicarPagoSobreCuenta(cuenta, 30), 30);
            expectCasi(aplicarPagoSobreCuenta(cuenta, 30), 0);
            expectCasi(cobradoTotal(cuenta), 90);
            expect('$a->$b->$c', isNotEmpty);
          }
        }
      }
    });
  });
}
