import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/caja_service.dart'
    if (dart.library.html) '../../data/caja_service_stub.dart';
import '../../domain/entities/retiro_caja.dart';

/// Registra retiros de efectivo durante el servicio.
class RetiroCajaPage extends StatefulWidget {
  const RetiroCajaPage({super.key});

  @override
  State<RetiroCajaPage> createState() => _RetiroCajaPageState();
}

class _RetiroCajaPageState extends State<RetiroCajaPage> {
  final _importeCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController();
  final _fmt = DateFormat('HH:mm');
  bool _guardando = false;
  List<RetiroCaja> _retiros = [];
  bool _cargando = true;
  bool _haySesion = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _importeCtrl.dispose();
    _motivoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final resumen = await CajaService.instance.obtenerResumenSesion();
    if (!mounted) return;
    setState(() {
      _haySesion = resumen.tieneSesion;
      _retiros = resumen.retiros;
      _cargando = false;
    });
  }

  Future<void> _registrarRetiro() async {
    final importe = double.tryParse(_importeCtrl.text.replaceAll(',', '.'));
    if (importe == null || importe <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Introduce un importe válido mayor que cero'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_motivoCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Indica el motivo del retiro'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      await CajaService.instance.registrarRetiro(
        importe: importe,
        motivo: _motivoCtrl.text,
      );
      _importeCtrl.clear();
      _motivoCtrl.clear();
      await _cargar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Retiro registrado'),
          backgroundColor: Color(0xFF00D9A5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
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
            Icon(Icons.money_off, color: Color(0xFFE94560)),
            SizedBox(width: 12),
            Text(
              'RETIRO DE CAJA',
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
          : !_haySesion
              ? _sinSesion()
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _formularioRetiro(),
                    const SizedBox(height: 24),
                    _listaRetiros(),
                  ],
                ),
    );
  }

  Widget _sinSesion() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber, color: Colors.amber, size: 48),
            const SizedBox(height: 16),
            const Text(
              'No hay sesión de caja abierta.\nAñade la caja del día primero.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00D9A5),
                foregroundColor: const Color(0xFF1A1A2E),
              ),
              child: const Text('VOLVER'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formularioRetiro() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Nuevo retiro',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _importeCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              labelText: 'Importe (€)',
              labelStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF1A1A2E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE94560)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _motivoCtrl,
            maxLines: 2,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Motivo',
              labelStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF1A1A2E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE94560)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _guardando ? null : _registrarRetiro,
            icon: _guardando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.remove_circle_outline),
            label: const Text('REGISTRAR RETIRO'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE94560),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _listaRetiros() {
    if (_retiros.isEmpty) {
      return const Text(
        'No hay retiros en esta sesión.',
        style: TextStyle(color: Colors.white38),
      );
    }

    final total =
        _retiros.fold(0.0, (suma, r) => suma + r.importe);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Retiros de la sesión',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              '-${total.toStringAsFixed(2)} €',
              style: const TextStyle(
                color: Color(0xFFE94560),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._retiros.reversed.map(
          (r) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  _fmt.format(r.fecha),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    r.motivo.isEmpty ? '(sin motivo)' : r.motivo,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                Text(
                  '-${r.importe.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    color: Color(0xFFE94560),
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
