import 'package:flutter/material.dart';

import '../../../../core/core.dart';

/// Grid de productos con tarjetas táctiles
///
/// Muestra productos con indicadores visuales para buffet y destino.
/// [popularidadPorProductoId]: si no es null, ordena primero por más pedidos (UI servidor).
/// [factorTamanoTarjeta]: 1.0 = tamaño camarero; 0.7 ≈ tarjeta ~30 % más pequeña en ancho/alto/contenido (UI servidor).
/// [gridAnchoFactor]: multiplica el ancho máximo de celda (1.1 = +10 % horizontal).
/// [gridAltoFraccion]: fracción de la altura “natural” (ratio 0.85); 0.4 = celdas ~40 % de alto.
/// [crossAxisCount]: si no es null, fuerza ese número de columnas (p. ej. 2 en app móvil).
/// [cantidadesEnCarrito]: productoId → unidades en el carrito pendiente (badge en app).
class ProductoGrid extends StatelessWidget {
  final String? categoriaFiltro;
  final List<Producto> productos;
  final ValueChanged<Producto> onProductoTap;
  /// productoId → unidades pedidas en histórico; null = orden solo por campo orden (camarero).
  final Map<int, int>? popularidadPorProductoId;
  final double factorTamanoTarjeta;
  final double gridAnchoFactor;
  final double gridAltoFraccion;
  final int? crossAxisCount;
  final Map<int, int> cantidadesEnCarrito;
  /// Producto cuyo borde se ilumina un instante al añadirlo (app).
  final int? productoIdBordeIluminado;

  const ProductoGrid({
    super.key,
    this.categoriaFiltro,
    required this.productos,
    required this.onProductoTap,
    this.popularidadPorProductoId,
    this.factorTamanoTarjeta = 1.0,
    this.gridAnchoFactor = 1.0,
    this.gridAltoFraccion = 1.0,
    this.crossAxisCount,
    this.cantidadesEnCarrito = const {},
    this.productoIdBordeIluminado,
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

    final esSabado = DateTime.now().weekday == DateTime.saturday;
    final pop = popularidadPorProductoId;
    productosFiltrados.sort((a, b) {
      if (pop != null) {
        final ca = pop[a.id ?? 0] ?? 0;
        final cb = pop[b.id ?? 0] ?? 0;
        if (ca != cb) return cb.compareTo(ca);
      }
      final porOrden = a.orden.compareTo(b.orden);
      if (porOrden != 0) return porOrden;
      if (esSabado) {
        if (a.esBuffet && !b.esBuffet) return -1;
        if (!a.esBuffet && b.esBuffet) return 1;
        return a.nombre.compareTo(b.nombre);
      }
      return 0;
    });

    final f = factorTamanoTarjeta;
    if (productosFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80 * f,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            SizedBox(height: 16 * f),
            Text(
              'No hay productos en esta categoría',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16 * f,
              ),
            ),
          ],
        ),
      );
    }
    const ratioBase = 0.85;
    final ancho = gridAnchoFactor.clamp(0.5, 2.0);
    final altoFrac = gridAltoFraccion.clamp(0.25, 1.0);
    final aspectRatio = ratioBase * ancho / altoFrac;

    final SliverGridDelegate gridDelegate = crossAxisCount != null
        ? SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount!,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: 12 * f,
            mainAxisSpacing: 12 * f,
          )
        : SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180 * f * ancho,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: 12 * f,
            mainAxisSpacing: 12 * f,
          );

    return GridView.builder(
      padding: EdgeInsets.all(16 * f),
      gridDelegate: gridDelegate,
      itemCount: productosFiltrados.length,
      itemBuilder: (context, index) {
        final producto = productosFiltrados[index];
        final id = producto.id ?? 0;
        final cantidad = id > 0 ? (cantidadesEnCarrito[id] ?? 0) : 0;
        return ProductoCard(
          producto: producto,
          onTap: () => onProductoTap(producto),
          esSabado: esSabado,
          factorTamanoTarjeta: f,
          cantidadEnCarrito: cantidad,
          iluminarBorde: id > 0 && id == productoIdBordeIluminado,
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
  /// 1.0 = tamaño estándar; 0.7 escala tarjeta (padding, tipografía, badges).
  final double factorTamanoTarjeta;
  /// Unidades pendientes en el carrito de la mesa (solo app).
  final int cantidadEnCarrito;
  /// Flash breve del borde al añadir al carrito.
  final bool iluminarBorde;

  const ProductoCard({
    super.key,
    required this.producto,
    required this.onTap,
    this.esSabado = false,
    this.factorTamanoTarjeta = 1.0,
    this.cantidadEnCarrito = 0,
    this.iluminarBorde = false,
  });

  @override
  Widget build(BuildContext context) {
    final f = factorTamanoTarjeta;
    // +5 % respecto al ajuste anterior (1.05 × 1.05 ≈ +10 % sobre la base original)
    const escalaTexto = 1.1025;
    final r = 16.0 * f;
    final esBuffetYSabado = producto.esBuffet && esSabado;
    final estaAgotado = !producto.isAvailable;
    // Cinta "BUFFET" esquina superior izquierda (solo sábado): dejar hueco arriba del nombre
    final paddingTopTexto = (esBuffetYSabado && !estaAgotado)
        ? (4 * f + 11 * f * escalaTexto + 4 * f)
        : 12 * f;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: estaAgotado ? null : onTap, // Deshabilitar si está agotado
        borderRadius: BorderRadius.circular(r),
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
            borderRadius: BorderRadius.circular(r),
            border: Border.all(
              color: estaAgotado
                  ? Colors.grey.shade700
                  : iluminarBorde
                      ? const Color(0xFF00D9A5)
                      : esBuffetYSabado
                          ? const Color(0xFFFFD700)
                          : const Color(0xFF0F3460),
              width: (iluminarBorde
                      ? 3.0
                      : esBuffetYSabado
                          ? 2.5
                          : 1.5) *
                  f,
            ),
            boxShadow: [
              BoxShadow(
                color: estaAgotado
                    ? Colors.transparent
                    : iluminarBorde
                        ? const Color(0xFF00D9A5).withValues(alpha: 0.55)
                        : esBuffetYSabado
                            ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.2),
                blurRadius: (iluminarBorde
                        ? 16.0
                        : esBuffetYSabado
                            ? 12.0
                            : 8.0) *
                    f,
                offset: Offset(0, 4 * f),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Contenido principal
              Opacity(
                opacity: estaAgotado ? 0.4 : 1.0,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12 * f, paddingTopTexto, 12 * f, 12 * f),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          producto.nombre,
                          style: TextStyle(
                            color: estaAgotado ? Colors.grey : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14 * f * escalaTexto,
                            height: 1.2,
                          ),
                          maxLines: 8,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: 6 * f),
                      // Precio y estrella buffet a la derecha (sustituye al indicador cocina/barra)
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
                              fontSize: 18 * f * escalaTexto,
                              decoration: estaAgotado ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const Spacer(),
                          if (producto.esBuffet && !estaAgotado)
                            Container(
                              padding: EdgeInsets.all(4 * f),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                                    blurRadius: 8 * f,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 14 * f,
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
                        padding: EdgeInsets.symmetric(
                          horizontal: 16 * f,
                          vertical: 8 * f,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE94560),
                          borderRadius: BorderRadius.circular(8 * f),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE94560).withValues(alpha: 0.5),
                              blurRadius: 12 * f,
                              spreadRadius: 2 * f,
                            ),
                          ],
                        ),
                        child: Text(
                          'AGOTADO',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14 * f * escalaTexto,
                            letterSpacing: 1.5 * f,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Indicador "INCLUIDO" si es buffet y sábado
              if (esBuffetYSabado && !estaAgotado)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8 * f,
                      vertical: 4 * f,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(14 * f),
                        bottomRight: Radius.circular(12 * f),
                      ),
                    ),
                    child: Text(
                      'BUFFET',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 9 * f * escalaTexto,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5 * f,
                      ),
                    ),
                  ),
                ),

              // Cantidad pendiente en el carrito (app móvil)
              if (cantidadEnCarrito > 0 && !estaAgotado)
                Positioned(
                  top: 6 * f,
                  right: 6 * f,
                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: 22 * f,
                      minHeight: 22 * f,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 6 * f,
                      vertical: 2 * f,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE94560),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE94560).withValues(alpha: 0.45),
                          blurRadius: 6 * f,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$cantidadEnCarrito',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12 * f * escalaTexto,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),

              // Indicador de stock disponible (si usa inventario y hay stock)
              if (producto.usarInventario && !estaAgotado && producto.stockDisponible > 0)
                Positioned(
                  bottom: 8 * f,
                  right: 8 * f,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8 * f,
                      vertical: 4 * f,
                    ),
                    decoration: BoxDecoration(
                      color: producto.stockDisponible <= 5
                          ? const Color(0xFFFF6B6B).withValues(alpha: 0.9)
                          : const Color(0xFF00D9A5).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12 * f),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4 * f,
                          offset: Offset(0, 2 * f),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 12 * f,
                          color: producto.stockDisponible <= 5
                              ? Colors.white
                              : Colors.black87,
                        ),
                        SizedBox(width: 4 * f),
                        Text(
                          'Quedan ${producto.stockDisponible}',
                          style: TextStyle(
                            color: producto.stockDisponible <= 5
                                ? Colors.white
                                : Colors.black87,
                            fontSize: 10 * f * escalaTexto,
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
}
