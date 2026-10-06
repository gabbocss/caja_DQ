import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/navigation/app_router.dart';
import '../../domain/entities/item_lista_compra.dart';
import '../providers/lista_compra_provider.dart';

/// Compra en desktop: lista pendiente (solo lectura) + opciones del hub.
class CompraDesktopPage extends StatefulWidget {
  const CompraDesktopPage({super.key});

  @override
  State<CompraDesktopPage> createState() => _CompraDesktopPageState();
}

class _CompraDesktopPageState extends State<CompraDesktopPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ListaCompraProvider>().cargar();
    });
  }

  Future<void> _quitarDeLista(ItemListaCompra item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Quitar de la lista',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Quitar «${item.nombre}» de la lista de compra?\n\n'
          'El producto sigue en el catálogo.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE94560),
            ),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final provider = context.read<ListaCompraProvider>();
    final exito = await provider.marcarHayQueComprar(item, false);
    if (!mounted) return;
    if (!exito && provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Consumer<ListaCompraProvider>(
        builder: (context, provider, _) {
          final pendientes = provider.pendientesCompra;
          final hayLista = provider.enListaCompra.isNotEmpty;
          final trailingComprar = !hayLista
              ? null
              : provider.cargando && pendientes.isEmpty
                  ? '…'
                  : pendientes.isNotEmpty
                      ? '${pendientes.length}'
                      : null;

          return Column(
            children: [
              _Header(
                cargando: provider.cargando,
                onRefresh: () => provider.cargar(),
              ),
              if (provider.error != null)
                Container(
                  width: double.infinity,
                  color: const Color(0xFF5D1A1A),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          provider.error!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      TextButton(
                        onPressed: () => provider.cargar(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: 340,
                      child: _ListaPanel(
                        items: pendientes,
                        onQuitar: _quitarDeLista,
                        nombreSuper: provider.nombreSupermercado,
                      ),
                    ),
                    const VerticalDivider(width: 1, color: Color(0xFF0F3460)),
                    Expanded(
                      child: _OpcionesPanel(
                        hayLista: hayLista,
                        pendientes: pendientes.length,
                        trailingComprar: trailingComprar,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool cargando;
  final VoidCallback onRefresh;

  const _Header({
    required this.cargando,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        border: Border(bottom: BorderSide(color: Color(0xFF0F3460))),
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_cart, color: Color(0xFFE94560)),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compra',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Pendientes de compra y acceso a la lista',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: cargando ? null : onRefresh,
            tooltip: 'Actualizar',
            icon: cargando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _ListaPanel extends StatelessWidget {
  final List<ItemListaCompra> items;
  final Future<void> Function(ItemListaCompra) onQuitar;
  final String? Function(int?) nombreSuper;

  const _ListaPanel({
    required this.items,
    required this.onQuitar,
    required this.nombreSuper,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No hay productos pendientes.\nMárcalos en «Hacer lista».',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final superNombre = nombreSuper(item.supermercadoId);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      [
                        if (item.cantidad.isNotEmpty) item.cantidad,
                        superNombre ?? 'Sin súper',
                      ].join(' · '),
                      style: TextStyle(
                        color: superNombre != null
                            ? const Color(0xFF4FC3F7)
                            : Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Quitar de la lista',
                onPressed: () => onQuitar(item),
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFE94560),
                  size: 20,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OpcionesPanel extends StatelessWidget {
  final bool hayLista;
  final int pendientes;
  final String? trailingComprar;

  const _OpcionesPanel({
    required this.hayLista,
    required this.pendientes,
    required this.trailingComprar,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _Tile(
          titulo: 'Comprar',
          subtitulo: hayLista
              ? (pendientes > 0
                  ? '$pendientes pendiente${pendientes == 1 ? '' : 's'}'
                  : 'Marcar lo comprado y vaciar al terminar')
              : 'Marcar lo comprado y vaciar al terminar',
          icono: Icons.shopping_cart_outlined,
          color: const Color(0xFF66BB6A),
          trailingText: trailingComprar,
          onTap: () => context.go(AppRoutes.listaCompraComprar),
        ),
        const SizedBox(height: 12),
        _Tile(
          titulo: 'Hacer lista',
          subtitulo: 'Catálogo, súper y qué hay que comprar',
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
          onTap: () => context.go(AppRoutes.listaCompraSupermercados),
        ),
      ],
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
