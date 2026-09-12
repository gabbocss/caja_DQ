import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/navigation/app_router.dart';
import '../../domain/entities/item_lista_compra.dart';
import '../providers/lista_compra_provider.dart';

/// Elige zona (cocina / sala) antes de ver el catálogo.
class HacerListaZonasPage extends StatefulWidget {
  const HacerListaZonasPage({super.key});

  @override
  State<HacerListaZonasPage> createState() => _HacerListaZonasPageState();
}

class _HacerListaZonasPageState extends State<HacerListaZonasPage> {
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
            _Header(onBack: () => context.go(AppRoutes.listaCompra)),
            Expanded(
              child: Consumer<ListaCompraProvider>(
                builder: (context, provider, _) {
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
