import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/navigation/app_router.dart';
import '../../domain/entities/item_lista_compra.dart';
import '../providers/lista_compra_provider.dart';

/// Checklist de compra: elige súper y marca lo comprado.
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

                  final sid = provider.supermercadoActualId;
                  final pendientes =
                      provider.pendientesParaSupermercado(sid);
                  final comprados = provider.compradosParaSupermercado(sid);
                  final deEsteSuper = pendientes
                      .where((i) => i.supermercadoId == sid && sid != null)
                      .toList();
                  final sinAsignar = pendientes
                      .where((i) => i.supermercadoId == null)
                      .toList();
                  final otros = sid == null
                      ? pendientes
                          .where((i) => i.supermercadoId != null)
                          .toList()
                      : <ItemListaCompra>[];

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
                              child: Text('Todos'),
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Text(
                          sid == null
                              ? 'Viendo todos. Elige un súper para filtrar.'
                              : 'Mostrando productos de este súper y los sin asignar.',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: provider.cargar,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            children: [
                              if (sid != null && deEsteSuper.isNotEmpty) ...[
                                const _SeccionTitulo('En este súper'),
                                ...deEsteSuper.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _CheckTile(
                                      item: item,
                                      comprado: false,
                                      badge: provider
                                          .nombreSupermercado(item.supermercadoId),
                                      badgeColor: const Color(0xFF4FC3F7),
                                      onChanged: (v) => provider.marcarComprado(
                                        item,
                                        v ?? false,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              if (sid == null && otros.isNotEmpty) ...[
                                const _SeccionTitulo('Por comprar'),
                                ...otros.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _CheckTile(
                                      item: item,
                                      comprado: false,
                                      badge: provider
                                          .nombreSupermercado(item.supermercadoId),
                                      badgeColor: const Color(0xFF4FC3F7),
                                      onChanged: (v) => provider.marcarComprado(
                                        item,
                                        v ?? false,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              if (sinAsignar.isNotEmpty) ...[
                                if (deEsteSuper.isNotEmpty || otros.isNotEmpty)
                                  const SizedBox(height: 8),
                                const _SeccionTitulo('Sin súper asignado'),
                                ...sinAsignar.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _CheckTile(
                                      item: item,
                                      comprado: false,
                                      badge: 'Sin asignar',
                                      badgeColor: Colors.white38,
                                      onChanged: (v) => provider.marcarComprado(
                                        item,
                                        v ?? false,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              if (comprados.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const _SeccionTitulo('Ya comprado'),
                                ...comprados.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _CheckTile(
                                      item: item,
                                      comprado: true,
                                      badge: provider.nombreSupermercado(
                                            item.supermercadoId,
                                          ) ??
                                          'Sin asignar',
                                      badgeColor: Colors.white38,
                                      onChanged: (v) => provider.marcarComprado(
                                        item,
                                        v ?? false,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              if (pendientes.isEmpty && comprados.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text(
                                    'Nada que comprar en este súper.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                ),
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
  final String? badge;
  final Color? badgeColor;
  final ValueChanged<bool?> onChanged;

  const _CheckTile({
    required this.item,
    required this.comprado,
    required this.onChanged,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final subtitulo = item.cantidad.isEmpty ? null : item.cantidad;

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
        subtitle: subtitulo == null
            ? null
            : Text(
                subtitulo,
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
