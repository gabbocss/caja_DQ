import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/navigation/app_router.dart';
import '../providers/lista_compra_provider.dart';

/// Hub móvil: Comprar / Hacer lista / Supermercados.
class ListaCompraHubPage extends StatefulWidget {
  const ListaCompraHubPage({super.key});

  @override
  State<ListaCompraHubPage> createState() => _ListaCompraHubPageState();
}

class _ListaCompraHubPageState extends State<ListaCompraHubPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ListaCompraProvider>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            Expanded(
              child: Consumer<ListaCompraProvider>(
                builder: (context, provider, _) {
                  final gasto = provider.gastoEstimadoMinimo;
                  final sinPrecio = provider.productosSinPrecioEnEstimacion;
                  final hayLista = provider.enListaCompra.isNotEmpty;
                  final trailing = !hayLista
                      ? null
                      : provider.cargando && gasto == 0 && sinPrecio == 0
                          ? '…'
                          : gasto > 0
                              ? '~ ${gasto.toStringAsFixed(2)} €'
                              : (sinPrecio > 0 ? 'Sin precios' : null);

                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _Tile(
                        titulo: 'Comprar',
                        subtitulo: hayLista
                            ? (sinPrecio > 0 && gasto > 0
                                ? 'Estimado con mínimas (faltan $sinPrecio sin precio)'
                                : sinPrecio > 0 && gasto == 0
                                    ? 'Marca precios para estimar el gasto'
                                    : 'Estimado con cantidades mínimas')
                            : 'Marcar lo comprado y vaciar al terminar',
                        icono: Icons.shopping_cart_outlined,
                        color: const Color(0xFF66BB6A),
                        trailingText: trailing,
                        onTap: () => context.go(AppRoutes.listaCompraComprar),
                      ),
                      const SizedBox(height: 12),
                      _Tile(
                        titulo: 'Hacer lista',
                        subtitulo: 'Catálogo, mínimas y qué hay que comprar',
                        icono: Icons.edit_note,
                        color: const Color(0xFFFFB74D),
                        onTap: () => context.go(AppRoutes.listaCompraHacer),
                      ),
                      const SizedBox(height: 12),
                      _Tile(
                        titulo: 'Supermercados',
                        subtitulo: 'Los súpers a los que sueles ir',
                        icono: Icons.storefront_outlined,
                        color: const Color(0xFF4FC3F7),
                        onTap: () =>
                            context.go(AppRoutes.listaCompraSupermercados),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go(AppRoutes.menus),
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF66BB6A).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shopping_basket_outlined,
              color: Color(0xFF66BB6A),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'LISTA DE LA COMPRA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Color color;
  final VoidCallback onTap;
  final String? trailingText;

  const _Tile({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.color,
    required this.onTap,
    this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icono, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingText != null) ...[
                const SizedBox(width: 8),
                Text(
                  trailingText!,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: color.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}
