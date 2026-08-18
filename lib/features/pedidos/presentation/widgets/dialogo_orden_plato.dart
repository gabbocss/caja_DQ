import 'package:flutter/material.dart';

/// Resultado del diálogo: unidades de 2º y 3º. El resto es 1º.
typedef ResultadoOrdenPlato = ({int segundo, int tercero});

/// Diálogo para repartir las unidades de un plato entre 1º, 2º y 3º.
/// El primero es el resto (total − segundo − tercero).
class DialogoOrdenPlato {
  DialogoOrdenPlato._();

  static Future<ResultadoOrdenPlato?> mostrar({
    required BuildContext context,
    required String nombrePlato,
    required int total,
    required int segundoInicial,
    required int terceroInicial,
  }) {
    return showDialog<ResultadoOrdenPlato>(
      context: context,
      builder: (ctx) => _DialogoOrdenPlatoBody(
        nombrePlato: nombrePlato,
        total: total,
        segundoInicial: segundoInicial,
        terceroInicial: terceroInicial,
      ),
    );
  }
}

class _DialogoOrdenPlatoBody extends StatefulWidget {
  final String nombrePlato;
  final int total;
  final int segundoInicial;
  final int terceroInicial;

  const _DialogoOrdenPlatoBody({
    required this.nombrePlato,
    required this.total,
    required this.segundoInicial,
    required this.terceroInicial,
  });

  @override
  State<_DialogoOrdenPlatoBody> createState() => _DialogoOrdenPlatoBodyState();
}

class _DialogoOrdenPlatoBodyState extends State<_DialogoOrdenPlatoBody> {
  late int _segundo;
  late int _tercero;

  int get _primero => widget.total - _segundo - _tercero;

  @override
  void initState() {
    super.initState();
    final total = widget.total;
    _segundo = widget.segundoInicial.clamp(0, total);
    _tercero = widget.terceroInicial.clamp(0, total - _segundo);
  }

  void _cambiarSegundo(int delta) {
    final nuevo = _segundo + delta;
    if (nuevo < 0 || nuevo + _tercero > widget.total) return;
    setState(() => _segundo = nuevo);
  }

  void _cambiarTercero(int delta) {
    final nuevo = _tercero + delta;
    if (nuevo < 0 || _segundo + nuevo > widget.total) return;
    setState(() => _tercero = nuevo);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF16213E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.nombrePlato,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.total} ${widget.total == 1 ? 'unidad' : 'unidades'} en el pedido',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FilaTurno(
            etiqueta: '1º  primero',
            cantidad: _primero,
            color: const Color(0xFF00D9A5),
          ),
          const SizedBox(height: 12),
          _FilaTurno(
            etiqueta: '2º  segundo',
            cantidad: _segundo,
            color: const Color(0xFFE94560),
            onDecrement: () => _cambiarSegundo(-1),
            onIncrement: () => _cambiarSegundo(1),
            puedeDecrementar: _segundo > 0,
            puedeIncrementar: _primero > 0,
          ),
          const SizedBox(height: 12),
          _FilaTurno(
            etiqueta: '3º  tercero',
            cantidad: _tercero,
            color: const Color(0xFFFFD700),
            onDecrement: () => _cambiarTercero(-1),
            onIncrement: () => _cambiarTercero(1),
            puedeDecrementar: _tercero > 0,
            puedeIncrementar: _primero > 0,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            (segundo: _segundo, tercero: _tercero),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF00D9A5),
            foregroundColor: Colors.black87,
          ),
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}

class _FilaTurno extends StatelessWidget {
  final String etiqueta;
  final int cantidad;
  final Color color;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final bool puedeDecrementar;
  final bool puedeIncrementar;

  const _FilaTurno({
    required this.etiqueta,
    required this.cantidad,
    required this.color,
    this.onDecrement,
    this.onIncrement,
    this.puedeDecrementar = false,
    this.puedeIncrementar = false,
  });

  bool get _esEditable => onDecrement != null && onIncrement != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              etiqueta,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          if (_esEditable) ...[
            _BotonPaso(
              icon: Icons.remove,
              onPressed: puedeDecrementar ? onDecrement : null,
            ),
            _CantidadTurno(cantidad: cantidad, color: color),
            _BotonPaso(
              icon: Icons.add,
              onPressed: puedeIncrementar ? onIncrement : null,
            ),
          ] else
            _CantidadTurno(cantidad: cantidad, color: color),
        ],
      ),
    );
  }
}

class _CantidadTurno extends StatelessWidget {
  final int cantidad;
  final Color color;

  const _CantidadTurno({required this.cantidad, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Text(
        '$cantidad',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }
}

class _BotonPaso extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _BotonPaso({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      color: Colors.white,
      disabledColor: Colors.white24,
      style: IconButton.styleFrom(
        minimumSize: const Size(36, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: const Color(0xFF0F3460),
      ),
    );
  }
}
