import '../domain/entities/caja_resumen_sesion.dart';
import '../domain/entities/cierre_caja.dart';
import '../domain/entities/conteo_efectivo.dart';
import '../domain/entities/sesion_caja.dart';

/// Stub de [CajaService] para compilación web (sin sistema de archivos local).
class CajaService {
  static final CajaService instance = CajaService._();
  CajaService._();

  String? get sesionActivaId => null;

  Future<SesionCaja?> obtenerSesionActiva() async => null;

  Future<List<CierreCaja>> obtenerHistorialCierres() async => [];

  Future<SesionCaja> abrirSesionConFondo(ConteoEfectivo fondo) async {
    throw UnsupportedError('Caja no disponible en web');
  }

  Future<SesionCaja> actualizarFondoInicial(ConteoEfectivo fondo) async {
    throw UnsupportedError('Caja no disponible en web');
  }

  Future<SesionCaja> registrarRetiro({
    required double importe,
    required String motivo,
  }) async {
    throw UnsupportedError('Caja no disponible en web');
  }

  Future<({double efectivo, double otros})> totalesCobrosSesion(
    String sesionId,
  ) async =>
      (efectivo: 0.0, otros: 0.0);

  Future<double> calcularTotalEsperado(SesionCaja sesion) async => 0;

  Future<CajaResumenSesion> obtenerResumenSesion() async =>
      const CajaResumenSesion(
        tieneSesion: false,
        tieneFondo: false,
        fondoInicial: 0,
        totalEfectivo: 0,
        totalOtros: 0,
        totalRetiros: 0,
        totalEsperado: 0,
      );

  Future<CierreCaja> cerrarSesion({
    required ConteoEfectivo conteoFisico,
    required bool cuadra,
  }) async {
    throw UnsupportedError('Caja no disponible en web');
  }
}
