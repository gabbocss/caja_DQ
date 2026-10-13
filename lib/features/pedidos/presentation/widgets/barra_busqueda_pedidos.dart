import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Barra de búsqueda de platos (estilo POS oscuro).
/// La X limpia el texto y quita el foco (útil en móvil sin tecla ESC).
class BarraBusquedaPedidos extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final String textoActual;
  final ValueChanged<String> onChanged;
  final VoidCallback onLimpiar;
  /// Si es true, Esc también limpia (desktop).
  final bool cerrarConEscape;

  const BarraBusquedaPedidos({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.textoActual,
    required this.onChanged,
    required this.onLimpiar,
    this.cerrarConEscape = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget campo = TextField(
      controller: controller,
      focusNode: focusNode,
      style: const TextStyle(color: Colors.white),
      cursorColor: const Color(0xFFE94560),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: Colors.white54,
        ),
        suffixIcon: textoActual.isNotEmpty
            ? IconButton(
                icon: const Icon(
                  Icons.clear,
                  color: Colors.white54,
                ),
                tooltip: 'Dejar de buscar',
                onPressed: onLimpiar,
              )
            : null,
        filled: true,
        fillColor: const Color(0xFF0F3460),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE94560),
            width: 1.5,
          ),
        ),
      ),
      onChanged: onChanged,
    );

    if (cerrarConEscape) {
      campo = Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            onLimpiar();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: campo,
      );
    }

    return Container(
      color: const Color(0xFF16213E),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: campo,
    );
  }
}
