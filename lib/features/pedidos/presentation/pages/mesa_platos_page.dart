import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../../../../core/services/reserva_carta_cache_service.dart';
import '../providers/pedidos_mobile_provider.dart';
import '../widgets/producto_grid.dart';
import '../widgets/carrito_panel.dart';
import '../widgets/dialogo_consumo_actual_lectura.dart';
import 'pedidos_page.dart' show ItemCarrito;

/// Pantalla de platos de una categoría para una mesa.
/// Swipe derecha abre el carrito (endDrawer); gesto o botón atrás vuelve.
class MesaPlatosPage extends StatefulWidget {
  final int numeroMesa;
  /// Slug de categoría (ej. "Bebidas" o "Platos_Fuertes")
  final String categoriaSlug;

  const MesaPlatosPage({super.key, required this.numeroMesa, required this.categoriaSlug});

  String get categoriaNombre => categoriaSlug.replaceAll('_', ' ');

  @override
  State<MesaPlatosPage> createState() => _MesaPlatosPageState();
}

class _MesaPlatosPageState extends State<MesaPlatosPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Producto> _productos = [];
  bool _cargandoProductos = true;
  /// Id del plato cuyo borde se ilumina brevemente al añadirlo.
  int? _flashProductoId;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PedidosMobileProvider>().loadCuentaMesa(widget.numeroMesa);
    });
  }

  void _iluminarBordeBreve(int? productoId) {
    if (productoId == null || productoId <= 0) return;
    setState(() => _flashProductoId = productoId);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (_flashProductoId == productoId) {
        setState(() => _flashProductoId = null);
      }
    });
  }

  /// En móvil cliente usa la carta cacheada (sync de Reservas); en local, Isar.
  Future<void> _cargarProductos() async {
    try {
      final productos = sl.isRegistered<ApiClient>()
          ? await ReservaCartaCacheService.instance.cargar()
          : await DatabaseService.instance.obtenerProductos();
      if (mounted) {
        setState(() {
          _productos = productos;
          _cargandoProductos = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando productos (carta caché): $e');
      if (mounted) {
        setState(() {
          _productos = [];
          _cargandoProductos = false;
        });
      }
    }
  }

  Future<void> _openCarrito() async {
    final provider = context.read<PedidosMobileProvider>();
    await provider.loadCuentaMesa(widget.numeroMesa);
    if (!mounted) return;
    _scaffoldKey.currentState?.openEndDrawer();
  }

  /// Valida stock del carrito frente a la lista de productos (misma lógica que UI servidor).
  /// Devuelve ([ajustes], agotados). Si ambos vacíos, se puede enviar.
  ({List<Map<String, dynamic>> ajustes, Set<int> agotados}) _validarStockCarrito(
    List<ItemCarrito> items,
    List<Producto> productos,
  ) {
    final cantidadPorProducto = <int, int>{};
    for (final item in items) {
      final id = item.producto.id;
      if (id == null || id <= 0) continue;
      cantidadPorProducto[id] = (cantidadPorProducto[id] ?? 0) + item.cantidad;
    }
    final ajustes = <Map<String, dynamic>>[];
    final agotados = <int>{};
    for (final entry in cantidadPorProducto.entries) {
      final id = entry.key;
      final solicitado = entry.value;
      Producto? producto;
      for (final p in productos) {
        if (p.id == id) {
          producto = p;
          break;
        }
      }
      if (producto == null) {
        agotados.add(id);
        continue;
      }
      if (!producto.isAvailable) {
        agotados.add(id);
        continue;
      }
      if (producto.usarInventario) {
        final disponible = producto.stockDisponible;
        if (disponible < solicitado) {
          if (disponible > 0) {
            ajustes.add({
              'id': id,
              'nombre': producto.nombre,
              'solicitado': solicitado,
              'disponible': disponible,
            });
          } else {
            agotados.add(id);
          }
        }
      }
    }
    return (ajustes: ajustes, agotados: agotados);
  }

  Future<void> _mostrarDialogoValidacionStock(
    BuildContext context,
    List<Map<String, dynamic>> ajustes,
    Set<int> agotados,
    List<ItemCarrito> items,
  ) async {
    final productosAgotadosNombres = items
        .where((item) => item.producto.id != null && agotados.contains(item.producto.id))
        .map((item) => item.producto.nombre)
        .toSet()
        .toList();
    final tieneAjustes = ajustes.isNotEmpty;
    final tieneAgotados = agotados.isNotEmpty;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (tieneAjustes && !tieneAgotados)
                      ? const Color(0xFFFFA500).withValues(alpha: 0.2)
                      : const Color(0xFFE94560).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  (tieneAjustes && !tieneAgotados) ? Icons.info_outline : Icons.error_outline,
                  color: (tieneAjustes && !tieneAgotados) ? const Color(0xFFFFA500) : const Color(0xFFE94560),
                  size: 64,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                tieneAjustes && !tieneAgotados
                    ? 'STOCK INSUFICIENTE'
                    : tieneAjustes && tieneAgotados
                        ? 'STOCK INSUFICIENTE Y AGOTADOS'
                        : 'PRODUCTOS AGOTADOS',
                style: TextStyle(
                  color: (tieneAjustes && !tieneAgotados) ? const Color(0xFFFFA500) : const Color(0xFFE94560),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (tieneAjustes && !tieneAgotados)
                const Text(
                  'No hay stock suficiente. Quita o cambia los platos indicados en el carrito para poder enviar el pedido.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                )
              else if (tieneAjustes && tieneAgotados)
                const Text(
                  'Algunos productos tienen stock limitado y otros están agotados. Quita o cambia platos del carrito para poder enviar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                )
              else
                const Text(
                  'No se puede enviar el pedido. Quita los artículos agotados del carrito.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              const SizedBox(height: 16),
              if (tieneAjustes)
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F3460),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: ajustes.length,
                    itemBuilder: (context, index) {
                      final ajuste = ajustes[index];
                      final solicitado = ajuste['solicitado'] as int;
                      final disponible = ajuste['disponible'] as int;
                      final quitar = solicitado - disponible;
                      final textoQuitar = ' en stock. Quita $quitar plato${quitar == 1 ? '' : 's'} del carrito.';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.info, color: Color(0xFFFFA500), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),
                                  children: [
                                    TextSpan(text: '${ajuste['nombre']}: '),
                                    const TextSpan(text: 'solo hay ', style: TextStyle(color: Colors.white70)),
                                    TextSpan(
                                      text: '$disponible',
                                      style: const TextStyle(color: Color(0xFFFFA500), fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(text: textoQuitar, style: const TextStyle(color: Colors.white70)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              if (tieneAgotados) ...[
                if (tieneAjustes) const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F3460),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: productosAgotadosNombres.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.cancel, color: Color(0xFFE94560), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                productosAgotadosNombres[index],
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (tieneAjustes && !tieneAgotados) ? const Color(0xFFFFA500) : const Color(0xFFE94560),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    tieneAjustes && !tieneAgotados ? 'CONTINUAR CON AJUSTES' : 'ENTENDIDO',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PedidosMobileProvider>(
      builder: (context, mobileProvider, _) {
        final items = mobileProvider.carritoMesa(widget.numeroMesa);
        final cuenta = mobileProvider.cuentaMesa(widget.numeroMesa);
        final mesasCuenta = mobileProvider.mesasConCuentaAbierta;
        final cantidadesEnCarrito = <int, int>{};
        for (final item in items) {
          final id = item.producto.id;
          if (id == null || id <= 0) continue;
          cantidadesEnCarrito[id] = (cantidadesEnCarrito[id] ?? 0) + item.cantidad;
        }

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFF1A1A2E),
          appBar: AppBar(
            title: Text('Mesa ${widget.numeroMesa} - ${widget.categoriaNombre}'),
            backgroundColor: const Color(0xFF16213E),
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: _openCarrito,
                  ),
                  if (items.isNotEmpty)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE94560),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          '${items.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          body: _cargandoProductos
              ? const Center(child: CircularProgressIndicator())
              : GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
                      _openCarrito();
                    }
                  },
                  child: ProductoGrid(
                    categoriaFiltro: widget.categoriaNombre,
                    productos: _productos,
                    crossAxisCount: 2,
                    gridAltoFraccion: 0.5,
                    cantidadesEnCarrito: cantidadesEnCarrito,
                    productoIdBordeIluminado: _flashProductoId,
                    onProductoTap: (producto) {
                      if (!producto.isAvailable) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${producto.nombre} está agotado'),
                            backgroundColor: Colors.orange,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      mobileProvider.addToCart(widget.numeroMesa, producto);
                      _iluminarBordeBreve(producto.id);
                    },
                  ),
                ),
          endDrawer: Drawer(
            backgroundColor: const Color(0xFF1A1A2E),
            width: MediaQuery.of(context).size.width * 0.9,
            child: SafeArea(
              child: CarritoPanel(
                mesaSeleccionada: widget.numeroMesa,
                items: items,
                consumoActual: cuenta,
                mesasConCuentaAbierta: mesasCuenta,
                mostrarSelectorMesas: false,
                onMesaChanged: (_) {},
                onEditarConsumo: cuenta.isEmpty
                    ? null
                    : () {
                        DialogoConsumoActualLectura.mostrar(
                          context: context,
                          mesaNumero: widget.numeroMesa,
                          pedidos: cuenta,
                        );
                      },
                onItemRemoved: (index) => mobileProvider.removeFromCart(widget.numeroMesa, index),
                onOrdenChanged: (index, orden) => mobileProvider.changeOrder(widget.numeroMesa, index, orden),
                onEnviar: () async {
                  final itemsCarrito = mobileProvider.carritoMesa(widget.numeroMesa);
                  final result = _validarStockCarrito(itemsCarrito, _productos);
                  if (result.ajustes.isNotEmpty || result.agotados.isNotEmpty) {
                    await _mostrarDialogoValidacionStock(
                      context,
                      result.ajustes,
                      result.agotados,
                      itemsCarrito,
                    );
                    return;
                  }
                  final ok = await mobileProvider.sendOrder(widget.numeroMesa);
                  if (!context.mounted) return;
                  if (ok) {
                    Navigator.of(context).pop();
                    context.go(AppRoutes.mesas);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pedido enviado'),
                        backgroundColor: Color(0xFF00D9A5),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(mobileProvider.error ?? 'Error al enviar'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                enviando: mobileProvider.enviando,
                productosAgotados: const {},
              ),
            ),
          ),
        );
      },
    );
  }
}
