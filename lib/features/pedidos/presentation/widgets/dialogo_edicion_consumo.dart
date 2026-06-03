import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/models/pedido.dart';
import '../models/linea_consumo_editable.dart';
import '../models/modificacion_consumo_rechazada.dart';

/// Ventana flotante redimensionable para editar platos de la cuenta abierta.
class DialogoEdicionConsumo extends StatefulWidget {
  final int mesaNumero;
  final List<Pedido> pedidos;
  final Future<void> Function(List<LineaConsumoEditable> lineas) onEnviarModificaciones;

  const DialogoEdicionConsumo({
    super.key,
    required this.mesaNumero,
    required this.pedidos,
    required this.onEnviarModificaciones,
  });

  static Future<void> mostrar({
    required BuildContext context,
    required int mesaNumero,
    required List<Pedido> pedidos,
    required Future<void> Function(List<LineaConsumoEditable> lineas)
        onEnviarModificaciones,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DialogoEdicionConsumo(
        mesaNumero: mesaNumero,
        pedidos: pedidos,
        onEnviarModificaciones: onEnviarModificaciones,
      ),
    );
  }

  @override
  State<DialogoEdicionConsumo> createState() => _DialogoEdicionConsumoState();
}

class _DialogoEdicionConsumoState extends State<DialogoEdicionConsumo> {
  static const _minAncho = 380.0;
  static const _minAlto = 280.0;
  static const _maxAncho = 920.0;
  static const _maxAlto = 860.0;

  late List<LineaConsumoEditable> _lineas;
  Size _tamano = const Size(560, 520);
  bool _guardando = false;
  int? _lineaEditandoPrecio;

  @override
  void initState() {
    super.initState();
    _lineas = LineaConsumoEditable.desdePedidos(widget.pedidos);
  }

  double get _subtotal =>
      _lineas.where((l) => l.cantidad > 0).fold(0.0, (s, l) => s + l.subtotal);

  void _cambiarCantidad(int index, int delta) {
    setState(() {
      final linea = _lineas[index];
      linea.cantidad = (linea.cantidad + delta).clamp(0, 999);
    });
  }

  Future<void> _enviar() async {
    if (_guardando) return;
    final hayCambios = _lineas.any((l) => l.huboCambio || l.cantidad <= 0);
    if (!hayCambios) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() => _guardando = true);
    try {
      await widget.onEnviarModificaciones(_lineas);
      if (mounted) Navigator.of(context).pop();
    } on ModificacionConsumoRechazada {
      // AlertDialog ya mostrado en pedidos_page; mantener ventana abierta.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _redimensionar(Offset delta, {bool desdeIzquierda = false, bool desdeArriba = false}) {
    setState(() {
      var w = _tamano.width + (desdeIzquierda ? -delta.dx : delta.dx);
      var h = _tamano.height + (desdeArriba ? -delta.dy : delta.dy);
      w = w.clamp(_minAncho, _maxAncho);
      h = h.clamp(_minAlto, _maxAlto);
      _tamano = Size(w, h);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: _tamano.width,
        height: _tamano.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(16),
              elevation: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCabecera(),
                  Expanded(child: _buildListaPlatos()),
                  _buildPie(),
                ],
              ),
            ),
            _asaRedimension(
              right: 0,
              bottom: 0,
              cursor: SystemMouseCursors.resizeDownRight,
              onDrag: (d) => _redimensionar(d),
            ),
            _asaRedimension(
              left: 0,
              bottom: 0,
              cursor: SystemMouseCursors.resizeDownLeft,
              onDrag: (d) => _redimensionar(d, desdeIzquierda: true),
            ),
            _asaRedimension(
              right: 0,
              top: 0,
              cursor: SystemMouseCursors.resizeUpRight,
              onDrag: (d) => _redimensionar(d, desdeArriba: true),
            ),
            _asaRedimension(
              left: 0,
              top: 0,
              cursor: SystemMouseCursors.resizeUpLeft,
              onDrag: (d) => _redimensionar(d, desdeIzquierda: true, desdeArriba: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _asaRedimension({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required MouseCursor cursor,
    required void Function(Offset delta) onDrag,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (d) => onDrag(d.delta),
          child: const SizedBox(width: 28, height: 28),
        ),
      ),
    );
  }

  Widget _buildCabecera() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0F3460),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_note, color: Color(0xFF00D9A5)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editar consumo — Mesa ${widget.mesaNumero}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Subtotal: €${_subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(color: Color(0xFF00D9A5), fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _guardando ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white54),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }

  Widget _buildListaPlatos() {
    if (_lineas.isEmpty) {
      return const Center(
        child: Text(
          'No hay platos en la cuenta',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _lineas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final linea = _lineas[index];
        final eliminado = linea.cantidad <= 0;
        return Opacity(
          opacity: eliminado ? 0.45 : 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F3460),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: eliminado
                    ? Colors.red.withValues(alpha: 0.4)
                    : const Color(0xFF1A1A2E),
              ),
            ),
            child: Row(
              children: [
                _botonCantidad(
                  icon: Icons.remove,
                  onTap: _guardando || linea.cantidad <= 0
                      ? null
                      : () => _cambiarCantidad(index, -1),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${linea.cantidad}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: eliminado ? Colors.red.shade300 : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _botonCantidad(
                  icon: Icons.add,
                  onTap: _guardando ? null : () => _cambiarCantidad(index, 1),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    linea.nombreProducto,
                    style: TextStyle(
                      color: eliminado ? Colors.white54 : Colors.white,
                      fontSize: 14,
                      decoration:
                          eliminado ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _PrecioEditableInline(
                  precio: linea.precioUnitario,
                  editando: _lineaEditandoPrecio == index,
                  enabled: !_guardando && !eliminado,
                  onTap: () => setState(() => _lineaEditandoPrecio = index),
                  onConfirmar: (v) {
                    setState(() {
                      linea.precioUnitario = v;
                      _lineaEditandoPrecio = null;
                    });
                  },
                  onCancelar: () => setState(() => _lineaEditandoPrecio = null),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _botonCantidad({required IconData icon, VoidCallback? onTap}) {
    return Material(
      color: const Color(0xFF16213E),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: onTap == null ? Colors.white24 : const Color(0xFF00D9A5),
            size: 26,
          ),
        ),
      ),
    );
  }

  Widget _buildPie() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Color(0xFF0F3460),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Arrastre las esquinas para redimensionar',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _guardando ? null : _enviar,
            icon: _guardando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(_guardando ? 'Guardando…' : 'Enviar modificaciones'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00D9A5),
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrecioEditableInline extends StatefulWidget {
  final double precio;
  final bool editando;
  final bool enabled;
  final VoidCallback onTap;
  final ValueChanged<double> onConfirmar;
  final VoidCallback onCancelar;

  const _PrecioEditableInline({
    required this.precio,
    required this.editando,
    required this.enabled,
    required this.onTap,
    required this.onConfirmar,
    required this.onCancelar,
  });

  @override
  State<_PrecioEditableInline> createState() => _PrecioEditableInlineState();
}

class _PrecioEditableInlineState extends State<_PrecioEditableInline> {
  late TextEditingController _controller;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.precio.toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(covariant _PrecioEditableInline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editando && !oldWidget.editando) {
      _controller.text = widget.precio.toStringAsFixed(2);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
    if (!widget.editando && oldWidget.editando) {
      _controller.text = widget.precio.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _confirmar() {
    final t = _controller.text.replaceAll(',', '.').trim();
    final v = double.tryParse(t);
    if (v == null || v < 0 || v.isNaN) {
      widget.onCancelar();
      return;
    }
    widget.onConfirmar(v);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.editando) {
      return InkWell(
        onTap: widget.enabled ? widget.onTap : null,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Text(
            '€${widget.precio.toStringAsFixed(2)}',
            style: TextStyle(
              color: widget.enabled
                  ? const Color(0xFF00D9A5)
                  : Colors.white38,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              decoration: widget.enabled ? TextDecoration.underline : null,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 72,
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
        ],
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          prefixText: '€',
          prefixStyle: const TextStyle(color: Color(0xFF00D9A5), fontSize: 13),
          filled: true,
          fillColor: const Color(0xFF16213E),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onSubmitted: (_) => _confirmar(),
        onTapOutside: (_) => _confirmar(),
      ),
    );
  }
}
