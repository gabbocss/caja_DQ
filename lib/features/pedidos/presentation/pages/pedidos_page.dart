import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/core.dart';
import '../../../../core/services/registro_pago_service.dart';
import '../../../estadisticas/data/estadisticas_service.dart';
import '../providers/pedidos_provider.dart';
import '../widgets/categoria_selector.dart';
import '../widgets/producto_grid.dart';
import '../widgets/carrito_panel.dart';
import '../widgets/dialogo_edicion_consumo.dart';
import '../models/linea_consumo_editable.dart';
import '../models/modificacion_consumo_rechazada.dart';

/// Forma de pago elegida en el modal de cobro.
enum MetodoPagoCuenta {
  efectivo,
  tarjeta,
  otros,
}

extension MetodoPagoCuentaExt on MetodoPagoCuenta {
  String get etiquetaImpresion {
    switch (this) {
      case MetodoPagoCuenta.efectivo:
        return 'efectivo';
      case MetodoPagoCuenta.tarjeta:
        return 'tarjeta';
      case MetodoPagoCuenta.otros:
        return 'otros';
    }
  }

  String get nombreUI {
    switch (this) {
      case MetodoPagoCuenta.efectivo:
        return 'Efectivo';
      case MetodoPagoCuenta.tarjeta:
        return 'Tarjeta';
      case MetodoPagoCuenta.otros:
        return 'Otros';
    }
  }
}

enum _PasoDialogoPagos { menu, importe }

/// Página principal de toma de pedidos (UI servidor / escritorio).
/// En móvil el flujo usa [MesaPlatosPage], que mantiene el grid sin popularidad ni iconos compactos.
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
  List<String> _categorias = [];
  Set<int> _productosAgotados = {}; // IDs de productos marcados como agotados
  List<Pedido> _cuentaActual = []; // Pedidos no pagados de la mesa seleccionada
  Set<int> _mesasConCuentaAbierta = {}; // Mesas con al menos un pedido no pagado
  /// Histórico de unidades pedidas por producto (último año) para ordenar el grid en servidor.
  Map<int, int> _popularidadPorProductoId = {};
  /// Números de mesa configurados (Config > Mesas). Vacío hasta cargar; si vacío el panel usa 1..20.
  List<int> _numerosMesas = [];
  // Apertura de mesa: buffet (sábado horario) o cubiertos
  int _adultosBuffet = 0;
  int _ninosBuffet = 0;
  int _cubiertos = 0;

  @override
  void initState() {
    super.initState();
    _cargarDestinos();
    _cargarCategorias();
    _cargarMesas();
    _cargarMesasConCuentaAbierta();
    _cargarCuentaMesa(_mesaSeleccionada);
    _cargarPopularidadProductos();
  }

  /// Orden del grid por popularidad (solo con BD local; requiere histórico de pedidos).
  Future<void> _cargarPopularidadProductos() async {
    if (sl.isRegistered<ApiClient>()) return;
    try {
      final map = await EstadisticasService.obtenerMapaCantidadPedidaPorProducto();
      if (mounted) setState(() => _popularidadPorProductoId = map);
    } catch (e) {
      debugPrint('Error al cargar popularidad de productos: $e');
    }
  }

  /// Carga la lista de mesas configuradas (Config > Mesas) para el selector del panel.
  Future<void> _cargarMesas() async {
    try {
      List<Mesa> list;
      if (sl.isRegistered<ApiClient>()) {
        list = await sl<ApiClient>().obtenerMesas();
      } else {
        list = await DatabaseService.instance.obtenerMesas();
      }
      final numeros = list.where((m) => m.activa).map((m) => m.numero).toList()..sort();
      if (mounted) {
        setState(() {
          _numerosMesas = numeros.isNotEmpty ? numeros : List.generate(20, (i) => i + 1);
          if (!_numerosMesas.contains(_mesaSeleccionada)) {
            _mesaSeleccionada = _numerosMesas.first;
          }
        });
        _cargarCuentaMesa(_mesaSeleccionada);
      }
    } catch (e) {
      debugPrint('Error al cargar mesas: $e');
      if (mounted) setState(() => _numerosMesas = List.generate(20, (i) => i + 1));
    }
  }

  Future<void> _cargarCategorias() async {
    try {
      List<String> cats;
      if (sl.isRegistered<ApiClient>()) {
        final list = await sl<ApiClient>().obtenerCategorias();
        cats = list.map((c) => c.nombre).toList();
      } else {
        final list = await DatabaseService.instance.obtenerCategorias();
        cats = list.map((c) => c.nombre).toList();
      }
      if (mounted) setState(() => _categorias = cats);
    } catch (e) {
      debugPrint('Error al cargar categorías: $e');
      if (mounted) setState(() => _categorias = []);
    }
  }

  /// Obtiene cuenta (pedidos no pagados) desde servidor o DB local
  Future<void> _cargarCuentaMesa(int numeroMesa) async {
    try {
      List<Pedido> pedidos;
      if (sl.isRegistered<ApiClient>()) {
        pedidos = await sl<ApiClient>().obtenerCuentaMesa(numeroMesa);
      } else {
        pedidos = await DatabaseService.instance.obtenerCuentaMesa(numeroMesa);
      }
      for (final p in pedidos) {
        p.normalizarTotalPendiente();
      }
      if (mounted) setState(() => _cuentaActual = pedidos);
    } catch (e) {
      debugPrint('Error al cargar cuenta mesa $numeroMesa: $e');
      if (mounted) setState(() => _cuentaActual = []);
    }
  }

  /// Carga qué mesas tienen cuenta abierta (para pintar icono verde)
  Future<void> _cargarMesasConCuentaAbierta() async {
    try {
      List<int> mesas;
      if (sl.isRegistered<ApiClient>()) {
        mesas = await sl<ApiClient>().obtenerMesasConCuentaAbierta();
      } else {
        mesas = await DatabaseService.instance.obtenerMesasConCuentaAbierta();
      }
      if (mounted) setState(() => _mesasConCuentaAbierta = mesas.toSet());
    } catch (e) {
      debugPrint('Error al cargar mesas con cuenta abierta: $e');
      if (mounted) setState(() => _mesasConCuentaAbierta = {});
    }
  }

  Future<void> _cargarDestinos() async {
    try {
      _destinos = await DatabaseService.instance.obtenerDestinosActivos();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error al cargar destinos: $e');
    }
  }

  /// Al tocar una mesa: si ya está en uso solo cambia; si no, pregunta adultos/niños o cubiertos
  Future<void> _alSeleccionarMesa(int mesa) async {
    // Si la mesa ya tiene cuenta abierta, solo seleccionarla sin preguntar
    if (_mesasConCuentaAbierta.contains(mesa)) {
      setState(() => _mesaSeleccionada = mesa);
      _cargarCuentaMesa(mesa);
      return;
    }

    ConfiguracionBuffet? config;
    try {
      config = await DatabaseService.instance.obtenerConfiguracionBuffetActiva();
    } catch (e) {
      debugPrint('Error al cargar config buffet: $e');
    }
    final esHorarioBuffet = config?.esHorarioBuffet() ?? false;

    if (!mounted) return;
    if (esHorarioBuffet) {
      await _mostrarDialogoAperturaBuffet(context, mesa, config!);
    } else {
      await _mostrarDialogoAperturaCubiertos(context, mesa, config);
    }
  }

  /// Diálogo: apertura de mesa en horario buffet (adultos y niños)
  Future<void> _mostrarDialogoAperturaBuffet(
    BuildContext context,
    int mesa,
    ConfiguracionBuffet config,
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
              Expanded(
                child: Text(
                  'Abrir mesa $mesa - Buffet',
                  style: const TextStyle(color: Colors.white),
                  softWrap: true,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Horario buffet activo. Indique comensales:',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                ),
                const SizedBox(height: 20),
                Row(
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
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: (adultos + ninos) < 1
                  ? null
                  : () {
                      final precioA = (config.precioAdulto.isNaN || config.precioAdulto < 0) ? 18.0 : config.precioAdulto;
                      final precioN = (config.precioNino.isNaN || config.precioNino < 0) ? 9.0 : config.precioNino;
                      setState(() {
                        _mesaSeleccionada = mesa;
                        _adultosBuffet = adultos;
                        _ninosBuffet = ninos;
                        _cubiertos = 0;
                        // Añadir adultos y niños como ítems en el carrito de la mesa
                        if (adultos > 0) {
                          _carrito.add(ItemCarrito(
                            producto: Producto.crear(nombre: 'Buffet - Adulto', precio: precioA, esBuffet: true),
                            cantidad: adultos,
                            orden: 1,
                          ));
                        }
                        if (ninos > 0) {
                          _carrito.add(ItemCarrito(
                            producto: Producto.crear(nombre: 'Buffet - Niño', precio: precioN, esBuffet: true),
                            cantidad: ninos,
                            orden: 1,
                          ));
                        }
                      });
                      _cargarCuentaMesa(mesa);
                      Navigator.of(ctx).pop();
                    },
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFD700)),
              child: const Text('Abrir mesa', style: TextStyle(color: Colors.black87)),
            ),
          ],
        ),
      ),
    );
  }

  /// Diálogo: apertura de mesa con cubiertos (fuera de horario buffet)
  Future<void> _mostrarDialogoAperturaCubiertos(
    BuildContext context,
    int mesa,
    ConfiguracionBuffet? config,
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
              Expanded(
                child: Text(
                  'Abrir mesa $mesa - Cubiertos',
                  style: const TextStyle(color: Colors.white),
                  softWrap: true,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Número de cubiertos:',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                ),
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final precio = (precioCubierto.isNaN || precioCubierto < 0) ? 2.0 : precioCubierto;
                setState(() {
                  _mesaSeleccionada = mesa;
                  _cubiertos = cubiertos;
                  _adultosBuffet = 0;
                  _ninosBuffet = 0;
                  // Añadir cubiertos como ítem en el carrito de la mesa
                  _carrito.add(ItemCarrito(
                    producto: Producto.crear(nombre: 'Cubiertos', precio: precio),
                    cantidad: cubiertos,
                    orden: 1,
                  ));
                });
                _cargarCuentaMesa(mesa);
                Navigator.of(ctx).pop();
              },
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00D9A5)),
              child: const Text('Abrir mesa'),
            ),
          ],
        ),
      ),
    );
  }

  /// Muestra diálogo de confirmación y libera la mesa seleccionada
  Future<void> _mostrarDialogoLiberarMesa() async {
    final numero = _mesaSeleccionada;
    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.meeting_room, color: Colors.orange.shade300),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '¿Liberar Mesa $numero?',
                style: const TextStyle(color: Colors.white),
                softWrap: true,
              ),
            ),
          ],
        ),
        content: const Text(
          'Se cerrará la cuenta actual y la mesa quedará disponible para nuevos comensales. Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade700),
            child: const Text('CONFIRMAR LIBERACIÓN'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    // Detectar si hay ítems de buffet en la cuenta (para no devolver stock en servidor)
    final isBuffetClose = _cuentaActual.any((p) {
      if (p.esBuffet) return true;
      return p.items.any((item) =>
          item.nombreProducto == 'Buffet - Adulto' || item.nombreProducto == 'Buffet - Niño');
    });

    try {
      if (sl.isRegistered<ApiClient>()) {
        await sl<ApiClient>().liberarMesa(numero, isBuffetClose: isBuffetClose);
      } else {
        await DatabaseService.instance.liberarMesa(numero, isBuffetClose: isBuffetClose);
      }
      if (!mounted) return;
      setState(() => _cuentaActual = []);
      await _cargarMesasConCuentaAbierta();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mesa $numero liberada correctamente'),
          backgroundColor: const Color(0xFF00D9A5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al liberar mesa: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Importe válido para cobros/UI (rechaza NaN e Infinity).
  double _importeCobroSeguro(double valor, double fallback) {
    if (valor.isNaN || valor.isInfinite || valor < 0) return fallback;
    return valor;
  }

  /// Total pendiente de la mesa (suma de totalPendiente de pedidos abiertos).
  double get _totalPendienteMesa {
    final fallback = _totalCuentaBrutaMesa();
    final suma = _cuentaActual.fold<double>(0, (sum, p) {
      p.normalizarTotalPendiente();
      return sum + p.totalPendienteSeguro;
    });
    return _importeCobroSeguro(suma, fallback);
  }

  /// Corrige pendientes en memoria y los persiste antes de cobrar.
  Future<void> _sincronizarPendientesCuentaMesa() async {
    var huboCambios = false;
    for (final p in _cuentaActual) {
      final antes = p.totalPendiente;
      p.normalizarTotalPendiente();
      if ((antes - p.totalPendiente).abs() > 0.001 ||
          antes.isNaN ||
          antes.isInfinite) {
        huboCambios = true;
      }
    }
    if (huboCambios && !sl.isRegistered<ApiClient>()) {
      final db = DatabaseService.instance;
      for (final p in _cuentaActual) {
        if (p.id != null) {
          await db.guardarPedido(p);
        }
      }
    }
    if (mounted) setState(() {});
  }

  /// Todos los ítems de la cuenta abierta de la mesa.
  List<ItemPedido> _itemsCuentaMesa() {
    final items = <ItemPedido>[];
    for (final p in _cuentaActual) {
      items.addAll(p.items);
    }
    return items;
  }

  /// Total bruto de la cuenta (suma de líneas, IVA incluido).
  double _totalCuentaBrutaMesa() {
    return _itemsCuentaMesa().fold<double>(0, (sum, i) => sum + i.subtotal);
  }

  bool _cuentaTieneBuffet() {
    return _cuentaActual.any((p) {
      if (p.esBuffet) return true;
      return p.items.any((item) =>
          item.nombreProducto == 'Buffet - Adulto' ||
          item.nombreProducto == 'Buffet - Niño');
    });
  }

  List<Pedido> _copiaPedidosParaEdicion() {
    return _cuentaActual.map((p) => Pedido.fromJson(p.toJson())).toList();
  }

  Future<void> _abrirEdicionConsumo() async {
    if (_cuentaActual.isEmpty || !mounted) return;
    await DialogoEdicionConsumo.mostrar(
      context: context,
      mesaNumero: _mesaSeleccionada,
      pedidos: _copiaPedidosParaEdicion(),
      onEnviarModificaciones: _aplicarModificacionesConsumo,
    );
    if (!mounted) return;
    await _cargarCuentaMesa(_mesaSeleccionada);
    await _cargarMesasConCuentaAbierta();
  }

  double _dineroCobradoAcumuladoMesa() {
    return _cuentaActual.fold<double>(
      0,
      (sum, p) => sum + p.dineroCobradoAcumulado,
    );
  }

  double _totalPropuestoTrasModificaciones(List<LineaConsumoEditable> lineas) {
    return lineas
        .where((l) => l.cantidad > 0)
        .fold<double>(0, (sum, l) => sum + l.subtotal);
  }

  Future<void> _mostrarBloqueoModificacionConsumo({
    required double totalPropuesto,
    required double dineroCobrado,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
        title: const Text('Cambios no permitidos'),
        content: Text(
          'Error: No se pueden aplicar los cambios. El nuevo total de la mesa '
          '(${totalPropuesto.toStringAsFixed(2)}€) no puede ser inferior al dinero ya cobrado '
          'en los pagos parciales (${dineroCobrado.toStringAsFixed(2)}€). '
          'Por favor, devuelva primero el importe correspondiente antes de eliminar los platos.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  /// Aplica cantidades/precios editados, valida caja, imprime cocina y sincroniza pendiente.
  Future<void> _aplicarModificacionesConsumo(
    List<LineaConsumoEditable> lineas,
  ) async {
    // --- 1. Total propuesto (líneas de la ventana flotante) ---
    final totalPropuesto = _totalPropuestoTrasModificaciones(lineas);

    // --- 2. Dinero ya cobrado (vivo en Isar, no histórico JSON) ---
    final dineroCobrado = _dineroCobradoAcumuladoMesa();

    // --- 3. Validación estricta antes de imprimir o persistir ---
    if (totalPropuesto < dineroCobrado - 0.009) {
      await _mostrarBloqueoModificacionConsumo(
        totalPropuesto: totalPropuesto,
        dineroCobrado: dineroCobrado,
      );
      throw const ModificacionConsumoRechazada();
    }

    for (final linea in lineas) {
      if (linea.cantidadEliminada > 0) {
        await ImprimirPedidoService.instance.imprimirEliminacionCocina(
          mesaNumero: _mesaSeleccionada,
          nombrePlato: linea.nombreProducto,
          cantidadEliminada: linea.cantidadEliminada,
          destinoId: linea.destinoId,
        );
      }
    }

    final itemsAdicionCocina = <ItemPedido>[];
    for (final linea in lineas) {
      if (linea.cantidadAnadida <= 0) continue;
      itemsAdicionCocina.add(
        ItemPedido.crear(
          productoId: linea.productoId,
          nombreProducto: linea.nombreProducto,
          precioUnitario: linea.precioUnitario,
          cantidad: linea.cantidadAnadida,
          destinoId: linea.destinoId,
        ),
      );
    }
    if (itemsAdicionCocina.isNotEmpty) {
      final pedidoImpresion = Pedido.crear(
        mesaNumero: _mesaSeleccionada,
        usuarioCamarero: 'Mesero',
        items: itemsAdicionCocina,
      );
      await ImprimirPedidoService.instance.imprimirPedido(pedidoImpresion);
    }

    final porPedido = <int, List<LineaConsumoEditable>>{};
    for (final l in lineas) {
      if (l.pedidoId == null) continue;
      porPedido.putIfAbsent(l.pedidoId!, () => []).add(l);
    }

    for (final pedido in _cuentaActual) {
      final id = pedido.id;
      if (id == null || !porPedido.containsKey(id)) continue;

      final lineasPedido = porPedido[id]!;
      final nuevosItems = <ItemPedido>[];
      for (final l in lineasPedido) {
        if (l.cantidad <= 0) continue;
        if (l.itemIndex >= pedido.items.length) continue;
        final item = pedido.items[l.itemIndex];
        item.cantidad = l.cantidad;
        item.precioUnitario = l.precioUnitario;
        nuevosItems.add(item);
      }

      pedido.items = nuevosItems;

      if (pedido.items.isEmpty) {
        if (sl.isRegistered<ApiClient>()) {
          await sl<ApiClient>().actualizarEstadoPedido(id, EstadoPedido.cancelado);
        } else {
          await DatabaseService.instance.actualizarEstadoPedido(
            id,
            EstadoPedido.cancelado,
          );
        }
      } else if (sl.isRegistered<ApiClient>()) {
        await sl<ApiClient>().guardarPedido(pedido);
      } else {
        await DatabaseService.instance.guardarPedido(pedido);
      }
    }

    // totalPendiente = total − dineroCobradoAcumulado (Isar)
    if (!sl.isRegistered<ApiClient>()) {
      await DatabaseService.instance
          .sincronizarPendienteMesaDesdeCobros(_mesaSeleccionada);
    }
  }

  /// Persiste el cobro en servidor o BD local.
  /// Devuelve `true` si fue pago total, `false` si parcial, `null` si hubo error.
  Future<bool?> _aplicarCobroEnSistema({
    required double importe,
    required MetodoPagoCuenta metodo,
    required bool pagoTotal,
    double? importeRecibido,
  }) async {
    final numero = _mesaSeleccionada;
    try {
      if (sl.isRegistered<ApiClient>()) {
        final res = await sl<ApiClient>().registrarPagoMesa(
          numeroMesa: numero,
          importe: importe,
          metodo: metodo.name,
          importeRecibido: importeRecibido,
          pagoTotal: pagoTotal,
        );
        final lista = res['pedidos'] as List<dynamic>? ?? [];
        if (mounted) {
          setState(() {
            _cuentaActual = lista
                .map((e) => Pedido.fromJson(e as Map<String, dynamic>))
                .toList();
            for (final p in _cuentaActual) {
              p.normalizarTotalPendiente();
            }
          });
        }
        await _cargarMesasConCuentaAbierta();
        return res['esPagoTotal'] as bool? ?? false;
      }

      final db = DatabaseService.instance;
      final pendienteAntes = await db.obtenerTotalPendienteMesa(numero);
      final esTotal = pagoTotal || importe >= pendienteAntes - 0.009;
      final double importeCobrado = esTotal
          ? pendienteAntes
          : importe.clamp(0, pendienteAntes).toDouble();

      final double? vuelto = importeRecibido != null && esTotal
          ? (importeRecibido - importeCobrado)
              .clamp(0, double.infinity)
              .toDouble()
          : null;

      double pendienteRestante;

      if (esTotal) {
        await RegistroPagoService.instance.registrar(
          RegistroPago(
            fecha: DateTime.now(),
            mesaNumero: numero,
            metodo: metodo.name,
            importeCobrado: importeCobrado,
            esParcial: false,
            importeRecibido: importeRecibido,
            vuelto: vuelto,
            pendienteRestante: 0,
            cerrado: true,
          ),
        );
        await db.liberarMesa(numero, isBuffetClose: _cuentaTieneBuffet());
        pendienteRestante = 0;
        if (mounted) setState(() => _cuentaActual = []);
      } else {
        pendienteRestante = await db.aplicarPagoMesa(numero, importeCobrado);
        await RegistroPagoService.instance.registrar(
          RegistroPago(
            fecha: DateTime.now(),
            mesaNumero: numero,
            metodo: metodo.name,
            importeCobrado: importeCobrado,
            esParcial: true,
            importeRecibido: importeRecibido,
            vuelto: vuelto,
            pendienteRestante: pendienteRestante,
          ),
        );
        await _cargarCuentaMesa(numero);
      }

      await _cargarMesasConCuentaAbierta();
      return esTotal;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar pago: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _imprimirTicketFinalCuenta(
    List<ItemPedido> items,
    double total,
  ) async {
    if (items.isEmpty) return;
    final config = await ConfiguracionImpresionService.instance.cargar();
    if (!config.tieneImpresoraCuenta) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configure la impresora de cuenta en Config > Impresora'),
          backgroundColor: Color(0xFFFF9800),
        ),
      );
      return;
    }
    await ImprimirPedidoService.instance.imprimirTicketCuentaMesa(
      _mesaSeleccionada,
      items,
      total,
    );
  }

  /// Confirma un cobro (parcial o total según importe vs pendiente).
  Future<void> _confirmarCobro({
    required MetodoPagoCuenta metodo,
    required double importeIntroducido,
    double? importeRecibidoEfectivo,
  }) async {
    if (importeIntroducido <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Introduzca un importe válido mayor que cero'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final pendienteAntes = _totalPendienteMesa;
    final esPagoTotal = importeIntroducido >= pendienteAntes - 0.009;
    final double importeACobrar = esPagoTotal
        ? pendienteAntes
        : importeIntroducido.clamp(0, pendienteAntes).toDouble();

    final itemsAntes = _itemsCuentaMesa();
    final totalBruto = _totalCuentaBrutaMesa();

    final resultado = await _aplicarCobroEnSistema(
      importe: importeACobrar,
      metodo: metodo,
      pagoTotal: esPagoTotal,
      importeRecibido: importeRecibidoEfectivo,
    );

    if (!mounted || resultado == null) return;

    if (resultado) {
      try {
        await _imprimirTicketFinalCuenta(itemsAntes, totalBruto);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cobro registrado; error al imprimir: $e'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
      if (!mounted) return;
      final vuelto = metodo == MetodoPagoCuenta.efectivo &&
              importeRecibidoEfectivo != null
          ? (importeRecibidoEfectivo - importeACobrar).toDouble()
          : 0.0;
      final avisoTerminal = metodo == MetodoPagoCuenta.tarjeta
          ? ' Cobre €${importeACobrar.toStringAsFixed(2)} en el terminal SumUp.'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            vuelto > 0.009
                ? 'Cuenta cobrada. Vuelto: €${vuelto.toStringAsFixed(2)}$avisoTerminal'
                : 'Cuenta cobrada y mesa liberada.$avisoTerminal',
          ),
          backgroundColor: const Color(0xFF00D9A5),
          duration: metodo == MetodoPagoCuenta.tarjeta
              ? const Duration(seconds: 5)
              : const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Pago parcial
    final pendienteDespues = _totalPendienteMesa;
    try {
      await ImprimirPedidoService.instance.imprimirTicketPagoParcial(
        mesaNumero: _mesaSeleccionada,
        items: itemsAntes,
        totalCuenta: totalBruto,
        importePagado: importeACobrar,
        totalRestante: pendienteDespues,
        metodoPagoEtiqueta: metodo.etiquetaImpresion,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pago registrado; error al imprimir: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    if (!mounted) return;
    final avisoTerminal = metodo == MetodoPagoCuenta.tarjeta
        ? ' Cobre €${importeACobrar.toStringAsFixed(2)} en el terminal SumUp.'
        : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pago parcial ${metodo.nombreUI}: €${importeACobrar.toStringAsFixed(2)}. '
          'Pendiente: €${pendienteDespues.toStringAsFixed(2)}.$avisoTerminal',
        ),
        backgroundColor: const Color(0xFF00D9A5),
        duration: metodo == MetodoPagoCuenta.tarjeta
            ? const Duration(seconds: 5)
            : const Duration(seconds: 3),
      ),
    );
  }

  /// Modal de pagos con menú de métodos y pantalla de importe.
  Future<void> _mostrarDialogoPagos() async {
    if (_cuentaActual.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La mesa no tiene consumo para cobrar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final importeController = TextEditingController();
    MetodoPagoCuenta? metodoSeleccionado;
    var paso = _PasoDialogoPagos.menu;
    var procesando = false;

    double? parseImporte() {
      final t = importeController.text
          .replaceAll(',', '.')
          .trim()
          .toLowerCase();
      if (t.isEmpty || t == 'infinity' || t == 'nan') return null;
      final v = double.tryParse(t);
      if (v == null || v.isNaN || v.isInfinite || v < 0) return null;
      return v;
    }

    await _sincronizarPendientesCuentaMesa();
    if (!mounted) return;

    final pendienteInicial = _totalPendienteMesa;

    await showDialog<void>(
      context: context,
      barrierDismissible: !procesando,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final pendiente = _importeCobroSeguro(
              _totalPendienteMesa,
              pendienteInicial,
            );
            final importe = parseImporte() ?? 0;
            final pendienteValido =
                pendiente.isFinite && pendiente > 0.009;
            final esCobroTotal = pendienteValido &&
                importe >= pendiente - 0.009 &&
                importe > 0;
            final double? vuelto = metodoSeleccionado == MetodoPagoCuenta.efectivo &&
                    esCobroTotal
                ? (importe - pendiente).toDouble()
                : null;

            Future<void> confirmar() async {
              if (!pendienteValido) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('No hay importe pendiente válido en la mesa'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              final valor = parseImporte();
              if (valor == null || valor <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Introduzca un importe válido'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              if (metodoSeleccionado == null) return;

              setDialogState(() => procesando = true);

              await _confirmarCobro(
                metodo: metodoSeleccionado!,
                importeIntroducido: valor,
                importeRecibidoEfectivo:
                    metodoSeleccionado == MetodoPagoCuenta.efectivo
                        ? valor
                        : null,
              );
              if (ctx.mounted) Navigator.of(ctx).pop();
            }

            Widget contenido;
            if (paso == _PasoDialogoPagos.menu) {
              contenido = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Pendiente: €${pendiente.toStringAsFixed(2)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF00D9A5),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: procesando
                        ? null
                        : () => setDialogState(() {
                              metodoSeleccionado = MetodoPagoCuenta.efectivo;
                              paso = _PasoDialogoPagos.importe;
                              if (pendiente.isFinite && pendiente > 0) {
                                importeController.text =
                                    pendiente.toStringAsFixed(2);
                              } else {
                                importeController.clear();
                              }
                            }),
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Efectivo'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00D9A5),
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: procesando
                        ? null
                        : () => setDialogState(() {
                              metodoSeleccionado = MetodoPagoCuenta.tarjeta;
                              paso = _PasoDialogoPagos.importe;
                              if (pendiente.isFinite && pendiente > 0) {
                                importeController.text =
                                    pendiente.toStringAsFixed(2);
                              } else {
                                importeController.clear();
                              }
                            }),
                    icon: const Icon(Icons.credit_card),
                    label: const Text('Tarjeta'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F3460),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: procesando
                        ? null
                        : () => setDialogState(() {
                              metodoSeleccionado = MetodoPagoCuenta.otros;
                              paso = _PasoDialogoPagos.importe;
                              if (pendiente.isFinite && pendiente > 0) {
                                importeController.text =
                                    pendiente.toStringAsFixed(2);
                              } else {
                                importeController.clear();
                              }
                            }),
                    icon: const Icon(Icons.more_horiz),
                    label: const Text('Otros'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE94560),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              );
            } else {
              final etiquetaMetodo = metodoSeleccionado?.nombreUI ?? '';
              contenido = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '$etiquetaMetodo — Mesa $_mesaSeleccionada',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pendiente: €${pendiente.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF00D9A5),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: importeController,
                    enabled: !procesando,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: metodoSeleccionado == MetodoPagoCuenta.efectivo
                          ? 'Importe recibido'
                          : 'Importe a cobrar',
                      labelStyle: const TextStyle(color: Colors.white54),
                      prefixText: '€ ',
                      prefixStyle: const TextStyle(
                        color: Color(0xFF00D9A5),
                        fontSize: 22,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0F3460),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  if (metodoSeleccionado == MetodoPagoCuenta.tarjeta) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Tras confirmar, cobre este importe manualmente en el terminal SumUp.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.blue.shade200,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (importe > 0 && importe < pendiente - 0.009) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Pago parcial: quedarán €${(pendiente - importe).toStringAsFixed(2)} pendientes',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.orange.shade300,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (vuelto != null && vuelto > 0.009) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D9A5).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF00D9A5)),
                      ),
                      child: Text(
                        'Vuelto a devolver: €${vuelto.toStringAsFixed(2)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF00D9A5),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: procesando ? null : confirmar,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFBB86FC),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: procesando
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            esCobroTotal ? 'Confirmar cobro total' : 'Confirmar pago parcial',
                          ),
                  ),
                ],
              );
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF16213E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  const Icon(Icons.payments, color: Color(0xFFBB86FC)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      paso == _PasoDialogoPagos.menu
                          ? 'Pagos — Mesa $_mesaSeleccionada'
                          : 'Cobro',
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: contenido,
              actions: [
                if (paso == _PasoDialogoPagos.importe)
                  TextButton(
                    onPressed: procesando
                        ? null
                        : () => setDialogState(() {
                              paso = _PasoDialogoPagos.menu;
                              importeController.clear();
                            }),
                    child: const Text('Atrás'),
                  ),
                TextButton(
                  onPressed: procesando ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );

    importeController.dispose();
  }

  /// Imprime el ticket de cuenta de la mesa (platos y total) en la impresora configurada.
  Future<void> _imprimirTicketCuenta() async {
    if (_cuentaActual.isEmpty || !mounted) return;
    final config = await ConfiguracionImpresionService.instance.cargar();
    if (!config.tieneImpresoraCuenta) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configure la impresora de ticket de cuenta en Config > Impresora'),
          backgroundColor: Color(0xFFFF9800),
        ),
      );
      return;
    }
    final items = <ItemPedido>[];
    for (final p in _cuentaActual) {
      items.addAll(p.items);
    }
    final total = items.fold<double>(0, (sum, item) => sum + item.subtotal);
    try {
      await ImprimirPedidoService.instance.imprimirTicketCuentaMesa(
        _mesaSeleccionada,
        items,
        total,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ticket enviado a la impresora'),
          backgroundColor: Color(0xFF00D9A5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al imprimir: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Base URL del servidor para el QR: prioriza la IP de red (192.168.x.x) para que
  /// los móviles puedan escanear; si el servidor está activo usa su URL, si no el serverUrl global.
  String _obtenerBaseUrlServidor() {
    if (sl.isRegistered<LocalServer>() && LocalServer.instance.serverUrl != null) {
      final url = LocalServer.instance.serverUrl!;
      return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    }
    final base = serverUrl ?? 'http://localhost:8080';
    return base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  }

  Future<void> _mostrarDialogoQrMesa(int numeroMesa) async {
    final baseUrl = _obtenerBaseUrlServidor();
    String qrUrl;
    try {
      final token = await DatabaseService.instance.getQrTokenForMesa(numeroMesa);
      qrUrl = '$baseUrl/qr/$token';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo generar el QR: $e'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF00D9A5), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D9A5).withValues(alpha: 0.2),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.qr_code_2, color: Color(0xFF00D9A5), size: 28),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Escanee para pedir desde su móvil',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Mesa $numeroMesa',
                style: const TextStyle(
                  color: Color(0xFF00D9A5),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: qrUrl,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF1A1A2E),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Mesa $numeroMesa',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
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
                          categorias: _categorias.isNotEmpty ? _categorias : null,
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
                            popularidadPorProductoId: _popularidadPorProductoId,
                            factorTamanoTarjeta: 0.7,
                            gridAnchoFactor: 1.155, // +10 % y luego +5 % (1.1 × 1.05)
                            gridAltoFraccion: 0.51,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Panel lateral - Carrito
                  CarritoPanel(
                    mesaSeleccionada: _mesaSeleccionada,
                    numerosMesas: _numerosMesas,
                    items: _carrito,
                    consumoActual: _cuentaActual,
                    mesasConCuentaAbierta: _mesasConCuentaAbierta,
                    onMesaChanged: (mesa) {
                      setState(() => _mesaSeleccionada = mesa);
                      _cargarCuentaMesa(mesa);
                    },
                    onMesaTap: _alSeleccionarMesa,
                    onMostrarQrMesa: _mostrarDialogoQrMesa,
                    onItemRemoved: _removerDelCarrito,
                    onOrdenChanged: _cambiarOrden,
                    onEnviar: _enviarPedido,
                    onLiberar: _mostrarDialogoLiberarMesa,
                    onImprimirCuenta: _imprimirTicketCuenta,
                    onPagos: _mostrarDialogoPagos,
                    onEditarConsumo: _cuentaActual.isEmpty
                        ? null
                        : _abrirEdicionConsumo,
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

          // Refrescar mesas (tras cambiar Config > Mesas)
          IconButton(
            onPressed: () async {
              await _cargarMesas();
              await _cargarMesasConCuentaAbierta();
              if (mounted) setState(() {});
            },
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: 'Actualizar lista de mesas',
          ),
          
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
      // Cada pulsación añade una línea (no se apilan)
      _carrito.add(ItemCarrito(producto: producto, cantidad: 1, orden: 1));
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

  void _cambiarOrden(int index, int orden) {
    setState(() {
      _carrito[index].orden = orden;
    });
  }

  Future<void> _enviarPedido() async {
    final tieneApertura = _adultosBuffet > 0 || _ninosBuffet > 0 || _cubiertos > 0;
    if (_carrito.isEmpty && !tieneApertura) {
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
      final db = DatabaseService.instance;

      // =====================================================
      // VALIDACIÓN DE STOCK - Usar la misma BD donde se guarda el pedido
      // =====================================================
      final cantidadPorProducto = <int, int>{};
      for (final item in _carrito) {
        final id = item.producto.id;
        if (id == null) continue;
        cantidadPorProducto[id] = (cantidadPorProducto[id] ?? 0) + item.cantidad;
      }

      if (cantidadPorProducto.isNotEmpty) {
        final ajustes = <Map<String, dynamic>>[];
        final agotados = <int>{};

        for (final entry in cantidadPorProducto.entries) {
          final id = entry.key;
          final solicitado = entry.value;
          final producto = await db.obtenerProductoPorId(id);

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

        if (ajustes.isNotEmpty || agotados.isNotEmpty) {
          setState(() {
            _productosAgotados = agotados;
          });
          if (mounted) {
            await _mostrarDialogoValidacionStock(ajustes, agotados);
          }
          setState(() => _enviando = false);
          return;
        }
      }

      setState(() {
        _productosAgotados.clear();
      });

      // =====================================================
      // PROCESAR PEDIDO
      // =====================================================

      // Agrupar productos por destino (los de apertura - buffet/cubiertos - ya están en _carrito)
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
          notas: item.notas,
          destinoId: destinoId,
          nombreDestino: nombreDestino,
          orden: item.orden,
        );
        
        itemsPorDestino.putIfAbsent(destinoId, () => []).add(itemPedido);
      }

      // Crear lista plana de todos los items
      final todosItems = itemsPorDestino.values.expand((items) => items).toList();
      
      // Crear el pedido
      final esBuffet = _adultosBuffet > 0 || _ninosBuffet > 0;
      final pedido = Pedido.crear(
        mesaNumero: _mesaSeleccionada,
        usuarioCamarero: 'Mesero', // TODO: Obtener del usuario logueado
        items: todosItems,
        esBuffet: esBuffet,
        numeroComensales: esBuffet ? (_adultosBuffet + _ninosBuffet) : _cubiertos,
      );
      pedido.calcularTotal();

      // Guardar en la base de datos
      final pedidoId = await db.guardarPedido(pedido);

      // Descontar stock de productos con inventario activado
      for (final item in pedido.items) {
        if (item.productoId <= 0) continue;
        final ok = await db.decrementarStock(item.productoId, item.cantidad);
        if (!ok) {
          debugPrint('⚠️ No se pudo descontar stock del producto ${item.productoId} (${item.nombreProducto})');
        }
      }
      
      // Actualizar estado de la mesa
      await db.actualizarEstadoMesa(_mesaSeleccionada, EstadoMesa.ocupada);

      debugPrint('✅ Pedido #$pedidoId creado para mesa $_mesaSeleccionada');

      // Imprimir en cada impresora configurada por destino (fire-and-forget)
      ImprimirPedidoService.instance.imprimirPedido(pedido).catchError((e, st) {
        debugPrint('Error al imprimir pedido: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al imprimir: $e'), backgroundColor: Colors.orange),
          );
        }
      });

      // Mostrar resumen del envío con destinos dinámicos
      if (mounted) {
        _mostrarResumenEnvio(itemsPorDestino);
      }
      
      // Limpiar carrito y datos de apertura de mesa
      setState(() {
        _carrito.clear();
        _adultosBuffet = 0;
        _ninosBuffet = 0;
        _cubiertos = 0;
      });

      // Actualizar cuenta actual y mesas con cuenta abierta
      _cargarCuentaMesa(_mesaSeleccionada);
      _cargarMesasConCuentaAbierta();
      _cargarPopularidadProductos();

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
                    ? 'STOCK INSUFICIENTE'
                    : tieneAjustes && tieneAgotados
                        ? 'STOCK INSUFICIENTE Y AGOTADOS'
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
                  'No hay stock suficiente. Quita o cambia los platos indicados en el carrito para poder enviar el pedido.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                )
              else if (tieneAjustes && tieneAgotados)
                const Text(
                  'Algunos productos tienen stock limitado y otros están agotados. Quita o cambia platos del carrito para poder enviar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                )
              else
                const Text(
                  'No se puede enviar el pedido. Quita los artículos agotados del carrito.',
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
                      final solicitado = ajuste['solicitado'] as int;
                      final disponible = ajuste['disponible'] as int;
                      final quitar = solicitado - disponible;
                      final textoQuitar = ' en stock. Quita $quitar plato${quitar == 1 ? '' : 's'} del carrito.';
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
                                    const TextSpan(
                                      text: 'solo hay ',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    TextSpan(
                                      text: '$disponible',
                                      style: const TextStyle(
                                        color: Color(0xFFFFA500),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: textoQuitar,
                                      style: const TextStyle(color: Colors.white70),
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

/// Modelo para items en el carrito local (cada línea es un plato; no se apilan)
class ItemCarrito {
  final Producto producto;
  /// Siempre 1: cada línea es un plato individual
  int cantidad;
  /// Orden del plato: 1 = 1º, 2 = 2º, etc.
  int orden;
  String? notas;

  ItemCarrito({
    required this.producto,
    this.cantidad = 1,
    this.orden = 1,
    this.notas,
  });

  double get subtotal => producto.precio * cantidad;
}
