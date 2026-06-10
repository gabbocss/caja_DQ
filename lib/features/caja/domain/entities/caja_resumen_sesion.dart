import 'retiro_caja.dart';
import 'sesion_caja.dart';

/// Resumen en vivo de la sesión de caja activa.
class CajaResumenSesion {
  final bool tieneSesion;
  final bool tieneFondo;
  final double fondoInicial;
  final double totalEfectivo;
  final double totalOtros;
  final double totalRetiros;
  final double totalEsperado;
  final List<RetiroCaja> retiros;
  final SesionCaja? sesion;

  const CajaResumenSesion({
    required this.tieneSesion,
    required this.tieneFondo,
    required this.fondoInicial,
    required this.totalEfectivo,
    required this.totalOtros,
    required this.totalRetiros,
    required this.totalEsperado,
    this.retiros = const [],
    this.sesion,
  });
}
