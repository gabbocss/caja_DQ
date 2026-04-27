import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../../domain/entities/linea_buffet.dart';
import '../../domain/repositories/cocina_repository.dart';
import '../providers/cocina_provider.dart';

/// Pantalla de Cocina para visualización en tiempo real
/// 
/// Diseñada para pantallas grandes con pedidos organizados por estado
class CocinaPage extends StatelessWidget {
  const CocinaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CocinaProvider(
        repository: sl.isRegistered<CocinaRepository>() ? sl<CocinaRepository>() : null,
      ),
      child: const _CocinaPageContent(),
    );
  }
}

class _CocinaPageContent extends StatelessWidget {
  const _CocinaPageContent();

  @override
  Widget build(BuildContext context) {
    return Consumer<CocinaProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF0D0D0D),
          body: SafeArea(
            child: Column(
              children: [
                // Banner de error al cargar pedidos (ej. servidor caído)
                if (provider.error != null) _buildErrorBanner(context, provider),
                // Cuerpo: Modo Buffet = líneas agregadas; Modo Carta = tarjetas por mesa
                Expanded(
                  child: provider.modoBuffet
                      ? _buildVistaBuffet(context, provider)
                      : _buildVistaCarta(context, provider),
                ),
                // Pie: cambio Modo Buffet / Modo Carta
                _buildPieModoKds(provider),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Banner de error cuando falla la carga de pedidos (ej. servidor no disponible)
  Widget _buildErrorBanner(BuildContext context, CocinaProvider provider) {
    return Material(
      color: const Color(0xFFB71C1C),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  provider.error!,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () => provider.recargar(),
                child: const Text('Reintentar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Vista modo carta: selector de destino + grid de tarjetas por pedido/mesa
  Widget _buildVistaCarta(BuildContext context, CocinaProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context, provider),
        _DestinoSelector(provider: provider),
        Expanded(
          child: provider.pedidos.isEmpty
              ? _buildSinPedidos(provider)
              : _buildPedidosGrid(context, provider),
        ),
      ],
    );
  }

  /// Vista modo buffet: líneas de platos únicos (acumulación global)
  Widget _buildVistaBuffet(BuildContext context, CocinaProvider provider) {
    final abiertas = provider.lineasAbiertas;
    final cerradas = provider.lineasCerradas;
    if (abiertas.isEmpty && cerradas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 80,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),
            const Text(
              'Sin líneas de producción',
              style: TextStyle(color: Colors.white38, fontSize: 20),
            ),
            const SizedBox(height: 8),
            const Text(
              'Los pedidos de buffet aparecerán aquí agrupados por plato',
              style: TextStyle(color: Colors.white24, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Líneas cerradas (en preparación) primero
        ...cerradas.map((l) => _LineaBuffetCerradaCard(
              linea: l,
              provider: provider,
            )),
        // Líneas abiertas (se siguen acumulando)
        ...abiertas.map((l) => _LineaBuffetAbiertaCard(
              linea: l,
              provider: provider,
            )),
      ],
    );
  }

  /// Pie: botón para cambiar entre Modo Buffet y Modo Carta + reloj a la derecha
  Widget _buildPieModoKds(CocinaProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            'Modo:',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(width: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Modo Carta'), icon: Icon(Icons.menu_book)),
              ButtonSegment(value: true, label: Text('Modo Buffet'), icon: Icon(Icons.restaurant)),
            ],
            selected: {provider.modoBuffet},
            onSelectionChanged: (Set<bool> selected) {
              provider.setModoKds(selected.first);
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFFE94560);
                }
                return const Color(0xFF16213E);
              }),
              foregroundColor: const WidgetStatePropertyAll(Colors.white),
            ),
          ),
          const Spacer(),
          _RelojPieWidget(),
        ],
      ),
    );
  }

  /// Reloj compacto para el pie (a la derecha de Modo Buffet)
  Widget _RelojPieWidget() {
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now().millisecondsSinceEpoch),
      builder: (context, snapshot) {
        final now = DateTime.now();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE94560).withValues(alpha: 0.3)),
          ),
          child: Text(
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 22,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, CocinaProvider provider) {
    final destinoNombre = provider.destinoSeleccionado?.nombre ?? 'TODOS';
    final destinoColor = provider.destinoSeleccionado != null
        ? _parseColor(provider.destinoSeleccionado!.color)
        : const Color(0xFFE94560);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: destinoColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getIconData(provider.destinoSeleccionado?.icono ?? 'restaurant'),
              color: destinoColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                destinoNombre.toUpperCase(),
                style: TextStyle(
                  color: destinoColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              Text(
                '${provider.totalPedidos} pedido${provider.totalPedidos != 1 ? 's' : ''} activo${provider.totalPedidos != 1 ? 's' : ''}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildEstadistica(
            'Pendientes',
            provider.pedidosPendientes.length,
            const Color(0xFFFFB74D),
            Icons.schedule,
          ),
          const SizedBox(width: 20),
          _buildEstadistica(
            'Preparando',
            provider.pedidosPreparando.length,
            const Color(0xFF4FC3F7),
            Icons.local_fire_department,
          ),
          const SizedBox(width: 24),
          _RelojWidget(),
          const SizedBox(width: 16),
          IconButton(
            onPressed: provider.toggleSonido,
            icon: Icon(
              provider.sonidoActivado ? Icons.volume_up : Icons.volume_off,
              color: provider.sonidoActivado ? const Color(0xFF00D9A5) : Colors.white54,
              size: 28,
            ),
            tooltip: provider.sonidoActivado ? 'Sonido activado' : 'Activar sonido',
          ),
          IconButton(
            onPressed: provider.recargar,
            icon: const Icon(Icons.refresh, color: Colors.white54, size: 28),
            tooltip: 'Actualizar',
          ),
        ],
      ),
    );
  }

  Widget _buildEstadistica(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSinPedidos(CocinaProvider provider) {
    final destinoNombre = provider.destinoSeleccionado?.nombre ?? 'todos los destinos';
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 120,
            color: const Color(0xFF00D9A5).withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          const Text(
            '¡Todo al día!',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay pedidos pendientes en $destinoNombre',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPedidosGrid(BuildContext context, CocinaProvider provider) {
    // Ordenar: pendientes primero, luego por tiempo de espera (más antiguos primero)
    final pedidosOrdenados = [...provider.pedidos];
    pedidosOrdenados.sort((a, b) {
      if (a.estado == EstadoPedido.pendiente && b.estado != EstadoPedido.pendiente) {
        return -1;
      }
      if (a.estado != EstadoPedido.pendiente && b.estado == EstadoPedido.pendiente) {
        return 1;
      }
      return a.fechaCreacion.compareTo(b.fechaCreacion);
    });

    return GridView.builder(
      key: ValueKey('cocina_grid_${provider.versionOptimista}'),
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: pedidosOrdenados.length,
      itemBuilder: (context, index) {
        final pedido = pedidosOrdenados[index];
        return _PedidoCard(
          pedido: pedido,
          provider: provider,
        );
      },
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFFE94560);
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'local_bar':
        return Icons.local_bar;
      case 'cake':
        return Icons.cake;
      case 'local_cafe':
        return Icons.local_cafe;
      case 'local_pizza':
        return Icons.local_pizza;
      case 'icecream':
        return Icons.icecream;
      case 'print':
        return Icons.print;
      default:
        return Icons.restaurant;
    }
  }
}

/// Widget de reloj que se actualiza cada segundo
class _RelojWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, _) {
        final now = DateTime.now();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 24,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}

/// Selector de destino para filtrar pedidos
class _DestinoSelector extends StatelessWidget {
  final CocinaProvider provider;

  const _DestinoSelector({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.destinos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xFF1A1A1A),
      child: Row(
        children: [
          // Botón "Todos"
          _DestinoChip(
            label: 'TODOS',
            icon: Icons.grid_view,
            color: const Color(0xFF757575),
            isSelected: provider.destinoSeleccionado == null,
            onTap: () => provider.verTodos(),
          ),
          const SizedBox(width: 8),
          const VerticalDivider(color: Colors.white24, indent: 12, endIndent: 12),
          const SizedBox(width: 8),
          
          // Destinos dinámicos
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: provider.destinos.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final destino = provider.destinos[index];
                final color = _parseColor(destino.color);
                
                return _DestinoChip(
                  label: destino.nombre.toUpperCase(),
                  icon: _getIconData(destino.icono),
                  color: color,
                  isSelected: provider.destinoSeleccionado?.id == destino.id,
                  onTap: () => provider.seleccionarDestino(destino),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFFE94560);
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'local_bar':
        return Icons.local_bar;
      case 'cake':
        return Icons.cake;
      case 'local_cafe':
        return Icons.local_cafe;
      case 'local_pizza':
        return Icons.local_pizza;
      case 'icecream':
        return Icons.icecream;
      case 'print':
        return Icons.print;
      default:
        return Icons.restaurant;
    }
  }
}

/// Chip de destino individual
class _DestinoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _DestinoChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.3) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : Colors.white24,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? color : Colors.white54, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.white54,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de pedido individual para la cocina
class _PedidoCard extends StatelessWidget {
  final Pedido pedido;
  final CocinaProvider provider;

  const _PedidoCard({
    required this.pedido,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final esUrgente = provider.esPedidoUrgente(pedido);
    final esPendiente = pedido.estado == EstadoPedido.pendiente;
    final esPreparando = pedido.estado == EstadoPedido.preparando;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: esUrgente
              ? Colors.red
              : esPendiente
                  ? const Color(0xFFFFB74D)
                  : const Color(0xFF4FC3F7),
          width: esUrgente ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: esUrgente
                ? Colors.red.withValues(alpha: 0.3)
                : esPendiente
                    ? const Color(0xFFFFB74D).withValues(alpha: 0.2)
                    : const Color(0xFF4FC3F7).withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: esUrgente ? 2 : 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header del pedido
          _buildHeader(esUrgente, esPendiente),
          
          // Lista de items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: pedido.items.length,
              itemBuilder: (context, index) {
                final item = pedido.items[index];
                return _ItemPedidoTile(
                  item: item,
                  index: index,
                  pedidoId: pedido.id ?? 0,
                  provider: provider,
                );
              },
            ),
          ),
          
          // Botones de acción
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (esPendiente)
                  Expanded(
                    child: _ActionButton(
                      label: 'PREPARAR',
                      icon: Icons.local_fire_department,
                      color: const Color(0xFFFFB74D),
                      onPressed: () => provider.iniciarPreparacion(pedido.id ?? 0),
                    ),
                  ),
                if (esPreparando)
                  Expanded(
                    child: _ActionButton(
                      label: 'LISTO',
                      icon: Icons.check_circle,
                      color: const Color(0xFF00D9A5),
                      onPressed: () => provider.marcarListo(pedido.id ?? 0),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool esUrgente, bool esPendiente) {
    final esQR = pedido.origen == OrigenPedido.qr;
    final esWeb = pedido.origen == OrigenPedido.web;
    final esDeCliente = esQR || esWeb;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: esUrgente
            ? Colors.red.withValues(alpha: 0.2)
            : esDeCliente
                ? const Color(0xFF9C27B0).withValues(alpha: 0.2)
                : esPendiente
                    ? const Color(0xFFFFB74D).withValues(alpha: 0.15)
                    : const Color(0xFF4FC3F7).withValues(alpha: 0.15),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Etiqueta de origen (QR/WEB) si aplica
          if (esDeCliente)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: esQR 
                      ? [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)]
                      : [const Color(0xFF00BCD4), const Color(0xFF0097A7)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (esQR ? const Color(0xFF9C27B0) : const Color(0xFF00BCD4))
                        .withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    esQR ? Icons.qr_code : Icons.language,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    pedido.etiquetaOrigen,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          
          Row(
            children: [
              // Número de mesa
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'MESA ${pedido.mesaNumero}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Tiempo de espera con actualización en tiempo real
              StreamBuilder(
                stream: Stream.periodic(const Duration(seconds: 1)),
                builder: (context, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: esUrgente ? Colors.red : Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          esUrgente ? Icons.warning : Icons.schedule,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          provider.formatearTiempoEspera(pedido),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tile de item dentro de un pedido
class _ItemPedidoTile extends StatelessWidget {
  final ItemPedido item;
  final int index;
  final int pedidoId;
  final CocinaProvider provider;

  const _ItemPedidoTile({
    required this.item,
    required this.index,
    required this.pedidoId,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final estaListo = item.estadoItem == EstadoPedido.listo;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: estaListo
            ? const Color(0xFF00D9A5).withValues(alpha: 0.15)
            : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: estaListo
              ? const Color(0xFF00D9A5).withValues(alpha: 0.5)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Cantidad
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFE94560).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${item.cantidad}',
                style: const TextStyle(
                  color: Color(0xFFE94560),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Nombre del producto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nombreProducto,
                  style: TextStyle(
                    color: estaListo ? Colors.white54 : Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    decoration: estaListo ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (item.notas != null && item.notas!.isNotEmpty)
                  Text(
                    item.notas!,
                    style: const TextStyle(
                      color: Color(0xFFFFB74D),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          
          // Checkbox para marcar como listo
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                final nuevoEstado = estaListo
                    ? EstadoPedido.preparando
                    : EstadoPedido.listo;
                provider.actualizarEstadoItem(pedidoId, index, nuevoEstado);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: estaListo
                      ? const Color(0xFF00D9A5)
                      : const Color(0xFF3A3A3A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  estaListo ? Icons.check : Icons.circle_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón de acción grande
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        shadowColor: color.withValues(alpha: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de línea abierta (modo buffet): plato con cantidad total y botón Empezar
class _LineaBuffetAbiertaCard extends StatelessWidget {
  final LineaBuffetAbierta linea;
  final CocinaProvider provider;

  const _LineaBuffetAbiertaCard({
    required this.linea,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final detalleMesas = linea.contribuciones
        .map((c) => 'Mesa ${c.mesaNumero}: ${c.cantidad}')
        .join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFFFB74D), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB74D).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${linea.cantidadTotal}',
                    style: const TextStyle(
                      color: Color(0xFFFFB74D),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        linea.nombreProducto,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (detalleMesas.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            detalleMesas,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => provider.empezarLinea(linea),
                  icon: const Icon(Icons.play_arrow, size: 22),
                  label: const Text('Empezar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB74D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de línea cerrada (modo buffet): plato congelado + Hecho (Todo) / Hecho (Parcial)
class _LineaBuffetCerradaCard extends StatelessWidget {
  final LineaBuffetCerrada linea;
  final CocinaProvider provider;

  const _LineaBuffetCerradaCard({
    required this.linea,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final detalleMesas = linea.contribuciones
        .map((c) => 'Mesa ${c.mesaNumero}: ${c.cantidad}')
        .join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF4FC3F7), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4FC3F7).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${linea.cantidadTotal}',
                    style: const TextStyle(
                      color: Color(0xFF4FC3F7),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        linea.nombreProducto,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (detalleMesas.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            detalleMesas,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pedirCantidadParcial(context),
                    icon: const Icon(Icons.done_all, size: 20),
                    label: const Text('Hecho (Parcial)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4FC3F7),
                      side: const BorderSide(color: Color(0xFF4FC3F7)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => provider.hechoTodoLinea(linea.id),
                    icon: const Icon(Icons.check_circle, size: 20),
                    label: const Text('Hecho (Todo)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D9A5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _pedirCantidadParcial(BuildContext context) {
    int cantidad = linea.cantidadTotal;
    final maxCant = linea.cantidadTotal;
    showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Hecho (Parcial)', style: TextStyle(color: Colors.white)),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Cantidad terminada',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: cantidad > 1
                          ? () => setState(() => cantidad--)
                          : null,
                      icon: const Icon(Icons.remove, color: Colors.white, size: 28),
                      style: IconButton.styleFrom(
                        backgroundColor: cantidad > 1 ? const Color(0xFF0F3460) : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        '$cantidad',
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: cantidad < maxCant
                          ? () => setState(() => cantidad++)
                          : null,
                      icon: const Icon(Icons.add, color: Colors.white, size: 28),
                      style: IconButton.styleFrom(
                        backgroundColor: cantidad < maxCant ? const Color(0xFF0F3460) : null,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              provider.hechoParcialLinea(linea.id, cantidad);
              Navigator.of(ctx).pop(cantidad);
            },
            child: const Text('Imprimir'),
          ),
        ],
      ),
    );
  }
}
