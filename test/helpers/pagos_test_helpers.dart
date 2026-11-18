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
