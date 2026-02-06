import 'package:flutter/material.dart';

import '../../../../core/core.dart';

/// Grid de productos con tarjetas táctiles
/// 
/// Muestra productos con indicadores visuales para buffet y destino
class ProductoGrid extends StatelessWidget {
  final String? categoriaFiltro;
  final List<Producto> productos;
  final ValueChanged<Producto> onProductoTap;

  const ProductoGrid({
    super.key,
    this.categoriaFiltro,
    required this.productos,
    required this.onProductoTap,
  });

  @override
  Widget build(BuildContext context) {
    // Filtrar por categoría
    var productosFiltrados = productos.where((p) => p.activo).toList();
    
    if (categoriaFiltro != null) {
      productosFiltrados = productosFiltrados
          .where((p) => p.categoria == categoriaFiltro)
          .toList();
    }

    // Si es sábado, ordenar productos buffet primero
    final esSabado = DateTime.now().weekday == DateTime.saturday;
    if (esSabado) {
      productosFiltrados.sort((a, b) {
        if (a.esBuffet && !b.esBuffet) return -1;
        if (!a.esBuffet && b.esBuffet) return 1;
        return a.nombre.compareTo(b.nombre);
      });
    }

    if (productosFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay productos en esta categoría',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: productosFiltrados.length,
      itemBuilder: (context, index) {
        final producto = productosFiltrados[index];
        return ProductoCard(
          producto: producto,
          onTap: () => onProductoTap(producto),
          esSabado: esSabado,
        );
      },
    );
  }
}

/// Tarjeta individual de producto
class ProductoCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback onTap;
  final bool esSabado;

  const ProductoCard({
    super.key,
    required this.producto,
    required this.onTap,
    this.esSabado = false,
  });

  @override
  Widget build(BuildContext context) {
    final esBuffetYSabado = producto.esBuffet && esSabado;
    final estaAgotado = !producto.isAvailable;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: estaAgotado ? null : onTap, // Deshabilitar si está agotado
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: estaAgotado
                  ? [
                      const Color(0xFF2A2A2A),
                      const Color(0xFF1A1A1A),
                    ]
                  : [
                      const Color(0xFF16213E),
                      const Color(0xFF1A1A2E).withValues(alpha: 0.8),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: estaAgotado
                  ? Colors.grey.shade700
                  : esBuffetYSabado
                      ? const Color(0xFFFFD700)
                      : const Color(0xFF0F3460),
              width: esBuffetYSabado ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: estaAgotado
                    ? Colors.transparent
                    : esBuffetYSabado
                        ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.2),
                blurRadius: esBuffetYSabado ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Contenido principal
              Opacity(
                opacity: estaAgotado ? 0.4 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icono del producto
                      Expanded(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _getColorDestino().withValues(alpha: estaAgotado ? 0.05 : 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getIconoCategoria(),
                              size: 40,
                              color: estaAgotado ? Colors.grey : _getColorDestino(),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Nombre del producto
                      Text(
                        producto.nombre,
                        style: TextStyle(
                          color: estaAgotado ? Colors.grey : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Precio
                      Row(
                        children: [
                          Text(
                            '\$${producto.precio.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: estaAgotado
                                  ? Colors.grey
                                  : esBuffetYSabado
                                      ? const Color(0xFFFFD700)
                                      : const Color(0xFF00D9A5),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              decoration: estaAgotado ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const Spacer(),
                          // Indicador de destino
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getColorDestino().withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              producto.destino == DestinoProducto.cocina
                                  ? '🍳'
                                  : '🍹',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Cartel de AGOTADO
              if (estaAgotado)
                Positioned.fill(
                  child: Center(
                    child: Transform.rotate(
                      angle: -0.2, // Ligera inclinación
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE94560),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE94560).withValues(alpha: 0.5),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Text(
                          'AGOTADO',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              
              // Badge de buffet (estrella dorada)
              if (producto.esBuffet && !estaAgotado)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              
              // Indicador "INCLUIDO" si es buffet y sábado
              if (esBuffetYSabado && !estaAgotado)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(14),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'BUFFET',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              
              // Indicador de stock disponible (si usa inventario y hay stock)
              if (producto.usarInventario && !estaAgotado && producto.stockDisponible > 0)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: producto.stockDisponible <= 5
                          ? const Color(0xFFFF6B6B).withValues(alpha: 0.9)
                          : const Color(0xFF00D9A5).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 12,
                          color: producto.stockDisponible <= 5
                              ? Colors.white
                              : Colors.black87,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Quedan ${producto.stockDisponible}',
                          style: TextStyle(
                            color: producto.stockDisponible <= 5
                                ? Colors.white
                                : Colors.black87,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorDestino() {
    return producto.destino == DestinoProducto.cocina
        ? const Color(0xFFE94560)
        : const Color(0xFF00D9A5);
  }

  IconData _getIconoCategoria() {
    switch (producto.categoria) {
      case 'Tacos':
        return Icons.lunch_dining;
      case 'Antojitos':
        return Icons.tapas;
      case 'Platos Fuertes':
        return Icons.dinner_dining;
      case 'Sopas':
        return Icons.soup_kitchen;
      case 'Ensaladas':
        return Icons.eco;
      case 'Postres':
        return Icons.cake;
      case 'Bebidas':
        return Icons.local_drink;
      case 'Bebidas Alcohólicas':
        return Icons.local_bar;
      case 'Extras':
        return Icons.add_circle;
      default:
        return Icons.restaurant;
    }
  }
}
