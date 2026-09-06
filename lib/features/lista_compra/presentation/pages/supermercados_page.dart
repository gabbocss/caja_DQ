import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/navigation/app_router.dart';
import '../../domain/entities/supermercado.dart';
import '../providers/supermercados_provider.dart';

/// Gestión del catálogo de supermercados en el VPS.
class SupermercadosPage extends StatefulWidget {
  const SupermercadosPage({super.key});

  @override
  State<SupermercadosPage> createState() => _SupermercadosPageState();
}

class _SupermercadosPageState extends State<SupermercadosPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupermercadosProvider>().cargar();
    });
  }

  Future<void> _dialogo({Supermercado? existente}) async {
    final ctrl = TextEditingController(text: existente?.nombre ?? '');
    final provider = context.read<SupermercadosProvider>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: Text(
          existente == null ? 'Añadir supermercado' : 'Editar supermercado',
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Nombre',
            labelStyle: TextStyle(color: Colors.white70),
            hintText: 'Ej. Mercadona, Lidl…',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;
    final exito = existente == null
        ? await provider.anadir(ctrl.text)
        : await provider.editar(existente, ctrl.text);
    if (!mounted) return;
    if (!exito && provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!)),
      );
    }
  }

  Future<void> _confirmarBorrar(Supermercado item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Eliminar', style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Eliminar "${item.nombre}"?\n'
          '(Más adelante, si hay productos asignados a este súper, habrá que '
          'revisarlos.)',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final provider = context.read<SupermercadosProvider>();
    final exito = await provider.eliminar(item);
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _dialogo(),
        backgroundColor: const Color(0xFF4FC3F7),
        foregroundColor: Colors.black87,
        icon: const Icon(Icons.add),
        label: const Text('Añadir'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              color: const Color(0xFF16213E),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go(AppRoutes.listaCompra),
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                  ),
                  const Expanded(
                    child: Text(
                      'SUPERMERCADOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        context.read<SupermercadosProvider>().cargar(),
                    tooltip: 'Actualizar desde el VPS',
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                'Añade los supermercados a los que sueles ir. '
                'Mantén pulsado para reordenar. Más adelante podrás asignar '
                'productos a cada uno.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
            Expanded(
              child: Consumer<SupermercadosProvider>(
                builder: (context, provider, _) {
                  if (provider.cargando && provider.items.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (provider.error != null && provider.items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              provider.error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: provider.cargar,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (provider.items.isEmpty) {
                    return const Center(
                      child: Text(
                        'No hay supermercados.\nPulsa Añadir para empezar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 15),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: provider.cargar,
                    child: ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                      itemCount: provider.items.length,
                      proxyDecorator: (child, index, animation) {
                        return Material(
                          color: Colors.transparent,
                          elevation: 6,
                          child: child,
                        );
                      },
                      onReorder: provider.reordenar,
                      itemBuilder: (context, index) {
                        final item = provider.items[index];
                        return Padding(
                          key: ValueKey(item.id),
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ReorderableDelayedDragStartListener(
                            index: index,
                            child: _Tile(
                              item: item,
                              onEdit: () => _dialogo(existente: item),
                              onDelete: () => _confirmarBorrar(item),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final Supermercado item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _Tile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4FC3F7).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, right: 8),
            child: Icon(Icons.drag_handle, color: Colors.white38),
          ),
          const Icon(Icons.storefront_outlined, color: Color(0xFF4FC3F7)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.nombre,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: Colors.white70),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: Color(0xFFE94560)),
          ),
        ],
      ),
    );
  }
}
