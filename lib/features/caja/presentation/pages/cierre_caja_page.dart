import 'package:flutter/material.dart';

import '../../data/caja_service.dart'
    if (dart.library.html) '../../data/caja_service_stub.dart';
import '../../domain/entities/caja_resumen_sesion.dart';
import '../../domain/entities/cierre_caja.dart';
import '../../domain/entities/conteo_efectivo.dart';
import '../widgets/conteo_denominaciones_form.dart';

enum _PasoCierre { resumen, conteo, resultado }

/// Arqueo y cierre de la sesión de caja activa.
class CierreCajaPage extends StatefulWidget {
  const CierreCajaPage({super.key});

  @override
  State<CierreCajaPage> createState() => _CierreCajaPageState();
}

class _CierreCajaPageState extends State<CierreCajaPage> {
  _PasoCierre _paso = _PasoCierre.resumen;
  CajaResumenSesion? _resumen;
  ConteoEfectivo _conteoFisico = ConteoEfectivo.vacio();
  CierreCaja? _resultado;
  bool _cargando = true;
  bool _cerrando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final resumen = await CajaService.instance.obtenerResumenSesion();
    if (!mounted) return;
    setState(() {
      _resumen = resumen;
      _cargando = false;
    });
  }

  Future<void> _irAConteo() async {
    if (_resumen == null || !_resumen!.tieneSesion) return;

    if (!_resumen!.tieneFondo) {
      final continuar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          title: const Text(
            'Sin fondo inicial',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'No has registrado la caja del día. El total esperado solo '
            'incluirá cobros en efectivo/otros y retiros.\n\n¿Continuar?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE94560),
              ),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
      if (continuar != true || !mounted) return;
    }

    setState(() => _paso = _PasoCierre.conteo);
  }

  Future<void> _confirmarCierre() async {
    if (_resumen == null) return;

    final esperado = _resumen!.totalEsperado;
    final fisico = _conteoFisico.total;
    final diferencia = fisico - esperado;
    final cuadra = diferencia.abs() < 0.01;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: Text(
          cuadra ? '¿Cuadra la caja?' : '¿Confirmar cierre con descuadre?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _lineaResumen('Esperado', esperado),
            _lineaResumen('Contado', fisico),
            const Divider(color: Colors.white24),
            _lineaResumen(
              'Diferencia',
              diferencia,
              destacado: true,
              color: cuadra ? const Color(0xFF00D9A5) : const Color(0xFFE94560),
            ),
            if (!cuadra) ...[
              const SizedBox(height: 12),
              const Text(
                'Se guardará el descuadre en el historial y se preparará '
                'una nueva sesión.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor:
                  cuadra ? const Color(0xFF00D9A5) : const Color(0xFFE94560),
              foregroundColor: const Color(0xFF1A1A2E),
            ),
            child: Text(cuadra ? 'Todo correcto' : 'Cerrar igualmente'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _cerrando = true);
    try {
      final cierre = await CajaService.instance.cerrarSesion(
        conteoFisico: _conteoFisico,
        cuadra: cuadra,
      );
      if (!mounted) return;
      setState(() {
        _resultado = cierre;
        _paso = _PasoCierre.resultado;
        _cerrando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cerrando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Widget _lineaResumen(
    String etiqueta,
    double valor, {
    bool destacado = false,
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
              color: Colors.white70,
              fontWeight: destacado ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${valor.toStringAsFixed(2)} €',
            style: TextStyle(
              color: color ?? Colors.white,
              fontWeight: destacado ? FontWeight.bold : FontWeight.w600,
              fontSize: destacado ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        leading: _paso == _PasoCierre.resultado
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (_paso == _PasoCierre.conteo) {
                    setState(() => _paso = _PasoCierre.resumen);
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
        title: const Row(
          children: [
            Icon(Icons.lock_clock, color: Color(0xFFE94560)),
            SizedBox(width: 12),
            Text(
              'CIERRE DE CAJA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE94560)),
            )
          : _buildCuerpo(),
    );
  }

  Widget _buildCuerpo() {
    return switch (_paso) {
      _PasoCierre.resumen => _buildResumen(),
      _PasoCierre.conteo => _buildConteo(),
      _PasoCierre.resultado => _buildResultado(),
    };
  }

  Widget _buildResumen() {
    final r = _resumen;
    if (r == null || !r.tieneSesion) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber, color: Colors.amber, size: 48),
              const SizedBox(height: 16),
              const Text(
                'No hay sesión de caja abierta.\nAñade la caja del día para empezar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('VOLVER'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Resumen de la sesión',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),
        _tarjetaResumen(r),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _irAConteo,
          icon: const Icon(Icons.calculate),
          label: const Text('CONTAR EFECTIVO Y CERRAR'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE94560),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _tarjetaResumen(CajaResumenSesion r) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _fila('Fondo inicial', r.fondoInicial, signo: ''),
          _fila('Cobros efectivo', r.totalEfectivo, signo: '+'),
          _fila('Cobros otros', r.totalOtros, signo: '+'),
          _fila('Retiros', r.totalRetiros, signo: '-'),
          const Divider(color: Colors.white24, height: 24),
          _fila('TOTAL ESPERADO', r.totalEsperado, destacado: true),
        ],
      ),
    );
  }

  Widget _fila(
    String etiqueta,
    double valor, {
    String signo = '',
    bool destacado = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            etiqueta,
            style: TextStyle(
              color: destacado ? Colors.white : Colors.white70,
              fontWeight: destacado ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '$signo${valor.toStringAsFixed(2)} €',
            style: TextStyle(
              color: destacado ? const Color(0xFF00D9A5) : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: destacado ? 20 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConteo() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Cuenta el efectivo que hay ahora en caja',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 16),
        ConteoDenominacionesForm(
          onChanged: (c) => _conteoFisico = c,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _cerrando ? null : _confirmarCierre,
          icon: _cerrando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_circle),
          label: const Text('FINALIZAR CIERRE'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF00D9A5),
            foregroundColor: const Color(0xFF1A1A2E),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildResultado() {
    final c = _resultado!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              c.cuadra ? Icons.check_circle : Icons.warning_amber,
              color: c.cuadra ? const Color(0xFF00D9A5) : Colors.amber,
              size: 72,
            ),
            const SizedBox(height: 16),
            Text(
              c.cuadra ? 'Caja cerrada correctamente' : 'Cierre con descuadre',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _lineaResumen('Esperado', c.totalEsperado),
                  _lineaResumen('Contado', c.conteoFisico),
                  _lineaResumen(
                    'Diferencia',
                    c.diferencia,
                    destacado: true,
                    color: c.cuadra
                        ? const Color(0xFF00D9A5)
                        : const Color(0xFFE94560),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Sesión cerrada. Puedes abrir una nueva caja cuando quieras.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00D9A5),
                foregroundColor: const Color(0xFF1A1A2E),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: const Text('LISTO'),
            ),
          ],
        ),
      ),
    );
  }
}
