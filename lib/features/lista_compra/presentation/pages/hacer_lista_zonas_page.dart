import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../pedidos/presentation/widgets/barra_busqueda_pedidos.dart';
import '../../domain/entities/item_lista_compra.dart';
import '../providers/lista_compra_provider.dart';

/// Elige zona (cocina / sala) antes de ver el catálogo.
class HacerListaZonasPage extends StatefulWidget {
  const HacerListaZonasPage({super.key});

  @override
  State<HacerListaZonasPage> createState() => _HacerListaZonasPageState();
}

class _HacerListaZonasPageState extends State<HacerListaZonasPage> {
  String _textoBusqueda = '';
  final TextEditingController _busquedaController = TextEditingController();
  final FocusNode _busquedaFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ListaCompraProvider>().cargar();
    });
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    _busquedaFocus.dispose();
    super.dispose();
  }

  void _limpiarBusqueda() {
    _busquedaController.clear();
    _busquedaFocus.unfocus();
    setState(() => _textoBusqueda = '');
  }

  List<ItemListaCompra> _filtrarTodos(List<ItemListaCompra> items) {
    final q = _textoBusqueda.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((i) => i.nombre.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final buscando = _textoBusqueda.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(onBack: () => context.go(AppRoutes.listaCompra)),
            BarraBusquedaPedidos(
              controller: _busquedaController,
              focusNode: _busquedaFocus,
              hintText: 'Buscar en todos los productos...',
              textoActual: _textoBusqueda,
              onChanged: (value) => setState(() => _textoBusqueda = value),
              onLimpiar: _limpiarBusqueda,
              cerrarConEscape: true,
            ),
            Expanded(
              child: Consumer<ListaCompraProvider>(
                builder: (context, provider, _) {
                  if (buscando) {
                    final resultados = _filtrarTodos(provider.items);
                    if (resultados.isEmpty) {
                      return const Center(
                        child: Text(
                          'Ningún producto coincide',
                          style: TextStyle(color: Colors.white54, fontSize: 15),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      itemCount: resultados.length,
                      itemBuilder: (context, index) {
                        final item = resultados[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ResultadoBusquedaTile(
                            item: item,
                            nombreSuper: provider.nombreSupermercado(
                              item.supermercadoId,
                            ),
                            onTap: () => context.go(
                              AppRoutes.listaCompraHacerZona(item.zona),
                            ),
                            onToggleHayQueComprar: (v) =>
                                provider.marcarHayQueComprar(item, v),
                          ),
                        );
                      },
                    );
                  }

                  final cocina = provider.itemsDe(ZonaListaCompra.cocina);
                  final sala = provider.itemsDe(ZonaListaCompra.sala);
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _ZonaTile(
                        titulo: 'Cocina',
                        subtitulo: cocina.isEmpty
                            ? 'Productos de cocina'
                            : '${cocina.length} producto${cocina.length == 1 ? '' : 's'}',
                        icono: Icons.kitchen_outlined,
                        onTap: () => context.go(
                          AppRoutes.listaCompraHacerZona(ZonaListaCompra.cocina),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ZonaTile(
                        titulo: 'Sala',
                        subtitulo: sala.isEmpty
                            ? 'Productos de sala'
                            : '${sala.length} producto${sala.length == 1 ? '' : 's'}',
                        icono: Icons.table_restaurant_outlined,
                        onTap: () => context.go(
                          AppRoutes.listaCompraHacerZona(ZonaListaCompra.sala),
                        ),
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
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

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
          const Expanded(
            child: Text(
              'HACER LISTA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultadoBusquedaTile extends StatelessWidget {
  final ItemListaCompra item;
  final String? nombreSuper;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleHayQueComprar;

  const _ResultadoBusquedaTile({
    required this.item,
    required this.nombreSuper,
    required this.onTap,
    required this.onToggleHayQueComprar,
  });

  @override
  Widget build(BuildContext context) {
    final detalle = [
      item.zona.etiqueta,
      if (item.cantidad.isNotEmpty) item.cantidad,
      if (item.hayQueComprar) 'Hay que comprar',
    ].join(' · ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
              Icon(
                Icons.chevron_right,
                color: const Color(0xFFFFB74D).withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZonaTile extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final VoidCallback onTap;

  const _ZonaTile({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFFFB74D);
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
                      style: const TextStyle(
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
              Icon(Icons.chevron_right, color: color.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}
