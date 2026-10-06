import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/navigation/app_router.dart';
import '../../domain/entities/item_lista_compra.dart';
import '../providers/lista_compra_provider.dart';

/// Catálogo de productos de una zona (cocina o sala).
class HacerListaPage extends StatefulWidget {
  final ZonaListaCompra zona;

  const HacerListaPage({super.key, required this.zona});

  @override
  State<HacerListaPage> createState() => _HacerListaPageState();
}

class _HacerListaPageState extends State<HacerListaPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListaCompraProvider>().cargar();
    });
  }

  Future<void> _dialogoItem({ItemListaCompra? existente}) async {
    final nombreCtrl = TextEditingController(text: existente?.nombre ?? '');
    final cantidadCtrl =
        TextEditingController(text: existente?.cantidad ?? '');
    var zona = existente?.zona ?? widget.zona;
    var supermercadoId = existente?.supermercadoId;
    final provider = context.read<ListaCompraProvider>();
    final idsSuper = provider.supermercados.map((s) => s.id).toSet();
    if (supermercadoId != null && !idsSuper.contains(supermercadoId)) {
      supermercadoId = null;
    }

    final resultado = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              backgroundColor: const Color(0xFF16213E),
              title: Text(
                existente == null ? 'Añadir producto' : 'Editar producto',
                style: const TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nombreCtrl,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Zona',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ZonaListaCompra>(
                        segments: const [
                          ButtonSegment(
                            value: ZonaListaCompra.cocina,
                            label: Text('Cocina'),
                            icon: Icon(Icons.kitchen_outlined, size: 16),
                          ),
                          ButtonSegment(
                            value: ZonaListaCompra.sala,
                            label: Text('Sala'),
                            icon: Icon(Icons.table_restaurant_outlined, size: 16),
                          ),
                        ],
                        selected: {zona},
                        onSelectionChanged: (sel) {
                          setLocal(() => zona = sel.first);
                        },
                        style: ButtonStyle(
                          foregroundColor:
                              WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.black87;
                            }
                            return Colors.white70;
                          }),
                          backgroundColor:
                              WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return const Color(0xFFFFB74D);
                            }
                            return const Color(0xFF0D0D0D);
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      value: supermercadoId,
                      dropdownColor: const Color(0xFF16213E),
                      decoration: const InputDecoration(
                        labelText: 'Comprar en',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      style: const TextStyle(color: Colors.white),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Sin asignar'),
                        ),
                        ...provider.supermercados.map(
                          (s) => DropdownMenuItem<int?>(
                            value: s.id,
                            child: Text(s.nombre),
                          ),
                        ),
                      ],
                      onChanged: (v) => setLocal(() => supermercadoId = v),
                    ),
                    TextField(
                      controller: cantidadCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Nota cantidad (opcional)',
                        labelStyle: TextStyle(color: Colors.white70),
                        hintText: 'p. ej. 2 packs, 1 caja…',
                        hintStyle: TextStyle(color: Colors.white38),
                      ),
                    ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: [
                if (existente != null)
                  IconButton(
                    onPressed: () => Navigator.pop(ctx, 'eliminar'),
                    tooltip: 'Eliminar',
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFE94560),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(ctx, 'cancelar'),
                      tooltip: 'Cancelar',
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx, 'guardar'),
                      tooltip: 'Guardar',
                      icon: const Icon(Icons.check, color: Color(0xFF66BB6A)),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (resultado == 'eliminar' && existente != null) {
      await _confirmarBorrar(existente);
      return;
    }
    if (resultado != 'guardar') return;

    final exito = existente == null
        ? await provider.anadir(
            nombre: nombreCtrl.text,
            cantidad: cantidadCtrl.text,
            zona: zona,
            supermercadoId: supermercadoId,
          )
        : await provider.editar(
            existente,
            nombre: nombreCtrl.text,
            cantidad: cantidadCtrl.text,
            zona: zona,
            supermercadoId: supermercadoId,
            clearSupermercado: supermercadoId == null,
          );

    if (!mounted) return;
    if (!exito && provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!)),
      );
    }
  }

  Future<void> _confirmarBorrar(ItemListaCompra item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Eliminar', style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Eliminar "${item.nombre}" de la lista?\n'
          'Se borrará también del catálogo.',
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
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final provider = context.read<ListaCompraProvider>();
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
        onPressed: () => _dialogoItem(),
        backgroundColor: const Color(0xFFFFB74D),
        foregroundColor: Colors.black87,
        icon: const Icon(Icons.add),
        label: const Text('Añadir'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              titulo: widget.zona.etiqueta.toUpperCase(),
              onBack: () => context.go(AppRoutes.listaCompraHacer),
              onRefresh: () => context.read<ListaCompraProvider>().cargar(),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                'Marca qué hay que comprar. Asigna el súper al crear o editar. '
                'Mantén pulsado para ordenar.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
            Expanded(
              child: Consumer<ListaCompraProvider>(
                builder: (context, provider, _) {
                  if (provider.cargando && provider.items.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (provider.error != null && provider.items.isEmpty) {
                    return _ErrorView(
                      mensaje: provider.error!,
                      onRetry: provider.cargar,
                    );
                  }
                  final items = provider.itemsDe(widget.zona);
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        'No hay productos en ${widget.zona.etiqueta.toLowerCase()}.\n'
                        'Pulsa Añadir para guardar productos.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 15,
                        ),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: provider.cargar,
                    child: ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                      itemCount: items.length,
                      proxyDecorator: (child, index, animation) {
                        return Material(
                          color: Colors.transparent,
                          elevation: 6,
                          child: child,
                        );
                      },
                      onReorder: (oldIndex, newIndex) {
                        provider.reordenar(widget.zona, oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Padding(
                          key: ValueKey(item.id),
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ReorderableDelayedDragStartListener(
                            index: index,
                            child: _CatalogTile(
                              item: item,
                              nombreSuper:
                                  provider.nombreSupermercado(item.supermercadoId),
                              onEdit: () => _dialogoItem(existente: item),
                              onToggleHayQueComprar: (v) =>
                                  provider.marcarHayQueComprar(item, v),
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

class _Header extends StatelessWidget {
  final String titulo;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const _Header({
    required this.titulo,
    required this.onBack,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      color: const Color(0xFF16213E),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
          ),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          IconButton(
            onPressed: onRefresh,
            tooltip: 'Actualizar desde el VPS',
            icon: const Icon(Icons.refresh, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _CatalogTile extends StatelessWidget {
  final ItemListaCompra item;
  final String? nombreSuper;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggleHayQueComprar;

  const _CatalogTile({
    required this.item,
    required this.nombreSuper,
    required this.onEdit,
    required this.onToggleHayQueComprar,
  });

  @override
  Widget build(BuildContext context) {
    final detalle = [
      if (item.cantidad.isNotEmpty) item.cantidad,
      if (item.hayQueComprar) 'Hay que comprar',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.hayQueComprar
              ? const Color(0xFFFFB74D).withValues(alpha: 0.45)
              : Colors.white24,
        ),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, right: 2),
            child: Icon(Icons.drag_handle, color: Colors.white38),
          ),
          Switch(
            value: item.hayQueComprar,
            activeThumbColor: const Color(0xFFFFB74D),
            onChanged: onToggleHayQueComprar,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (detalle.isNotEmpty)
                  Text(
                    detalle,
                    style: TextStyle(
                      color: item.hayQueComprar
                          ? const Color(0xFFFFB74D)
                          : Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                Text(
                  nombreSuper ?? 'Sin súper asignado',
                  style: TextStyle(
                    color: nombreSuper != null
                        ? const Color(0xFF4FC3F7)
                        : Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String mensaje;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.mensaje, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: Colors.white38, size: 48),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
