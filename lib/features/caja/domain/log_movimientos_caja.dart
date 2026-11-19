import '../../../core/services/registro_pago_service.dart';
import 'entities/conteo_efectivo.dart';
import 'entities/movimiento_caja.dart';
import 'entities/sesion_caja.dart';

/// Construye el log cronológico de una sesión (sin I/O).
class LogMovimientosCaja {
  LogMovimientosCaja._();

  static List<MovimientoCaja> construir({
    required SesionCaja sesion,
    required List<RegistroPago> cobros,
    required ConteoEfectivo conteoFisico,
    required double totalEsperado,
    required double diferencia,
    required bool cuadra,
    DateTime? cerradoEn,
  }) {
    final movimientos = <MovimientoCaja>[];

    movimientos.add(
      MovimientoCaja(
        tipo: 'apertura',
        fecha: sesion.abiertaEn,
        descripcion: sesion.tieneFondoInicial
            ? 'Apertura de caja · fondo inicial'
            : 'Apertura de caja · sin fondo registrado',
        importe: sesion.totalFondoInicial,
      ),
    );

    for (final cobro in cobros) {
      final metodo = cobro.metodo.toLowerCase();
      final entraEnCajon = metodo == 'efectivo' || metodo == 'otros';
      final parcial = cobro.esParcial ? 'parcial' : 'total';
      final mesa = 'Mesa ${cobro.mesaNumero}';
      final notaVuelto = cobro.vuelto != null && cobro.vuelto! > 0.009
          ? ' · vuelto ${cobro.vuelto!.toStringAsFixed(2)} €'
          : '';
      final notaCajon = entraEnCajon ? '' : ' · no entra en cajón';

      movimientos.add(
        MovimientoCaja(
          tipo: 'cobro',
          fecha: cobro.fecha,
          descripcion: 'Cobro $parcial · $mesa · $metodo$notaVuelto$notaCajon',
          importe: cobro.importeCobrado,
          metodo: metodo,
          mesaNumero: cobro.mesaNumero,
          esParcial: cobro.esParcial,
        ),
      );
    }

    for (final retiro in sesion.retiros) {
      movimientos.add(
        MovimientoCaja(
          tipo: 'retiro',
          fecha: retiro.fecha,
          descripcion: retiro.motivo.trim().isEmpty
              ? 'Retiro de caja'
              : 'Retiro · ${retiro.motivo.trim()}',
          importe: -retiro.importe,
        ),
      );
    }

    final cierreFecha = cerradoEn ?? DateTime.now();
    movimientos.add(
      MovimientoCaja(
        tipo: 'cierre',
        fecha: cierreFecha,
        descripcion: cuadra
            ? 'Cierre · cuadra · contado ${conteoFisico.total.toStringAsFixed(2)} €'
            : 'Cierre · descuadre ${diferencia.toStringAsFixed(2)} € · '
                'esperado ${totalEsperado.toStringAsFixed(2)} € · '
                'contado ${conteoFisico.total.toStringAsFixed(2)} €',
        importe: conteoFisico.total,
      ),
    );

    movimientos.sort((a, b) {
      final porFecha = a.fecha.compareTo(b.fecha);
      if (porFecha != 0) return porFecha;
      return _prioridadTipo(a.tipo).compareTo(_prioridadTipo(b.tipo));
    });

    return movimientos;
  }

  static int _prioridadTipo(String tipo) => switch (tipo) {
        'apertura' => 0,
        'cobro' => 1,
        'retiro' => 2,
        'cierre' => 3,
        _ => 4,
      };
}
