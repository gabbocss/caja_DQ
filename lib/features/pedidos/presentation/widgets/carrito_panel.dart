import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../pages/pedidos_page.dart';

/// Panel lateral del carrito de compras
/// 
/// Muestra la mesa seleccionada, items agregados, consumo actual de la mesa y botón de envío
class CarritoPanel extends StatelessWidget {
  final int mesaSeleccionada;
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
  final bool enviando;
  final Set<int> productosAgotados; // IDs de productos agotados

  const CarritoPanel({
    super.key,
    required this.mesaSeleccionada,
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
    this.enviando = false,
    this.productosAgotados = const {},
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
              const Expanded(
                child: Text(
                  'MESA SELECCIONADA',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
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
          const SizedBox(height: 12),
          
          // Grid de mesas
          SizedBox(
            height: 80,
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: 10,
              itemBuilder: (context, index) {
                final numeroMesa = index + 1;
                final isSelected = mesaSeleccionada == numeroMesa;
                final tieneCuentaAbierta = mesasConCuentaAbierta.contains(numeroMesa);
                
                Color borderColor = const Color(0xFF16213E);
                Color? backgroundColor = const Color(0xFF1A1A2E);
                if (isSelected) {
                  borderColor = const Color(0xFFE94560);
                  backgroundColor = null;
                } else if (tieneCuentaAbierta) {
                  borderColor = const Color(0xFF00D9A5);
                  backgroundColor = const Color(0xFF00D9A5).withValues(alpha: 0.15);
                }
                
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (onMesaTap != null) {
                        onMesaTap!(numeroMesa);
                      } else {
                        onMesaChanged(numeroMesa);
                      }
                    },
                    onLongPress: onMostrarQrMesa != null
                        ? () => onMostrarQrMesa!(numeroMesa)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFFE94560), Color(0xFFFF6B6B)],
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

    final totalConsumo = todosLosItems.fold<double>(
      0,
      (sum, item) => sum + item.subtotal,
    );

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: const Color(0xFF00D9A5), size: 18),
              const SizedBox(width: 6),
              const Text(
                'CONSUMO ACTUAL',
                style: TextStyle(
                  color: Color(0xFF00D9A5),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 140),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: todosLosItems.length,
              itemBuilder: (context, index) {
                final item = todosLosItems[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.cantidad}×',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.nombreProducto,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '\$${item.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF00D9A5),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(color: Color(0xFF00D9A5), height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal cuenta',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              Text(
                '\$${totalConsumo.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF00D9A5),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
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
    return Container(
      padding: const EdgeInsets.all(16),
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
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  const Text(
                    'TOTAL: ',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF00D9A5),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),

          // Botón LIBERAR (solo si la mesa tiene consumo actual)
          if (consumoActual.isNotEmpty && onLiberar != null) ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: enviando ? null : onLiberar,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF9800),
                  side: const BorderSide(color: Color(0xFFFF9800), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'LIBERAR',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Botón ENVIAR
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: enviando || items.isEmpty ? null : onEnviar,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE94560),
                disabledBackgroundColor: const Color(0xFF1A1A2E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
                shadowColor: const Color(0xFFE94560).withValues(alpha: 0.5),
              ),
              child: enviando
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'ENVIAR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
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
