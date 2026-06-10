import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/scroll_horizontal_con_flechas.dart';

/// Widget de selector de categorías con scroll horizontal
///
/// Permite filtrar productos por categoría con botones grandes táctiles.
/// Si [categorias] es null o vacío, usa [CategoriaProducto.todas].
class CategoriaSelector extends StatelessWidget {
  final String? categoriaSeleccionada;
  final ValueChanged<String?> onCategoriaChanged;
  final List<String>? categorias;

  const CategoriaSelector({
    super.key,
    this.categoriaSeleccionada,
    required this.onCategoriaChanged,
    this.categorias,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF0F3460),
            width: 2,
          ),
        ),
      ),
      child: ScrollHorizontalConFlechas(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          _buildCategoriaChip(
            context,
            label: 'TODOS',
            icono: Icons.apps,
            isSelected: categoriaSeleccionada == null,
            onTap: () => onCategoriaChanged(null),
          ),
          const SizedBox(width: 8),
          Container(
            width: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F3460),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          ...(categorias?.isNotEmpty == true
                  ? categorias!
                  : CategoriaProducto.todas)
              .map(
            (categoria) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildCategoriaChip(
                context,
                label: categoria.toUpperCase(),
                icono: _getIconoCategoria(categoria),
                isSelected: categoriaSeleccionada == categoria,
                onTap: () => onCategoriaChanged(categoria),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaChip(
    BuildContext context, {
    required String label,
    required IconData icono,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFFE94560), Color(0xFFFF6B6B)],
                  )
                : null,
            color: isSelected ? null : const Color(0xFF0F3460),
            borderRadius: BorderRadius.circular(25),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFE94560).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icono,
                size: 18,
                color: isSelected ? Colors.white : Colors.white60,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconoCategoria(String categoria) {
    switch (categoria) {
      case CategoriaProducto.tacos:
        return Icons.lunch_dining;
      case CategoriaProducto.antojitos:
        return Icons.tapas;
      case CategoriaProducto.platosFuertes:
        return Icons.dinner_dining;
      case CategoriaProducto.sopas:
        return Icons.soup_kitchen;
      case CategoriaProducto.ensaladas:
        return Icons.eco;
      case CategoriaProducto.postres:
        return Icons.cake;
      case CategoriaProducto.bebidas:
        return Icons.local_drink;
      case CategoriaProducto.bebidasAlcoholicas:
        return Icons.local_bar;
      case CategoriaProducto.extras:
        return Icons.add_circle;
      default:
        return Icons.restaurant;
    }
  }
}
