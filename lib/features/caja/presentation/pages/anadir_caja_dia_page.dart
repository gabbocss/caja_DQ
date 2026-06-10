import 'package:flutter/material.dart';

import '../../data/caja_service.dart'
    if (dart.library.html) '../../data/caja_service_stub.dart';
import '../../domain/entities/conteo_efectivo.dart';
import '../widgets/conteo_denominaciones_form.dart';

/// Registra el fondo inicial de la sesión de caja (billetes y monedas).
class AnadirCajaDiaPage extends StatefulWidget {
  const AnadirCajaDiaPage({super.key});

  @override
  State<AnadirCajaDiaPage> createState() => _AnadirCajaDiaPageState();
}

class _AnadirCajaDiaPageState extends State<AnadirCajaDiaPage> {
  bool _guardando = false;
  ConteoEfectivo _conteo = ConteoEfectivo.vacio();
  bool _haySesionActiva = false;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarEstado();
  }

  Future<void> _cargarEstado() async {
    final sesion = await CajaService.instance.obtenerSesionActiva();
    if (!mounted) return;
    setState(() {
      _haySesionActiva = sesion != null;
      _conteo = sesion?.fondoInicial ?? ConteoEfectivo.vacio();
      _cargando = false;
    });
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      if (_haySesionActiva) {
        await CajaService.instance.actualizarFondoInicial(_conteo);
      } else {
        await CajaService.instance.abrirSesionConFondo(_conteo);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _conteo.estaVacio
                ? 'Sesión abierta sin fondo inicial'
                : 'Caja del día registrada: ${_conteo.total.toStringAsFixed(2)} €',
          ),
          backgroundColor: const Color(0xFF00D9A5),
        ),
      );
      Navigator.of(context).pop(true);
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
            Icon(Icons.account_balance_wallet, color: Color(0xFF00D9A5)),
            SizedBox(width: 12),
            Text(
              'CAJA DEL DÍA',
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
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_haySesionActiva)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F3460),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF00D9A5)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Hay una sesión abierta. Puedes actualizar el fondo inicial.',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                const Text(
                  'Indica cuántos billetes y monedas hay en caja al inicio del turno.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 20),
                ConteoDenominacionesForm(
                  conteoInicial: _conteo,
                  onChanged: (c) => _conteo = c,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: _guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _haySesionActiva ? 'ACTUALIZAR FONDO' : 'ABRIR CAJA',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00D9A5),
                    foregroundColor: const Color(0xFF1A1A2E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
