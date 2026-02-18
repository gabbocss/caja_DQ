import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../providers/pedidos_mobile_provider.dart';
import 'pedidos_page.dart' show ItemCarrito;

/// Pantalla principal del flujo móvil: grid de mesas.
/// Al tocar una mesa: si tiene cuenta abierta va a categorías; si no, pregunta cubiertos o adultos/niños (buffet).
class MesasPage extends StatefulWidget {
  const MesasPage({super.key});

  @override
  State<MesasPage> createState() => _MesasPageState();
}

class _MesasPageState extends State<MesasPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PedidosMobileProvider>().loadMesas();
      context.read<PedidosMobileProvider>().loadDestinos();
    });
  }

  Future<void> _onMesaTap(int numeroMesa) async {
    final provider = context.read<PedidosMobileProvider>();
    if (provider.mesasConCuentaAbierta.contains(numeroMesa)) {
      await provider.loadCuentaMesa(numeroMesa);
      if (mounted) context.push('/mesas/categorias/$numeroMesa');
      return;
    }

    ConfiguracionBuffet? config;
    try {
      if (sl.isRegistered<ApiClient>()) {
        config = await sl<ApiClient>().obtenerConfiguracionBuffetActiva();
      } else {
        config = await DatabaseService.instance.obtenerConfiguracionBuffetActiva();
      }
    } catch (_) {}
    final esHorarioBuffet = config?.esHorarioBuffet() ?? false;

    if (!mounted) return;
    if (esHorarioBuffet && config != null) {
      await _mostrarDialogoBuffet(context, numeroMesa, config, provider);
    } else {
      await _mostrarDialogoCubiertos(context, numeroMesa, config, provider);
    }
  }

  Future<void> _mostrarDialogoBuffet(
    BuildContext context,
    int mesa,
    ConfiguracionBuffet config,
    PedidosMobileProvider provider,
  ) async {
    int adultos = 1;
    int ninos = 0;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFFFD700)),
              const SizedBox(width: 8),
              Text('Abrir mesa $mesa - Buffet', style: const TextStyle(color: Colors.white)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Indique comensales:',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Adultos:', style: TextStyle(color: Colors.white70)),
                    const SizedBox(width: 16),
                    IconButton.filled(
                      onPressed: () => setDialogState(() => adultos = (adultos - 1).clamp(0, 99)),
                      icon: const Icon(Icons.remove),
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFFE94560)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('$adultos', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    IconButton.filled(
                      onPressed: () => setDialogState(() => adultos++),
                      icon: const Icon(Icons.add),
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFF00D9A5)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Niños:', style: TextStyle(color: Colors.white70)),
                    const SizedBox(width: 24),
                    IconButton.filled(
                      onPressed: () => setDialogState(() => ninos = (ninos - 1).clamp(0, 99)),
                      icon: const Icon(Icons.remove),
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFFE94560)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('$ninos', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    IconButton.filled(
                      onPressed: () => setDialogState(() => ninos++),
                      icon: const Icon(Icons.add),
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFF00D9A5)),
                    ),
                  ],
                ),
                if (adultos + ninos == 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Debe haber al menos 1 comensal',
                      style: TextStyle(color: Colors.orange.shade300, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
            FilledButton(
              onPressed: (adultos + ninos) < 1
                  ? null
                  : () {
                      final precioA = (config.precioAdulto.isNaN || config.precioAdulto < 0) ? 18.0 : config.precioAdulto;
                      final precioN = (config.precioNino.isNaN || config.precioNino < 0) ? 9.0 : config.precioNino;
                      final items = <ItemCarrito>[];
                      if (adultos > 0) {
                        items.add(ItemCarrito(
                          producto: Producto.crear(nombre: 'Buffet - Adulto', precio: precioA, esBuffet: true),
                          cantidad: adultos,
                          orden: 1,
                        ));
                      }
                      if (ninos > 0) {
                        items.add(ItemCarrito(
                          producto: Producto.crear(nombre: 'Buffet - Niño', precio: precioN, esBuffet: true),
                          cantidad: ninos,
                          orden: 1,
                        ));
                      }
                      provider.setAperturaMesa(
                        mesa,
                        AperturaMesa(adultosBuffet: adultos, ninosBuffet: ninos),
                        itemsIniciales: items,
                      );
                      provider.loadCuentaMesa(mesa);
                      Navigator.of(ctx).pop();
                      if (context.mounted) context.push('/mesas/categorias/$mesa');
                    },
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFD700)),
              child: const Text('Abrir mesa', style: TextStyle(color: Colors.black87)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoCubiertos(
    BuildContext context,
    int mesa,
    ConfiguracionBuffet? config,
    PedidosMobileProvider provider,
  ) async {
    int cubiertos = 1;
    final precioCubierto = config?.precioCubierto ?? 2.0;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.restaurant, color: Color(0xFF00D9A5)),
              const SizedBox(width: 8),
              Text('Abrir mesa $mesa - Cubiertos', style: const TextStyle(color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Número de cubiertos:', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filled(
                    onPressed: () => setDialogState(() => cubiertos = (cubiertos - 1).clamp(1, 99)),
                    icon: const Icon(Icons.remove),
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFFE94560)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('$cubiertos', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  ),
                  IconButton.filled(
                    onPressed: () => setDialogState(() => cubiertos++),
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFF00D9A5)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F3460),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Precio por cubierto:', style: TextStyle(color: Colors.white70)),
                    Text('\$${precioCubierto.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF00D9A5), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                final precio = (precioCubierto.isNaN || precioCubierto < 0) ? 2.0 : precioCubierto;
                final items = [
                  ItemCarrito(
                    producto: Producto.crear(nombre: 'Cubiertos', precio: precio),
                    cantidad: cubiertos,
                    orden: 1,
                  ),
                ];
                provider.setAperturaMesa(mesa, AperturaMesa(cubiertos: cubiertos), itemsIniciales: items);
                provider.loadCuentaMesa(mesa);
                Navigator.of(ctx).pop();
                if (context.mounted) context.push('/mesas/categorias/$mesa');
              },
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00D9A5)),
              child: const Text('Abrir mesa'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Mesas'),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
      ),
      body: Consumer<PedidosMobileProvider>(
        builder: (context, provider, _) {
          final listaMesas = provider.mesas.isNotEmpty
              ? provider.mesas.where((m) => m.activa).toList()
              : List.generate(10, (i) => Mesa.crear(numero: i + 1));

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadMesas();
              await provider.loadDestinos();
            },
            color: const Color(0xFFE94560),
            backgroundColor: const Color(0xFF16213E),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: listaMesas.length,
              itemBuilder: (context, index) {
              final mesa = listaMesas[index];
              final numero = mesa.numero;
              final tieneCuenta = provider.mesasConCuentaAbierta.contains(numero);

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onMesaTap(numero),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: tieneCuenta
                          ? const Color(0xFF00D9A5).withValues(alpha: 0.25)
                          : const Color(0xFF16213E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: tieneCuenta ? const Color(0xFF00D9A5) : const Color(0xFF0F3460),
                        width: tieneCuenta ? 2.5 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.table_restaurant,
                          size: 48,
                          color: tieneCuenta ? const Color(0xFF00D9A5) : Colors.white70,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mesa $numero',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (tieneCuenta)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Con cuenta',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
        },
      ),
    );
  }
}
