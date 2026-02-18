import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';

/// Pantalla de categorías para una mesa.
/// Muestra la lista de categorías (Bebidas, Primeros, etc.); al tocar una se navega a platos.
class MesaCategoriasPage extends StatelessWidget {
  final int numeroMesa;

  const MesaCategoriasPage({super.key, required this.numeroMesa});

  static IconData _iconoCategoria(String categoria) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text('Mesa $numeroMesa - Categorías'),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: CategoriaProducto.todas.length,
        itemBuilder: (context, index) {
          final categoria = CategoriaProducto.todas[index];
          final slug = categoria.replaceAll(' ', '_');
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/mesas/$numeroMesa/platos/$slug'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF0F3460), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE94560).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _iconoCategoria(categoria),
                          color: const Color(0xFFE94560),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          categoria,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white54, size: 28),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
