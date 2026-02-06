import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../providers/pedidos_provider.dart';
import '../widgets/categoria_selector.dart';
import '../widgets/producto_grid.dart';
import '../widgets/carrito_panel.dart';

/// Página principal de toma de pedidos para camareros
/// 
/// Diseñada para uso táctil con botones grandes y alto contraste
class PedidosPage extends StatefulWidget {
  const PedidosPage({super.key});

  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> {
  String? _categoriaSeleccionada;
  int _mesaSeleccionada = 1;
  final List<ItemCarrito> _carrito = [];
  bool _enviando = false;
  List<DestinoImpresion> _destinos = [];
  Set<int> _productosAgotados = {}; // IDs de productos marcados como agotados

  @override
  void initState() {
    super.initState();
    _cargarDestinos();
  }

  Future<void> _cargarDestinos() async {
    try {
      _destinos = await DatabaseService.instance.obtenerDestinosActivos();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error al cargar destinos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PedidosProvider(),
      child: Consumer<PedidosProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            backgroundColor: const Color(0xFF1A1A2E),
            body: SafeArea(
              child: Row(
                children: [
                  // Panel principal - Productos
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        // Header con selector de mesa
                        _buildHeader(context),
                        
                        // Selector de categorías
                        CategoriaSelector(
                          categoriaSeleccionada: _categoriaSeleccionada,
                          onCategoriaChanged: (categoria) {
                            setState(() => _categoriaSeleccionada = categoria);
                          },
                        ),
                        
                        // Grid de productos
                        Expanded(
                          child: ProductoGrid(
                            categoriaFiltro: _categoriaSeleccionada,
                            productos: provider.productos,
                            onProductoTap: _agregarAlCarrito,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Panel lateral - Carrito
                  CarritoPanel(
                    mesaSeleccionada: _mesaSeleccionada,
                    items: _carrito,
                    onMesaChanged: (mesa) {
                      setState(() => _mesaSeleccionada = mesa);
                    },
                    onItemRemoved: _removerDelCarrito,
                    onItemQuantityChanged: _cambiarCantidad,
                    onEnviar: _enviarPedido,
                    enviando: _enviando,
                    productosAgotados: _productosAgotados,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final esSabado = DateTime.now().weekday == DateTime.saturday;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo/Título
          const Icon(
            Icons.restaurant_menu,
            color: Color(0xFFE94560),
            size: 32,
          ),
          const SizedBox(width: 12),
          Text(
            'TOMAR PEDIDO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              shadows: [
                Shadow(
                  color: const Color(0xFFE94560).withValues(alpha: 0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Indicador de día de buffet
          if (esSabado)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.black87, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '¡HOY ES BUFFET!',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(width: 16),
          
          // Hora actual
          StreamBuilder(
            stream: Stream.periodic(const Duration(seconds: 1)),
            builder: (context, _) {
              final now = DateTime.now();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F3460),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontFamily: 'monospace',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _agregarAlCarrito(Producto producto) {
    setState(() {
      // Buscar si ya existe en el carrito
      final existente = _carrito.indexWhere((item) => 
        item.producto.id != null && producto.id != null 
          ? item.producto.id == producto.id 
          : item.producto.nombre == producto.nombre);
      
      if (existente >= 0) {
        _carrito[existente].cantidad++;
      } else {
        _carrito.add(ItemCarrito(producto: producto));
      }
    });
    
    // Feedback táctil
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${producto.nombre} agregado',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF00D9A5),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
      ),
    );
  }

  void _removerDelCarrito(int index) {
    setState(() {
      _carrito.removeAt(index);
    });
  }

  void _cambiarCantidad(int index, int nuevaCantidad) {
    setState(() {
      if (nuevaCantidad <= 0) {
        _carrito.removeAt(index);
      } else {
        _carrito[index].cantidad = nuevaCantidad;
      }
    });
  }

  Future<void> _enviarPedido() async {
    if (_carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El carrito está vacío'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      // =====================================================
      // VALIDACIÓN PRE-VUELO - Verificar disponibilidad con cantidades
      // =====================================================
      final itemsParaValidar = _carrito
          .where((item) => item.producto.id != null)
          .map((item) => {
                'id': item.producto.id!,
                'cantidad': item.cantidad,
              })
          .toList();
      
      // Llamar al endpoint de validación
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/productos/validar-stock'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'items': itemsParaValidar}),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Error al validar stock: ${response.statusCode}');
      }
      
      final validacionJson = jsonDecode(response.body) as Map<String, dynamic>;
      final errores = (validacionJson['errores'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      
      if (errores.isNotEmpty) {
        // Hay errores: ajustar cantidades o marcar como agotados
        final ajustes = <Map<String, dynamic>>[];
        final agotados = <int>{};
        
        for (final error in errores) {
          final id = error['id'] as int;
          final tipoError = error['error'] as String;
          final solicitado = error['solicitado'] as int;
          final disponible = error['disponible'] as int;
          
          if (tipoError == 'parcial' && disponible > 0) {
            // Stock parcial: ajustar cantidad
            ajustes.add({
              'id': id,
              'nombre': error['nombre'] as String,
              'solicitado': solicitado,
              'disponible': disponible,
            });
            
            // Actualizar cantidad en el carrito
            final itemIndex = _carrito.indexWhere(
              (item) => item.producto.id == id,
            );
            if (itemIndex >= 0) {
              _carrito[itemIndex].cantidad = disponible;
            }
          } else {
            // Producto completamente agotado o no existe
            agotados.add(id);
          }
        }
        
        setState(() {
          _productosAgotados = agotados;
        });
        
        // Mostrar diálogo con información detallada
        if (mounted) {
          await _mostrarDialogoValidacionStock(ajustes, agotados);
        }
        
        // Si hay productos completamente agotados, no continuar
        if (agotados.isNotEmpty) {
          setState(() => _enviando = false);
          return;
        }
        
        // Si solo hubo ajustes, continuar con el pedido ajustado (no retornar)
      }
      
      // Limpiar marcas de agotados si todo está bien
      setState(() {
        _productosAgotados.clear();
      });
      
      // =====================================================
      // PROCESAR PEDIDO
      // =====================================================
      
      final db = DatabaseService.instance;
      
      // Agrupar productos por destino dinámico
      final itemsPorDestino = <int?, List<ItemPedido>>{};
      
      for (final item in _carrito) {
        // Obtener info del destino del producto
        final destinoId = item.producto.destinoId;
        String? nombreDestino;
        
        if (destinoId != null) {
          final destino = _destinos.where((d) => d.id == destinoId).firstOrNull;
          nombreDestino = destino?.nombre;
        }
        
        final itemPedido = ItemPedido.crear(
          productoId: item.producto.id ?? 0,
          nombreProducto: item.producto.nombre,
          precioUnitario: item.producto.precio,
          cantidad: item.cantidad,
          destinoId: destinoId,
          nombreDestino: nombreDestino,
        );
        
        itemsPorDestino.putIfAbsent(destinoId, () => []).add(itemPedido);
      }

      // Crear lista plana de todos los items
      final todosItems = itemsPorDestino.values.expand((items) => items).toList();
      
      // Crear el pedido
      final pedido = Pedido.crear(
        mesaNumero: _mesaSeleccionada,
        usuarioCamarero: 'Mesero', // TODO: Obtener del usuario logueado
        items: todosItems,
      );
      pedido.calcularTotal();

      // Guardar en la base de datos
      final pedidoId = await db.guardarPedido(pedido);
      
      // Actualizar estado de la mesa
      await db.actualizarEstadoMesa(_mesaSeleccionada, EstadoMesa.ocupada);

      debugPrint('✅ Pedido #$pedidoId creado para mesa $_mesaSeleccionada');

      // Mostrar resumen del envío con destinos dinámicos
      if (mounted) {
        _mostrarResumenEnvio(itemsPorDestino);
      }
      
      // Limpiar carrito
      setState(() {
        _carrito.clear();
      });

      // Recargar productos para reflejar stock actualizado (sobre todo en Web)
      if (mounted) {
        context.read<PedidosProvider>().recargar();
      }
      
    } catch (e) {
      debugPrint('❌ Error al enviar pedido: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar pedido: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _enviando = false);
    }
  }

  Future<void> _mostrarDialogoValidacionStock(
    List<Map<String, dynamic>> ajustes,
    Set<int> productosAgotados,
  ) async {
    final productosAgotadosNombres = _carrito
        .where((item) => item.producto.id != null && productosAgotados.contains(item.producto.id))
        .map((item) => item.producto.nombre)
        .toList();
    
    final tieneAjustes = ajustes.isNotEmpty;
    final tieneAgotados = productosAgotados.isNotEmpty;
    
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
              // Icono según el tipo de error
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (tieneAjustes && !tieneAgotados)
                      ? const Color(0xFFFFA500).withValues(alpha: 0.2)
                      : const Color(0xFFE94560).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  (tieneAjustes && !tieneAgotados)
                      ? Icons.info_outline
                      : Icons.error_outline,
                  color: (tieneAjustes && !tieneAgotados)
                      ? const Color(0xFFFFA500)
                      : const Color(0xFFE94560),
                  size: 64,
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                tieneAjustes && !tieneAgotados
                    ? 'AJUSTE DE CANTIDADES'
                    : tieneAjustes && tieneAgotados
                        ? 'PROBLEMAS CON EL PEDIDO'
                        : 'PRODUCTOS AGOTADOS',
                style: TextStyle(
                  color: (tieneAjustes && !tieneAgotados)
                      ? const Color(0xFFFFA500)
                      : const Color(0xFFE94560),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Mensaje principal
              if (tieneAjustes && !tieneAgotados)
                const Text(
                  'Hemos ajustado automáticamente las cantidades de algunos productos:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                )
              else if (tieneAjustes && tieneAgotados)
                const Text(
                  'Algunos productos tienen stock limitado y otros están agotados:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                )
              else
                const Text(
                  'No se puede enviar el pedido.\nPor favor, revisa los artículos agotados:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              const SizedBox(height: 16),
              
              // Lista de ajustes (stock parcial)
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
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info,
                              color: Color(0xFFFFA500),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                  children: [
                                    TextSpan(text: '${ajuste['nombre']}: '),
                                    TextSpan(
                                      text: 'Pediste ${ajuste['solicitado']}, ',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                    const TextSpan(
                                      text: 'pero solo quedan ',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    TextSpan(
                                      text: '${ajuste['disponible']}',
                                      style: const TextStyle(
                                        color: Color(0xFFFFA500),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
              
              // Lista de productos agotados
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
                            const Icon(
                              Icons.cancel,
                              color: Color(0xFFE94560),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                productosAgotadosNombres[index],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
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
              
              // Botón cerrar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (tieneAjustes && !tieneAgotados)
                        ? const Color(0xFFFFA500)
                        : const Color(0xFFE94560),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    tieneAjustes && !tieneAgotados
                        ? 'CONTINUAR CON AJUSTES'
                        : 'ENTENDIDO',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  void _mostrarDialogoProductosAgotados(List<int> productosAgotadosIds) {
    _mostrarDialogoValidacionStock([], productosAgotadosIds.toSet());
  }

  void _mostrarResumenEnvio(Map<int?, List<ItemPedido>> itemsPorDestino) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono de éxito
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D9A5).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF00D9A5),
                  size: 64,
                ),
              ),
              const SizedBox(height: 20),
              
              const Text(
                '¡PEDIDO ENVIADO!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Resumen por destino dinámico
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: itemsPorDestino.entries.map((entry) {
                  final destinoId = entry.key;
                  final items = entry.value;
                  final cantidad = items.fold(0, (sum, item) => sum + item.cantidad);
                  
                  // Buscar info del destino
                  DestinoImpresion? destino;
                  if (destinoId != null) {
                    destino = _destinos.where((d) => d.id == destinoId).firstOrNull;
                  }
                  
                  final nombre = destino?.nombre ?? items.first.nombreDestino ?? 'Sin destino';
                  final color = destino != null 
                      ? _parseColor(destino.color) 
                      : const Color(0xFF757575);
                  final icono = destino != null 
                      ? _getIconData(destino.icono) 
                      : Icons.help_outline;
                  
                  return _buildDestinoResumen(nombre, cantidad, icono, color);
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'Mesa $_mesaSeleccionada',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Botón cerrar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F3460),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'CONTINUAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  Widget _buildDestinoResumen(String titulo, int cantidad, IconData icono, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icono, color: color, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          titulo.toUpperCase(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Text(
          '$cantidad item${cantidad > 1 ? 's' : ''}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
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

/// Modelo para items en el carrito local
class ItemCarrito {
  final Producto producto;
  int cantidad;
  String? notas;

  ItemCarrito({
    required this.producto,
    this.cantidad = 1,
    this.notas,
  });

  double get subtotal => producto.precio * cantidad;
}
