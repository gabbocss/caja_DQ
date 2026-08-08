import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../core/services/registro_pago_service.dart';
import '../pages/pedidos_page.dart';

/// Panel lateral del carrito de compras
/// 
/// Muestra la mesa seleccionada, items agregados, consumo actual de la mesa y botón de envío
class CarritoPanel extends StatelessWidget {
  final int mesaSeleccionada;
  /// Números de mesa configurados (Config > Mesas). Si vacío o null se usa 1..20.
  final List<int> numerosMesas;
  final List<ItemCarrito> items;
  final List<Pedido> consumoActual; // Pedidos no pagados de la mesa (cuenta abierta)
  final Set<int> mesasConCuentaAbierta; // Mesas con al menos un pedido no pagado
  final ValueChanged<int> onMesaChanged;
  /// Si se proporciona, se llama al tocar una mesa (para mostrar diálogo de apertura)
  final Future<void> Function(int mesa)? onMesaTap;
  final ValueChanged<int>? onMostrarQrMesa;
  final ValueChanged<int> onItemRemoved;
  /// Callback para cambiar el orden del plato (1º, 2º, etc.) por índice
  final void Function(int index, int orden)? onOrdenChanged;
  final VoidCallback onEnviar;
  /// Se llama al pulsar LIBERAR (solo visible si la mesa tiene consumo actual)
  final VoidCallback? onLiberar;
  /// Se llama al pulsar IMPRIMIR (ticket cuenta de la mesa)
  final VoidCallback? onImprimirCuenta;
  /// Se llama al pulsar PAGOS (modal de formas de pago)
  final VoidCallback? onPagos;
  /// Doble clic en CONSUMO ACTUAL para abrir edición de platos
  final VoidCallback? onEditarConsumo;
  final bool enviando;
  final Set<int> productosAgotados; // IDs de productos agotados
  /// Si es false, oculta el grid de mesas y muestra solo "Mesa X" (flujo móvil).
  final bool mostrarSelectorMesas;

  const CarritoPanel({
    super.key,
    required this.mesaSeleccionada,
    this.numerosMesas = const [],
    required this.items,
    this.consumoActual = const [],
    this.mesasConCuentaAbierta = const {},
    required this.onMesaChanged,
    this.onMesaTap,
    this.onMostrarQrMesa,
    required this.onItemRemoved,
    this.onOrdenChanged,
    required this.onEnviar,
    this.onLiberar,
    this.onImprimirCuenta,
    this.onPagos,
    this.onEditarConsumo,
    this.enviando = false,
    this.productosAgotados = const {},
    this.mostrarSelectorMesas = true,
  });

  double get total => items.fold(0, (sum, item) => sum + item.subtotal);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        border: const Border(
          left: BorderSide(
            color: Color(0xFF0F3460),
            width: 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(-5, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Selector de mesa
          _buildMesaSelector(),
          
          // Consumo actual de la mesa (cuenta abierta)
          if (consumoActual.isNotEmpty) _buildConsumoActual(),
          
          // Lista de items del carrito
          Expanded(
            child: items.isEmpty
                ? _buildCarritoVacio()
                : _buildListaItems(),
          ),
          
          // Resumen y botón enviar
          _buildResumen(),
        ],
      ),
    );
  }

  Widget _buildMesaSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F3460),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF1A1A2E),
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.table_restaurant,
                color: Color(0xFFE94560),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mostrarSelectorMesas
                      ? 'MESA SELECCIONADA'
                      : 'Mesa $mesaSeleccionada',
                  style: TextStyle(
                    color: mostrarSelectorMesas ? Colors.white60 : Colors.white,
                    fontSize: mostrarSelectorMesas ? 12 : 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: mostrarSelectorMesas ? 1 : 0,
                  ),
                ),
              ),
              if (onMostrarQrMesa != null)
                IconButton(
                  onPressed: () => onMostrarQrMesa!(mesaSeleccionada),
                  icon: const Icon(Icons.qr_code_2),
                  color: const Color(0xFF00D9A5),
                  tooltip: 'Ver QR para pedir desde móvil',
                ),
            ],
          ),
          if (mostrarSelectorMesas) ...[
            const SizedBox(height: 12),
            // Selector de mesas con paginación (usa mesas configuradas en Config > Mesas)
            _MesaSelectorPaginado(
              mesaSeleccionada: mesaSeleccionada,
              numerosMesas: numerosMesas,
              mesasConCuentaAbierta: mesasConCuentaAbierta,
              onMesaChanged: onMesaChanged,
              onMesaTap: onMesaTap,
              onMostrarQrMesa: onMostrarQrMesa,
            ),
          ],
        ],
      ),
    );
  }

  /// Lista de consumo actual (items de pedidos no pagados de la mesa)
  Widget _buildConsumoActual() {
    final todosLosItems = <ItemPedido>[];
    for (final pedido in consumoActual) {
      todosLosItems.addAll(pedido.items);
    }
    if (todosLosItems.isEmpty) return const SizedBox.shrink();

    // App móvil: solo el botón "CONSUMO ACTUAL" (sin totales), un toque para ver platos.
    if (!mostrarSelectorMesas) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEditarConsumo,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F3460),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00D9A5).withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Color(0xFF00D9A5), size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'CONSUMO ACTUAL',
                    style: TextStyle(
                      color: Color(0xFF00D9A5),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final subtotalCuenta = todosLosItems.fold<double>(
      0,
      (sum, item) => sum + item.subtotal,
    );
    final pendienteCuenta = consumoActual.fold<double>(0, (sum, pedido) {
      pedido.normalizarTotalPendiente();
      return sum + pedido.totalPendienteSeguro;
    });
    final pagadoCuenta = (subtotalCuenta - pendienteCuenta)
        .clamp(0, subtotalCuenta)
        .toDouble();
    final hayPagosParciales = pagadoCuenta > 0.009 && pendienteCuenta > 0.009;

    final contenido = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: const Color(0xFF00D9A5), size: 18),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'CONSUMO ACTUAL',
                  style: TextStyle(
                    color: Color(0xFF00D9A5),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (onEditarConsumo != null)
                Icon(
                  Icons.touch_app_outlined,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
            ],
          ),
          if (onEditarConsumo != null) ...[
            const SizedBox(height: 4),
            Text(
              'Doble clic para editar platos',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 10,
              ),
            ),
          ],
          const SizedBox(height: 10),
          _lineaResumenCuenta('Subtotal cuenta', subtotalCuenta, destacado: false),
          if (hayPagosParciales) ...[
            const SizedBox(height: 6),
            _ResumenPagosPorMetodo(
              key: ValueKey(
                '$mesaSeleccionada-${pagadoCuenta.toStringAsFixed(2)}-'
                '${pendienteCuenta.toStringAsFixed(2)}',
              ),
              mesaNumero: mesaSeleccionada,
              consumoActual: consumoActual,
            ),
            const SizedBox(height: 6),
            _lineaResumenCuenta(
              'Total Restante',
              pendienteCuenta,
              destacado: true,
            ),
          ] else
            _lineaResumenCuenta('Subtotal cuenta', subtotalCuenta, destacado: true),
        ],
      );

    return GestureDetector(
      onDoubleTap: onEditarConsumo,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F3460),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF00D9A5).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: contenido,
      ),
    );
  }

  Widget _lineaResumenCuenta(
    String etiqueta,
    double importe, {
    bool destacado = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          etiqueta,
          style: TextStyle(
            color: color ?? (destacado ? Colors.white60 : Colors.white54),
            fontSize: destacado ? 12 : 11,
            fontWeight: destacado ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          '\$${importe.toStringAsFixed(2)}',
          style: TextStyle(
            color: destacado ? const Color(0xFF00D9A5) : (color ?? Colors.white70),
            fontSize: destacado ? 16 : 14,
            fontWeight: destacado ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCarritoVacio() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 16),
            Text(
              'Carrito vacío',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca un producto para agregarlo',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaItems() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final estaAgotado = item.producto.id != null &&
            productosAgotados.contains(item.producto.id);
        return _CarritoItemTile(
          item: item,
          index: index,
          onRemove: () => onItemRemoved(index),
          onOrdenChanged: onOrdenChanged != null
              ? (orden) => onOrdenChanged!(index, orden)
              : null,
          estaAgotado: estaAgotado,
        );
      },
    );
  }

  Widget _buildResumen() {
    // En la app móvil (sin selector de mesas) el bloque es ~25% más bajo.
    final compacto = !mostrarSelectorMesas;
    final padding = compacto ? 12.0 : 16.0;
    final gapResumen = compacto ? 12.0 : 16.0;
    final alturaBoton = compacto ? 44.0 : 52.0;
    final fontProducto = compacto ? 11.0 : 14.0;
    final fontTotalLabel = compacto ? 11.0 : 14.0;
    final fontTotal = compacto ? 18.0 : 24.0;
    final fontBoton = compacto ? 12.0 : 16.0;
    final gapBotones = compacto ? 9.0 : 12.0;
    final paddingBoton = compacto
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 0)
        : null;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3460),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Resumen de items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${items.length} producto${items.length != 1 ? 's' : ''}',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: fontProducto,
                ),
              ),
              Row(
                children: [
                  Text(
                    'TOTAL: ',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: fontTotalLabel,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: const Color(0xFF00D9A5),
                      fontSize: fontTotal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: gapResumen),

          // Botones LIBERAR e IMPRIMIR (solo si la mesa tiene consumo actual)
          if (consumoActual.isNotEmpty && (onLiberar != null || onImprimirCuenta != null)) ...[
            SizedBox(
              height: alturaBoton,
              child: Row(
                children: [
                  if (onLiberar != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: enviando ? null : onLiberar,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF9800),
                          side: const BorderSide(color: Color(0xFFFF9800), width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: paddingBoton,
                          minimumSize: Size(0, alturaBoton),
                          tapTargetSize: compacto
                              ? MaterialTapTargetSize.shrinkWrap
                              : MaterialTapTargetSize.padded,
                        ),
                        child: Text(
                          'LIBERAR',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: fontBoton,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  if (onLiberar != null && onImprimirCuenta != null)
                    SizedBox(width: gapBotones),
                  if (onImprimirCuenta != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: enviando ? null : onImprimirCuenta,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00D9A5),
                          side: const BorderSide(color: Color(0xFF00D9A5), width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: paddingBoton,
                          minimumSize: Size(0, alturaBoton),
                          tapTargetSize: compacto
                              ? MaterialTapTargetSize.shrinkWrap
                              : MaterialTapTargetSize.padded,
                        ),
                        child: Text(
                          'IMPRIMIR',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: fontBoton,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: gapBotones),
          ],

          // Botones ENVIAR y PAGOS (misma altura que LIBERAR / IMPRIMIR)
          SizedBox(
            height: alturaBoton,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: enviando || items.isEmpty ? null : onEnviar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE94560),
                      disabledBackgroundColor: const Color(0xFF1A1A2E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: const Color(0xFFE94560).withValues(alpha: 0.5),
                      padding: paddingBoton,
                      minimumSize: Size(0, alturaBoton),
                      tapTargetSize: compacto
                          ? MaterialTapTargetSize.shrinkWrap
                          : MaterialTapTargetSize.padded,
                    ),
                    child: enviando
                        ? SizedBox(
                            width: compacto ? 18 : 22,
                            height: compacto ? 18 : 22,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            'ENVIAR',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: fontBoton,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
                if (onPagos != null) ...[
                  SizedBox(width: gapBotones),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: enviando || consumoActual.isEmpty
                          ? null
                          : onPagos,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFBB86FC),
                        side: const BorderSide(color: Color(0xFFBB86FC), width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: paddingBoton,
                        minimumSize: Size(0, alturaBoton),
                        tapTargetSize: compacto
                            ? MaterialTapTargetSize.shrinkWrap
                            : MaterialTapTargetSize.padded,
                      ),
                      child: Text(
                        'PAGOS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: fontBoton,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Selector de mesas: grid horizontal con flechas. Usa numerosMesas si no vacío; si no 1..20.
class _MesaSelectorPaginado extends StatefulWidget {
  final int mesaSeleccionada;
  final List<int> numerosMesas;
  final Set<int> mesasConCuentaAbierta;
  final ValueChanged<int> onMesaChanged;
  final Future<void> Function(int mesa)? onMesaTap;
  final ValueChanged<int>? onMostrarQrMesa;

  const _MesaSelectorPaginado({
    required this.mesaSeleccionada,
    this.numerosMesas = const [],
    required this.mesasConCuentaAbierta,
    required this.onMesaChanged,
    this.onMesaTap,
    this.onMostrarQrMesa,
  });

  @override
  State<_MesaSelectorPaginado> createState() => _MesaSelectorPaginadoState();
}

class _MesaSelectorPaginadoState extends State<_MesaSelectorPaginado> {
  final ScrollController _scrollController = ScrollController();

  List<int> get _numerosMesas {
    if (widget.numerosMesas.isNotEmpty) return widget.numerosMesas;
    return List.generate(20, (i) => i + 1);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollIzquierda() {
    const delta = 120.0;
    final offset = (_scrollController.offset - delta).clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(offset, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  void _scrollDerecha() {
    const delta = 120.0;
    final max = _scrollController.position.maxScrollExtent;
    final offset = (_scrollController.offset + delta).clamp(0.0, max);
    _scrollController.animateTo(offset, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            if (_scrollController.hasClients && _scrollController.offset > 0) {
              _scrollIzquierda();
            }
          },
          icon: const Icon(Icons.chevron_left),
          color: Colors.white70,
          style: IconButton.styleFrom(
            minimumSize: const Size(36, 36),
            padding: EdgeInsets.zero,
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 80,
            child: GridView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: _numerosMesas.length,
              itemBuilder: (context, index) {
                final numeroMesa = _numerosMesas[index];
                final isSelected = widget.mesaSeleccionada == numeroMesa;
                final tieneCuentaAbierta =
                    widget.mesasConCuentaAbierta.contains(numeroMesa);

                Color borderColor = const Color(0xFF16213E);
                Color? backgroundColor = const Color(0xFF1A1A2E);
                if (isSelected) {
                  borderColor = const Color(0xFFE94560);
                  backgroundColor = null;
                } else if (tieneCuentaAbierta) {
                  borderColor = const Color(0xFF00D9A5);
                  backgroundColor =
                      const Color(0xFF00D9A5).withValues(alpha: 0.15);
                }

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (widget.onMesaTap != null) {
                        widget.onMesaTap!(numeroMesa);
                      } else {
                        widget.onMesaChanged(numeroMesa);
                      }
                    },
                    onLongPress: widget.onMostrarQrMesa != null
                        ? () => widget.onMostrarQrMesa!(numeroMesa)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFFE94560),
                                  Color(0xFFFF6B6B),
                                ],
                              )
                            : null,
                        color: isSelected ? null : backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: borderColor,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$numeroMesa',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : tieneCuentaAbierta
                                    ? const Color(0xFF00D9A5)
                                    : Colors.white60,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            if (_scrollController.hasClients &&
                _scrollController.offset < _scrollController.position.maxScrollExtent) {
              _scrollDerecha();
            }
          },
          icon: const Icon(Icons.chevron_right),
          color: Colors.white70,
          style: IconButton.styleFrom(
            minimumSize: const Size(36, 36),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

/// Tile individual de item en el carrito
class _CarritoItemTile extends StatelessWidget {
  final ItemCarrito item;
  final int index;
  final VoidCallback onRemove;
  final ValueChanged<int>? onOrdenChanged;
  final bool estaAgotado;

  const _CarritoItemTile({
    required this.item,
    required this.index,
    required this.onRemove,
    this.onOrdenChanged,
    this.estaAgotado = false,
  });

  Future<void> _mostrarDialogoOrden(BuildContext context) async {
    if (onOrdenChanged == null) return;
    int seleccionado = item.orden;
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            '¿Orden de los platos?',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(9, (i) {
                final n = i + 1;
                final isSelected = seleccionado == n;
                return ChoiceChip(
                  label: Text('$nº'),
                  selected: isSelected,
                  onSelected: (_) => setState(() => seleccionado = n),
                  selectedColor: const Color(0xFF00D9A5),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black87 : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                );
              }),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(seleccionado),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00D9A5)),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      ),
    );
    if (result != null) onOrdenChanged!(result);
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('$index-${item.producto.id ?? item.producto.nombre}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.withValues(alpha: 0.3),
        child: const Icon(
          Icons.delete,
          color: Colors.red,
          size: 28,
        ),
      ),
      child: GestureDetector(
        onDoubleTap: onOrdenChanged != null ? () => _mostrarDialogoOrden(context) : null,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: estaAgotado
                ? const Color(0xFF2A1A1A)
                : const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: estaAgotado
                  ? const Color(0xFFE94560)
                  : item.producto.esBuffet
                      ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                      : const Color(0xFF0F3460),
              width: estaAgotado ? 2 : 1,
            ),
            boxShadow: estaAgotado
                ? [
                    BoxShadow(
                      color: const Color(0xFFE94560).withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 50,
                decoration: BoxDecoration(
                  color: estaAgotado
                      ? const Color(0xFFE94560)
                      : item.producto.destino == DestinoProducto.cocina
                          ? const Color(0xFFE94560)
                          : const Color(0xFF00D9A5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.producto.nombre,
                            style: TextStyle(
                              color: estaAgotado ? Colors.white60 : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              decoration: estaAgotado ? TextDecoration.lineThrough : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.producto.esBuffet && !estaAgotado)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.star,
                              color: Color(0xFFFFD700),
                              size: 14,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (estaAgotado)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE94560),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'AGOTADO',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      )
                    else
                      Text(
                        '\$${item.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF00D9A5),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                  ],
                ),
              ),
              if (estaAgotado)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFE94560),
                  ),
                  tooltip: 'Eliminar producto agotado',
                )
              else
                Tooltip(
                  message: 'Doble clic para cambiar orden del plato',
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F3460),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${item.orden}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cobros parciales de la mesa desglosados por método (desde registros de caja).
class _ResumenPagosPorMetodo extends StatefulWidget {
  const _ResumenPagosPorMetodo({
    super.key,
    required this.mesaNumero,
    required this.consumoActual,
  });

  final int mesaNumero;
  final List<Pedido> consumoActual;

  @override
  State<_ResumenPagosPorMetodo> createState() => _ResumenPagosPorMetodoState();
}

class _ResumenPagosPorMetodoState extends State<_ResumenPagosPorMetodo> {
  late Future<Map<String, double>> _totalesFuture;

  @override
  void initState() {
    super.initState();
    _totalesFuture = _cargarTotales();
  }

  Future<Map<String, double>> _cargarTotales() {
    return RegistroPagoService.instance.totalesPorMetodoEnMesa(
      widget.mesaNumero,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: _totalesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 18);
        }
        final totales = snapshot.data!;
        final filas = <Widget>[];

        void addSiPositivo(String etiqueta, double importe) {
          if (importe <= 0.009) return;
          if (filas.isNotEmpty) filas.add(const SizedBox(height: 4));
          filas.add(_filaPagoMetodo(etiqueta, importe));
        }

        addSiPositivo('Efectivo', totales['efectivo'] ?? 0);
        addSiPositivo('Tarjeta', totales['tarjeta'] ?? 0);
        addSiPositivo('Otros', totales['otros'] ?? 0);

        if (filas.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: filas,
        );
      },
    );
  }
}

Widget _filaPagoMetodo(String etiqueta, double importe) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        etiqueta,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
        ),
      ),
      Text(
        '\$${importe.toStringAsFixed(2)}',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}
