import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/navigation/app_router.dart';
import '../../domain/entities/item_lista_compra.dart';
import '../../domain/entities/unidad_medida.dart';
import '../providers/lista_compra_provider.dart';
import '../widgets/dialogo_precio_producto.dart';

/// Catálogo de productos + unidad + precios por súper.
class HacerListaPage extends StatefulWidget {
  const HacerListaPage({super.key});

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
    final contenidoCtrl = TextEditingController(
      text: existente?.contenidoCantidad?.toString() ?? '',
    );
    final minimaCtrl = TextEditingController(
      text: '${existente?.cantidadMinima ?? 1}',
    );
    var unidadBase = existente?.unidadBase ?? UnidadBase.unidad;
    var contenidoUnidad = existente?.contenidoUnidad ??
        ContenidoUnidad.paraBase(unidadBase).first;
    final provider = context.read<ListaCompraProvider>();

    final ok = await showDialog<bool>(
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
                    TextField(
                      controller: cantidadCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Nota cantidad (opcional)',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                    TextField(
                      controller: minimaCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Cantidad mínima a comprar',
                        labelStyle: TextStyle(color: Colors.white70),
                        hintText: '1, 2, 3…',
                        hintStyle: TextStyle(color: Colors.white38),
                        helperText:
                            'Envases/unidades que sueles comprar de este producto',
                        helperStyle: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Se compra / compara por',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<UnidadBase>(
                        segments: const [
                          ButtonSegment(
                            value: UnidadBase.kilo,
                            label: Text('Kilo'),
                            icon: Icon(Icons.scale, size: 16),
                          ),
                          ButtonSegment(
                            value: UnidadBase.litro,
                            label: Text('Litro'),
                            icon: Icon(Icons.water_drop_outlined, size: 16),
                          ),
                          ButtonSegment(
                            value: UnidadBase.unidad,
                            label: Text('Unidad'),
                            icon: Icon(Icons.tag, size: 16),
                          ),
                        ],
                        selected: {unidadBase},
                        onSelectionChanged: (sel) {
                          final v = sel.first;
                          setLocal(() {
                            unidadBase = v;
                            contenidoUnidad =
                                ContenidoUnidad.paraBase(v).first;
                          });
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
                    if (unidadBase == UnidadBase.unidad)
                      TextField(
                        controller: contenidoCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Unidades por envase (opcional)',
                          labelStyle: TextStyle(color: Colors.white70),
                          hintText: '1',
                          hintStyle: TextStyle(color: Colors.white38),
                        ),
                      )
                    else ...[
                      TextField(
                        controller: contenidoCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: unidadBase == UnidadBase.litro
                              ? 'Tamaño del envase'
                              : 'Peso del envase',
                          labelStyle: const TextStyle(color: Colors.white70),
                          hintText: unidadBase == UnidadBase.litro
                              ? '750'
                              : '500',
                          hintStyle: const TextStyle(color: Colors.white38),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Medida del envase',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ContenidoUnidad>(
                          segments: ContenidoUnidad.paraBase(unidadBase)
                              .map(
                                (u) => ButtonSegment(
                                  value: u,
                                  label: Text(u.etiquetaLarga),
                                ),
                              )
                              .toList(),
                          selected: {
                            ContenidoUnidad.paraBase(unidadBase)
                                    .contains(contenidoUnidad)
                                ? contenidoUnidad
                                : ContenidoUnidad.paraBase(unidadBase).first,
                          },
                          onSelectionChanged: (sel) {
                            setLocal(() => contenidoUnidad = sel.first);
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
                                return const Color(0xFF4FC3F7);
                              }
                              return const Color(0xFF0D0D0D);
                            }),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      unidadBase == UnidadBase.litro
                          ? 'Los precios se compararán en €/L'
                          : unidadBase == UnidadBase.kilo
                              ? 'Los precios se compararán en €/kg'
                              : 'Los precios se compararán en €/unidad',
                      style: const TextStyle(
                        color: Color(0xFF66BB6A),
                        fontSize: 12,
                      ),
                    ),
                  ],
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
            );
          },
        );
      },
    );

    if (ok != true || !mounted) return;

    if (unidadBase == UnidadBase.unidad) {
      contenidoUnidad = ContenidoUnidad.ud;
    }

    final contenido = double.tryParse(
      contenidoCtrl.text.trim().replaceAll(',', '.'),
    );
    final minima = int.tryParse(minimaCtrl.text.trim()) ?? 1;

    final exito = existente == null
        ? await provider.anadir(
            nombre: nombreCtrl.text,
            cantidad: cantidadCtrl.text,
            unidadBase: unidadBase,
            contenidoCantidad: contenido,
            contenidoUnidad: contenidoUnidad,
            cantidadMinima: minima,
          )
        : await provider.editar(
            existente,
            nombre: nombreCtrl.text,
            cantidad: cantidadCtrl.text,
            unidadBase: unidadBase,
            contenidoCantidad: contenido,
            clearContenido: contenidoCtrl.text.trim().isEmpty,
            contenidoUnidad: contenidoUnidad,
            cantidadMinima: minima,
          );

    if (!mounted) return;
    if (!exito && provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!)),
      );
    }
  }

  Future<void> _dialogoPrecio(ItemListaCompra item) async {
    await mostrarDialogoPrecioProducto(
      context,
      item: item,
      supermercadoIdPreferido:
          context.read<ListaCompraProvider>().supermercadoActualId,
    );
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
              titulo: 'HACER LISTA',
              onBack: () => context.go(AppRoutes.listaCompra),
              onRefresh: () => context.read<ListaCompraProvider>().cargar(),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                'Marca qué hay que comprar. Usa € para guardar precios por '
                'súper (calcula €/L, €/kg o €/ud). Mantén pulsado para ordenar.',
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
                  if (provider.items.isEmpty) {
                    return const Center(
                      child: Text(
                        'El catálogo está vacío.\nPulsa Añadir para guardar productos.',
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
                      onReorder: (oldIndex, newIndex) {
                        provider.reordenar(oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final item = provider.items[index];
                        final precios = provider.preciosDeProducto(item.id);
                        return Padding(
                          key: ValueKey(item.id),
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ReorderableDelayedDragStartListener(
                            index: index,
                            child: _CatalogTile(
                              item: item,
                              preciosCount: precios.length,
                              mejorPrecio: precios.isEmpty
                                  ? null
                                  : precios
                                      .reduce(
                                        (a, b) => a.precioPorBase <
                                                b.precioPorBase
                                            ? a
                                            : b,
                                      )
                                      .precioPorBase,
                              onEdit: () => _dialogoItem(existente: item),
                              onPrecio: () => _dialogoPrecio(item),
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
  final int preciosCount;
  final double? mejorPrecio;
  final VoidCallback onEdit;
  final VoidCallback onPrecio;
  final ValueChanged<bool> onToggleHayQueComprar;

  const _CatalogTile({
    required this.item,
    required this.preciosCount,
    required this.mejorPrecio,
    required this.onEdit,
    required this.onPrecio,
    required this.onToggleHayQueComprar,
  });

  @override
  Widget build(BuildContext context) {
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
                Text(
                  '${item.unidadBase.etiqueta}'
                  '${item.contenidoCantidad != null ? ' · ${item.contenidoCantidad} ${item.contenidoUnidad.etiquetaLarga}' : ''}'
                  ' · Mín. ${item.cantidadMinima}'
                  '${item.hayQueComprar ? ' · Hay que comprar' : ''}',
                  style: TextStyle(
                    color: item.hayQueComprar
                        ? const Color(0xFFFFB74D)
                        : Colors.white54,
                    fontSize: 12,
                  ),
                ),
                if (mejorPrecio != null)
                  Text(
                    'Mejor: ${formatearPrecioPorBase(mejorPrecio, item.unidadBase)} ($preciosCount súper)',
                    style: const TextStyle(
                      color: Color(0xFF66BB6A),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onPrecio,
            tooltip: 'Guardar precio',
            icon: const Icon(Icons.euro, color: Color(0xFF66BB6A)),
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
