import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/navigation/app_router.dart';
import '../../domain/entities/item_lista_compra.dart';
import '../../domain/entities/precio_producto.dart';
import '../../domain/entities/unidad_medida.dart';
import '../providers/lista_compra_provider.dart';
import '../widgets/dialogo_precio_producto.dart';

/// Checklist de compra: elige súper y prioriza lo más barato ahí.
class ComprarPage extends StatefulWidget {
  const ComprarPage({super.key});

  @override
  State<ComprarPage> createState() => _ComprarPageState();
}

class _ComprarPageState extends State<ComprarPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListaCompraProvider>().cargar();
    });
  }

  Future<void> _editarPrecio(ItemListaCompra item) async {
    final provider = context.read<ListaCompraProvider>();
    await mostrarDialogoPrecioProducto(
      context,
      item: item,
      supermercadoIdPreferido: provider.supermercadoActualId,
    );
  }

  Future<void> _confirmarVaciar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Vaciar lista de compra',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Seguro? Se quitarán todos de «hay que comprar» y se desmarcarán '
          'los comprados.\n\nEl catálogo de productos NO se borra.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final provider = context.read<ListaCompraProvider>();
    final exito = await provider.vaciarCompra();
    if (!mounted) return;
    if (!exito && provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lista de compra vaciada. El catálogo sigue intacto.'),
        ),
      );
    }
  }

  String? _textoPrecioAqui(PrecioProducto? p, ItemListaCompra item) {
    if (p == null) return null;
    return formatearPrecioCompleto(
      precioEnvase: p.precioEnvase,
      precioPorBase: p.precioPorBase,
      unidadBase: item.unidadBase,
    );
  }

  String? _textoComparativa(ComparativaPrecio c) {
    if (c.sinDatos) return 'Sin precios guardados';
    final lineas = <String>[];
    if (c.precioAqui != null) {
      lineas.add(
        'Aquí ${formatearPrecioCompleto(
          precioEnvase: c.precioAqui!.precioEnvase,
          precioPorBase: c.precioAqui!.precioPorBase,
          unidadBase: c.producto.unidadBase,
        )}',
      );
    }
    if (c.mejorPrecio != null && !c.esMasBaratoAqui) {
      lineas.add(
        'Mejor ${formatearPrecioCompleto(
          precioEnvase: c.mejorPrecio!.precioEnvase,
          precioPorBase: c.mejorPrecio!.precioPorBase,
          unidadBase: c.producto.unidadBase,
        )}'
        '${c.mejorSupermercado != null ? ' (${c.mejorSupermercado!.nombre})' : ''}',
      );
    } else if (c.mejorPrecio != null && c.precioAqui == null) {
      lineas.add(
        'Mejor ${formatearPrecioCompleto(
          precioEnvase: c.mejorPrecio!.precioEnvase,
          precioPorBase: c.mejorPrecio!.precioPorBase,
          unidadBase: c.producto.unidadBase,
        )}'
        '${c.mejorSupermercado != null ? ' en ${c.mejorSupermercado!.nombre}' : ''}',
      );
    }
    return lineas.isEmpty ? null : lineas.join('\n');
  }

  PrecioProducto? _precioEnActual(
    ListaCompraProvider provider,
    ItemListaCompra item,
  ) {
    final sid = provider.supermercadoActualId;
    if (sid == null) return null;
    for (final p in provider.preciosDeProducto(item.id)) {
      if (p.supermercadoId == sid) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              titulo: 'COMPRAR',
              onBack: () => context.go(AppRoutes.listaCompra),
              onRefresh: () => context.read<ListaCompraProvider>().cargar(),
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

                  if (!provider.hayAlgoEnCompra) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No hay productos para comprar.\n'
                          'Ve a «Hacer lista» y activa «Hay que comprar».',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 15),
                        ),
                      ),
                    );
                  }

                  final pendientes = provider.pendientesConComparativa;
                  final comprados = provider.compradosCompra;
                  final masBaratos =
                      pendientes.where((c) => c.esMasBaratoAqui).toList();
                  final otros =
                      pendientes.where((c) => !c.esMasBaratoAqui).toList();

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: DropdownButtonFormField<int?>(
                          value: provider.supermercadoActualId,
                          dropdownColor: const Color(0xFF16213E),
                          decoration: const InputDecoration(
                            labelText: 'Estoy en',
                            labelStyle: TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Color(0xFF16213E),
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(color: Colors.white),
                          hint: const Text(
                            'Elige supermercado',
                            style: TextStyle(color: Colors.white54),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Sin seleccionar'),
                            ),
                            ...provider.supermercados.map(
                              (s) => DropdownMenuItem<int?>(
                                value: s.id,
                                child: Text(s.nombre),
                              ),
                            ),
                          ],
                          onChanged: provider.seleccionarSupermercado,
                        ),
                      ),
                      if (provider.supermercadoActualId == null)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Text(
                            'Selecciona el súper para ver qué te conviene comprar aquí.',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                        ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: provider.cargar,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            children: [
                              if (masBaratos.isNotEmpty) ...[
                                const _SeccionTitulo(
                                  'Más barato aquí — cómpralo',
                                ),
                                ...masBaratos.map(
                                  (c) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _CheckTile(
                                      item: c.producto,
                                      comprado: false,
                                      subtitulo: _textoPrecioAqui(
                                            c.precioAqui,
                                            c.producto,
                                          ) ??
                                          _textoComparativa(c),
                                      badge: 'Aquí',
                                      badgeColor: const Color(0xFF66BB6A),
                                      onChanged: (v) =>
                                          provider.marcarComprado(
                                        c.producto,
                                        v ?? false,
                                      ),
                                      onEditarPrecio: () =>
                                          _editarPrecio(c.producto),
                                    ),
                                  ),
                                ),
                              ],
                              if (otros.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const _SeccionTitulo('Por comprar'),
                                ...otros.map(
                                  (c) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _CheckTile(
                                      item: c.producto,
                                      comprado: false,
                                      subtitulo: _textoComparativa(c),
                                      badge: c.sinDatos
                                          ? 'Sin precio'
                                          : (c.mejorSupermercado?.nombre),
                                      badgeColor: c.sinDatos
                                          ? Colors.white38
                                          : const Color(0xFFFFB74D),
                                      onChanged: (v) =>
                                          provider.marcarComprado(
                                        c.producto,
                                        v ?? false,
                                      ),
                                      onEditarPrecio: () =>
                                          _editarPrecio(c.producto),
                                    ),
                                  ),
                                ),
                              ],
                              if (comprados.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const _SeccionTitulo('Ya comprado'),
                                ...comprados.map(
                                  (item) {
                                    final precio =
                                        _precioEnActual(provider, item);
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: _CheckTile(
                                        item: item,
                                        comprado: true,
                                        subtitulo: _textoPrecioAqui(
                                          precio,
                                          item,
                                        ),
                                        onChanged: (v) =>
                                            provider.marcarComprado(
                                          item,
                                          v ?? false,
                                        ),
                                        onEditarPrecio: () =>
                                            _editarPrecio(item),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _confirmarVaciar,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFE94560),
                              side: const BorderSide(color: Color(0xFFE94560)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.cleaning_services_outlined),
                            label: const Text('Vaciar lista de compra'),
                          ),
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

class _SeccionTitulo extends StatelessWidget {
  final String texto;
  const _SeccionTitulo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        texto,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  final ItemListaCompra item;
  final bool comprado;
  final String? subtitulo;
  final String? badge;
  final Color? badgeColor;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onEditarPrecio;

  const _CheckTile({
    required this.item,
    required this.comprado,
    required this.onChanged,
    required this.onEditarPrecio,
    this.subtitulo,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: comprado ? const Color(0xFF1A1A1A) : const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: comprado
              ? Colors.white24
              : const Color(0xFF66BB6A).withValues(alpha: 0.35),
        ),
      ),
      child: CheckboxListTile(
        value: comprado,
        onChanged: onChanged,
        activeColor: const Color(0xFF66BB6A),
        controlAffinity: ListTileControlAffinity.leading,
        secondary: IconButton(
          onPressed: onEditarPrecio,
          tooltip: 'Modificar precio',
          icon: const Icon(Icons.euro, color: Color(0xFF66BB6A)),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.nombre,
                style: TextStyle(
                  color: comprado ? Colors.white38 : Colors.white,
                  decoration: comprado ? TextDecoration.lineThrough : null,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (badgeColor ?? Colors.white38).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    color: badgeColor ?? Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: (subtitulo == null && item.cantidad.isEmpty)
            ? null
            : Text(
                [
                  if (subtitulo != null) subtitulo!,
                  if (item.cantidad.isNotEmpty) item.cantidad,
                ].join('\n'),
                style: TextStyle(
                  color: comprado ? Colors.white24 : Colors.white54,
                  fontSize: 12,
                ),
              ),
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
