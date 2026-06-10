import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/conteo_efectivo.dart';
import '../../domain/entities/denominacion_euro.dart';

/// Formulario reutilizable para contar billetes y monedas por denominación.
class ConteoDenominacionesForm extends StatefulWidget {
  final ConteoEfectivo conteoInicial;
  final ValueChanged<ConteoEfectivo>? onChanged;

  const ConteoDenominacionesForm({
    super.key,
    ConteoEfectivo? conteoInicial,
    this.onChanged,
  }) : conteoInicial = conteoInicial ?? const ConteoEfectivo({});

  @override
  State<ConteoDenominacionesForm> createState() =>
      _ConteoDenominacionesFormState();
}

class _ConteoDenominacionesFormState extends State<ConteoDenominacionesForm> {
  late ConteoEfectivo _conteo;
  final _controllers = <double, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _conteo = widget.conteoInicial.cantidades.isEmpty
        ? ConteoEfectivo.vacio()
        : widget.conteoInicial;
    for (final valor in DenominacionEuro.valores) {
      final c = TextEditingController(
        text: '${_conteo.cantidadDe(valor)}',
      );
      c.addListener(() => _actualizarCantidad(valor, c.text));
      _controllers[valor] = c;
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _actualizarCantidad(double denominacion, String texto) {
    final cantidad = int.tryParse(texto.trim()) ?? 0;
    final nueva = _conteo.conCantidad(denominacion, cantidad);
    if (nueva.cantidades[DenominacionEuro.clave(denominacion)] !=
        _conteo.cantidades[DenominacionEuro.clave(denominacion)]) {
      setState(() => _conteo = nueva);
      widget.onChanged?.call(_conteo);
    }
  }

  ConteoEfectivo get conteo => _conteo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F3460),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Denominación',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Cant.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Subtotal',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...DenominacionEuro.valores.map(_filaDenominacion),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00D9A5).withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '${_conteo.total.toStringAsFixed(2)} €',
                style: const TextStyle(
                  color: Color(0xFF00D9A5),
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filaDenominacion(double valor) {
    final cantidad = _conteo.cantidadDe(valor);
    final subtotal = valor * cantidad;
    final esBillete = valor >= 5;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  esBillete ? Icons.payments_outlined : Icons.toll_outlined,
                  color: esBillete
                      ? const Color(0xFF00D9A5)
                      : Colors.amber.shade300,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  DenominacionEuro.etiqueta(valor),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: TextField(
              controller: _controllers[valor],
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE94560)),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${subtotal.toStringAsFixed(2)} €',
              textAlign: TextAlign.end,
              style: TextStyle(
                color: subtotal > 0 ? Colors.white70 : Colors.white30,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
