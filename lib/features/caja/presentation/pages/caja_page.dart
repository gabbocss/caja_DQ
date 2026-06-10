import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/caja_service.dart'
    if (dart.library.html) '../../data/caja_service_stub.dart';
import '../../domain/entities/caja_resumen_sesion.dart';
import '../../domain/entities/cierre_caja.dart';
import 'anadir_caja_dia_page.dart';
import 'cierre_caja_page.dart';
import 'retiro_caja_page.dart';

/// Menú principal de caja: apertura, retiros, cierre e historial.
class CajaPage extends StatefulWidget {
  const CajaPage({super.key});

  @override
  State<CajaPage> createState() => _CajaPageState();
}

class _CajaPageState extends State<CajaPage> {
  CajaResumenSesion? _resumen;
  List<CierreCaja> _historial = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final resumen = await CajaService.instance.obtenerResumenSesion();
    final historial = await CajaService.instance.obtenerHistorialCierres();
    if (!mounted) return;
    setState(() {
      _resumen = resumen;
      _historial = historial.take(10).toList();
      _cargando = false;
    });
  }

  Future<void> _navegar(Widget page) async {
    final actualizado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => page),
    );
    if (actualizado == true || actualizado == null) {
      await _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Row(
          children: [
            Icon(Icons.point_of_sale, color: Color(0xFF00D9A5)),
            SizedBox(width: 12),
            Text(
              'CAJA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _cargando ? null : _cargar,
            icon: const Icon(Icons.refresh, color: Color(0xFF00D9A5)),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE94560)),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_resumen != null) _estadoSesion(_resumen!),
                const SizedBox(height: 24),
                _opcion(
                  icon: Icons.account_balance_wallet,
                  color: const Color(0xFF00D9A5),
                  titulo: 'Añadir caja del día',
                  subtitulo: _resumen?.tieneSesion == true
                      ? 'Actualizar el fondo de la sesión activa'
                      : 'Contar billetes y monedas al inicio del turno',
                  onTap: () => _navegar(const AnadirCajaDiaPage()),
                ),
                const SizedBox(height: 12),
                _opcion(
                  icon: Icons.money_off,
                  color: const Color(0xFFE94560),
                  titulo: 'Retiro de caja',
                  subtitulo: 'Registrar dinero sacado durante el servicio',
                  onTap: () => _navegar(const RetiroCajaPage()),
                  habilitado: _resumen?.tieneSesion == true,
                ),
                const SizedBox(height: 12),
                _opcion(
                  icon: Icons.lock_clock,
                  color: const Color(0xFFFFB347),
                  titulo: 'Cierre de caja',
                  subtitulo: 'Arqueo del efectivo y cierre del turno',
                  onTap: () => _navegar(const CierreCajaPage()),
                  habilitado: _resumen?.tieneSesion == true,
                ),
                const SizedBox(height: 32),
                _historialCierres(),
              ],
            ),
    );
  }

  Widget _estadoSesion(CajaResumenSesion r) {
    if (!r.tieneSesion) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white54),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No hay sesión abierta. Añade la caja del día para empezar.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0F3460),
            const Color(0xFF16213E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00D9A5).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF00D9A5),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Sesión activa',
                style: TextStyle(
                  color: Color(0xFF00D9A5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _miniFila('Fondo', r.fondoInicial),
          _miniFila('Efectivo cobrado', r.totalEfectivo),
          _miniFila('Otros cobrados', r.totalOtros),
          _miniFila('Retiros', r.totalRetiros, negativo: true),
          const Divider(color: Colors.white24, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total esperado',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${r.totalEsperado.toStringAsFixed(2)} €',
                style: const TextStyle(
                  color: Color(0xFF00D9A5),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniFila(String etiqueta, double valor, {bool negativo = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(
            '${negativo ? '-' : ''}${valor.toStringAsFixed(2)} €',
            style: TextStyle(
              color: negativo ? const Color(0xFFE94560) : Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _opcion({
    required IconData icon,
    required Color color,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
    bool habilitado = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: habilitado ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: habilitado ? color.withValues(alpha: 0.3) : Colors.white10,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: habilitado ? 0.15 : 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: habilitado ? color : Colors.white24,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        color: habilitado ? Colors.white : Colors.white38,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitulo,
                      style: TextStyle(
                        color: habilitado ? Colors.white54 : Colors.white24,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: habilitado ? Colors.white38 : Colors.white12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historialCierres() {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Últimos cierres',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        if (_historial.isEmpty)
          const Text(
            'Aún no hay cierres registrados.',
            style: TextStyle(color: Colors.white38),
          )
        else
          ..._historial.map(
            (c) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    c.cuadra ? Icons.check_circle : Icons.warning,
                    color: c.cuadra
                        ? const Color(0xFF00D9A5)
                        : const Color(0xFFE94560),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fmt.format(c.cerradoEn),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          c.cuadra
                              ? 'Cuadra · ${c.conteoFisico.toStringAsFixed(2)} €'
                              : 'Descuadre: ${c.diferencia.toStringAsFixed(2)} €',
                          style: TextStyle(
                            color: c.cuadra
                                ? Colors.white54
                                : const Color(0xFFE94560),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${c.totalEsperado.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
