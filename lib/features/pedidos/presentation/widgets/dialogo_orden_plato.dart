import 'package:flutter/material.dart';

/// Variante/nota aplicada a N unidades de un turno concreto (1º / 2º / 3º).
class VariantePlato {
  /// 1 = primero, 2 = segundo, 3 = tercero
  final int orden;
  final String texto;
  final int cantidad;

  const VariantePlato({
    required this.orden,
    required this.texto,
    required this.cantidad,
  });
}

/// Resultado del diálogo: turnos + variantes por turno.
class ResultadoOrdenPlato {
  final int segundo;
  final int tercero;
  final List<VariantePlato> variantes;

  const ResultadoOrdenPlato({
    required this.segundo,
    required this.tercero,
    required this.variantes,
  });
}

/// Diálogo para repartir unidades entre 1º/2º/3º y añadir variantes por turno.
class DialogoOrdenPlato {
  DialogoOrdenPlato._();

  static Future<ResultadoOrdenPlato?> mostrar({
    required BuildContext context,
    required String nombrePlato,
    required int total,
    required int segundoInicial,
    required int terceroInicial,
    List<VariantePlato> variantesIniciales = const [],
  }) {
    return showDialog<ResultadoOrdenPlato>(
      context: context,
      builder: (ctx) => _DialogoOrdenPlatoBody(
        nombrePlato: nombrePlato,
        total: total,
        segundoInicial: segundoInicial,
        terceroInicial: terceroInicial,
        variantesIniciales: variantesIniciales,
      ),
    );
  }
}

class _VarianteEdicion {
  final int orden;
  final TextEditingController controller;
  int cantidad;

  _VarianteEdicion({
    required this.orden,
    required String texto,
    this.cantidad = 1,
  }) : controller = TextEditingController(text: texto);

  void dispose() => controller.dispose();
}

class _DialogoOrdenPlatoBody extends StatefulWidget {
  final String nombrePlato;
  final int total;
  final int segundoInicial;
  final int terceroInicial;
  final List<VariantePlato> variantesIniciales;

  const _DialogoOrdenPlatoBody({
    required this.nombrePlato,
    required this.total,
    required this.segundoInicial,
    required this.terceroInicial,
    required this.variantesIniciales,
  });

  @override
  State<_DialogoOrdenPlatoBody> createState() => _DialogoOrdenPlatoBodyState();
}

class _DialogoOrdenPlatoBodyState extends State<_DialogoOrdenPlatoBody> {
  late int _segundo;
  late int _tercero;
  final List<_VarianteEdicion> _variantes = [];

  int get _primero => widget.total - _segundo - _tercero;

  int _cantidadTurno(int orden) {
    switch (orden) {
      case 2:
        return _segundo;
      case 3:
        return _tercero;
      default:
        return _primero;
    }
  }

  int _sumaVariantesTurno(int orden) => _variantes
      .where((v) => v.orden == orden)
      .fold<int>(0, (sum, v) => sum + v.cantidad);

  int _restanteTurno(int orden) =>
      _cantidadTurno(orden) - _sumaVariantesTurno(orden);

  bool _puedeAnadirVariante(int orden) =>
      _cantidadTurno(orden) > 0 && _restanteTurno(orden) > 0;

  List<_VarianteEdicion> _variantesDe(int orden) =>
      _variantes.where((v) => v.orden == orden).toList();

  @override
  void initState() {
    super.initState();
    final total = widget.total;
    _segundo = widget.segundoInicial.clamp(0, total);
    _tercero = widget.terceroInicial.clamp(0, total - _segundo);

    final usadosPorOrden = <int, int>{1: 0, 2: 0, 3: 0};
    for (final v in widget.variantesIniciales) {
      final texto = v.texto.trim();
      final orden = v.orden.clamp(1, 3);
      if (texto.isEmpty || v.cantidad <= 0) continue;
      final cupo = _cantidadTurno(orden) - (usadosPorOrden[orden] ?? 0);
      if (cupo <= 0) continue;
      final cant = v.cantidad.clamp(1, cupo);
      _variantes.add(
        _VarianteEdicion(orden: orden, texto: texto, cantidad: cant),
      );
      usadosPorOrden[orden] = (usadosPorOrden[orden] ?? 0) + cant;
    }
  }

  @override
  void dispose() {
    for (final v in _variantes) {
      v.dispose();
    }
    super.dispose();
  }

  void _limpiarVariantesTurno(int orden) {
    final aEliminar = _variantes.where((v) => v.orden == orden).toList();
    for (final v in aEliminar) {
      _variantes.remove(v);
      v.dispose();
    }
  }

  void _recortarVariantesTurno(int orden, int maxUnidades) {
    if (maxUnidades <= 0) {
      _limpiarVariantesTurno(orden);
      return;
    }
    var usados = 0;
    final delTurno = _variantesDe(orden);
    for (final v in delTurno) {
      if (usados >= maxUnidades) {
        _variantes.remove(v);
        v.dispose();
        continue;
      }
      final restante = maxUnidades - usados;
      if (v.cantidad > restante) {
        v.cantidad = restante;
      }
      usados += v.cantidad;
    }
  }

  void _cambiarSegundo(int delta) {
    final nuevo = _segundo + delta;
    if (nuevo < 0 || nuevo + _tercero > widget.total) return;
    setState(() {
      _segundo = nuevo;
      _recortarVariantesTurno(2, _segundo);
      _recortarVariantesTurno(1, _primero);
    });
  }

  void _cambiarTercero(int delta) {
    final nuevo = _tercero + delta;
    if (nuevo < 0 || _segundo + nuevo > widget.total) return;
    setState(() {
      _tercero = nuevo;
      _recortarVariantesTurno(3, _tercero);
      _recortarVariantesTurno(1, _primero);
    });
  }

  void _anadirVariante(int orden) {
    if (!_puedeAnadirVariante(orden)) return;
    setState(() {
      _variantes.add(_VarianteEdicion(orden: orden, texto: '', cantidad: 1));
    });
  }

  void _eliminarVariante(_VarianteEdicion v) {
    setState(() {
      _variantes.remove(v);
      v.dispose();
    });
  }

  void _cambiarCantidadVariante(_VarianteEdicion v, int delta) {
    final nuevo = v.cantidad + delta;
    // Mínimo 1: para quitar la variante se usa la papelera.
    if (nuevo < 1) return;
    if (delta > 0 && _restanteTurno(v.orden) <= 0) return;
    setState(() => v.cantidad = nuevo);
  }

  void _aceptar() {
    final variantes = <VariantePlato>[];
    final usadosPorOrden = <int, int>{1: 0, 2: 0, 3: 0};
    for (final v in _variantes) {
      final texto = v.controller.text.trim();
      if (texto.isEmpty) continue;
      final cupoTurno = _cantidadTurno(v.orden);
      if (cupoTurno <= 0) continue;
      final usados = usadosPorOrden[v.orden] ?? 0;
      final cant = v.cantidad.clamp(1, cupoTurno - usados);
      if (cant <= 0) continue;
      variantes.add(
        VariantePlato(orden: v.orden, texto: texto, cantidad: cant),
      );
      usadosPorOrden[v.orden] = usados + cant;
    }
    Navigator.of(context).pop(
      ResultadoOrdenPlato(
        segundo: _segundo,
        tercero: _tercero,
        variantes: variantes,
      ),
    );
  }

  Widget _bloqueTurno({
    required int orden,
    required String etiqueta,
    required Color color,
    VoidCallback? onDecrement,
    VoidCallback? onIncrement,
    bool puedeDecrementar = false,
    bool puedeIncrementar = false,
  }) {
    final variantes = _variantesDe(orden);
    final cupo = _cantidadTurno(orden);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FilaTurno(
          etiqueta: etiqueta,
          cantidad: cupo,
          color: color,
          onDecrement: onDecrement,
          onIncrement: onIncrement,
          puedeDecrementar: puedeDecrementar,
          puedeIncrementar: puedeIncrementar,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            onPressed:
                _puedeAnadirVariante(orden) ? () => _anadirVariante(orden) : null,
            tooltip: cupo <= 0
                ? 'Sin platos en este turno'
                : 'Añadir variante a este turno',
            icon: const Icon(Icons.add_circle_outline),
            color: color,
            disabledColor: Colors.white24,
          ),
        ),
        for (var i = 0; i < variantes.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _FilaVariante(
            controller: variantes[i].controller,
            cantidad: variantes[i].cantidad,
            accentColor: color,
            puedeIncrementar: _restanteTurno(orden) > 0,
            onDecrement: () => _cambiarCantidadVariante(variantes[i], -1),
            onIncrement: () => _cambiarCantidadVariante(variantes[i], 1),
            onEliminar: () => _eliminarVariante(variantes[i]),
          ),
        ],
      ],
    );
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
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _bloqueTurno(
                orden: 1,
                etiqueta: '1º  primero',
                color: const Color(0xFF00D9A5),
              ),
              const SizedBox(height: 12),
              _bloqueTurno(
                orden: 2,
                etiqueta: '2º  segundo',
                color: const Color(0xFFE94560),
                onDecrement: () => _cambiarSegundo(-1),
                onIncrement: () => _cambiarSegundo(1),
                puedeDecrementar: _segundo > 0,
                puedeIncrementar: _primero > 0,
              ),
              const SizedBox(height: 12),
              _bloqueTurno(
                orden: 3,
                etiqueta: '3º  tercero',
                color: const Color(0xFFFFD700),
                onDecrement: () => _cambiarTercero(-1),
                onIncrement: () => _cambiarTercero(1),
                puedeDecrementar: _tercero > 0,
                puedeIncrementar: _primero > 0,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _aceptar,
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

class _FilaVariante extends StatelessWidget {
  final TextEditingController controller;
  final int cantidad;
  final Color accentColor;
  final bool puedeIncrementar;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onEliminar;

  const _FilaVariante({
    required this.controller,
    required this.cantidad,
    required this.accentColor,
    required this.puedeIncrementar,
    required this.onDecrement,
    required this.onIncrement,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Variante (ej. sin ajo)',
              hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
          Row(
            children: [
              _BotonPaso(
                icon: Icons.remove,
                // Mínimo 1; eliminar con papelera.
                onPressed: cantidad > 1 ? onDecrement : null,
              ),
              _CantidadTurno(cantidad: cantidad, color: accentColor),
              _BotonPaso(
                icon: Icons.add,
                onPressed: puedeIncrementar ? onIncrement : null,
              ),
              const Spacer(),
              IconButton(
                onPressed: onEliminar,
                tooltip: 'Eliminar variante',
                icon: const Icon(Icons.delete_outline, size: 22),
                color: const Color(0xFFE94560),
              ),
            ],
          ),
        ],
      ),
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
