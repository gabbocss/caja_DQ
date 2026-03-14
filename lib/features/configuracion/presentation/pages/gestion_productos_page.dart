import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/core.dart';

/// Pantalla de gestión de productos del menú
/// 
/// Permite ver, editar, crear y cambiar la disponibilidad de productos
class GestionProductosPage extends StatefulWidget {
  const GestionProductosPage({super.key});

  @override
  State<GestionProductosPage> createState() => _GestionProductosPageState();
}

class _GestionProductosPageState extends State<GestionProductosPage> {
  List<Producto> _productos = [];
  List<DestinoImpresion> _destinos = [];
  List<Categoria> _categoriasDb = [];
  bool _cargando = true;
  String? _filtroCategoria;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      _productos = await DatabaseService.instance.obtenerProductos();
      _destinos = await DatabaseService.instance.obtenerDestinosActivos();
      _categoriasDb = await DatabaseService.instance.obtenerCategorias();
    } catch (e) {
      debugPrint('Error al cargar datos: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<String> get _categorias {
    final cats = _productos.map((p) => p.categoria ?? 'Sin categoría').toSet().toList();
    cats.sort();
    return cats;
  }

  List<Producto> get _productosFiltrados {
    if (_filtroCategoria == null) return _productos;
    return _productos.where((p) => p.categoria == _filtroCategoria).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Row(
          children: [
            Icon(Icons.restaurant_menu, color: Color(0xFFE94560)),
            SizedBox(width: 12),
            Text(
              'GESTIÓN DE PRODUCTOS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          // Botón añadir producto
          IconButton(
            onPressed: () => _mostrarFormularioProducto(null),
            icon: const Icon(Icons.add_circle, color: Color(0xFF00D9A5)),
            tooltip: 'Añadir producto',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
          : Column(
              children: [
                // Filtro por categoría
                _buildFiltroCategorias(),
                
                // Contador de productos
                _buildContador(),
                
                // Lista de productos (solo se puede reordenar con "Todos" seleccionado)
                Expanded(
                  child: _productosFiltrados.isEmpty
                      ? _buildSinProductos()
                      : _buildListaProductos(),
                ),
              ],
            ),
    );
  }

  Widget _buildFiltroCategorias() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xFF16213E),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _CategoriaChip(
            label: 'Todos',
            isSelected: _filtroCategoria == null,
            onTap: () => setState(() => _filtroCategoria = null),
          ),
          const SizedBox(width: 8),
          ..._categorias.map((cat) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _CategoriaChip(
              label: cat,
              isSelected: _filtroCategoria == cat,
              onTap: () => setState(() => _filtroCategoria = cat),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildContador() {
    final disponibles = _productosFiltrados.where((p) => p.isAvailable).length;
    final agotados = _productosFiltrados.length - disponibles;
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF0F3460),
      child: Row(
        children: [
          Text(
            '${_productosFiltrados.length} productos',
            style: const TextStyle(color: Colors.white70),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00D9A5).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$disponibles disponibles',
              style: const TextStyle(color: Color(0xFF00D9A5), fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE94560).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$agotados agotados',
              style: const TextStyle(color: Color(0xFFE94560), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinProductos() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay productos',
            style: TextStyle(color: Colors.white54, fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _mostrarFormularioProducto(null),
            icon: const Icon(Icons.add),
            label: const Text('Añadir producto'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D9A5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaProductos() {
    final lista = _productosFiltrados;
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lista.length,
      onReorder: _reordenarProductos,
      itemBuilder: (context, index) {
        final producto = lista[index];
        return _ProductoTile(
          key: ValueKey(producto.id),
          producto: producto,
          destinos: _destinos,
          showDragHandle: true,
          reorderIndex: index,
          onToggleDisponibilidad: () => _toggleDisponibilidad(producto),
          onEditar: () => _mostrarFormularioProducto(producto),
          onEliminar: () => _confirmarEliminar(producto),
        );
      },
    );
  }

  /// Orden de productos: categoría * 1000 + índice dentro de la categoría.
  int _ordenParaProducto(String? categoria, int indiceEnCategoria) {
    final cat = _categoriasDb.where((c) => c.nombre == categoria).firstOrNull;
    return (cat?.orden ?? 9999) * 1000 + indiceEnCategoria;
  }

  Future<void> _reordenarProductos(int oldIndex, int newIndex) async {
    final db = DatabaseService.instance;
    if (_filtroCategoria != null) {
      // Reordenar solo dentro de la categoría seleccionada
      final filtered = List<Producto>.from(_productosFiltrados);
      if (newIndex > oldIndex) newIndex--;
      final item = filtered.removeAt(oldIndex);
      filtered.insert(newIndex, item);
      final catOrden = _categoriasDb
          .where((c) => c.nombre == _filtroCategoria)
          .firstOrNull
          ?.orden ?? 0;
      for (int i = 0; i < filtered.length; i++) {
        filtered[i].orden = catOrden * 1000 + i;
        await db.guardarProducto(filtered[i]);
      }
    } else {
      // Reordenar lista completa (Todos): asignar orden = categoría*1000 + índice en categoría
      setState(() {
        if (newIndex > oldIndex) newIndex--;
        final item = _productos.removeAt(oldIndex);
        _productos.insert(newIndex, item);
      });
      final ordenPorCategoria = <String, int>{};
      for (final p in _productos) {
        final cat = p.categoria ?? '';
        final idx = ordenPorCategoria[cat] ?? 0;
        ordenPorCategoria[cat] = idx + 1;
        p.orden = _ordenParaProducto(p.categoria, idx);
      }
      for (final p in _productos) {
        await db.guardarProducto(p);
      }
    }
    await _cargarDatos();
  }

  Future<void> _toggleDisponibilidad(Producto producto) async {
    try {
      await DatabaseService.instance.actualizarDisponibilidad(
        producto.id!,
        !producto.isAvailable,
      );
      await _cargarDatos();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              producto.isAvailable
                  ? '${producto.nombre} marcado como AGOTADO'
                  : '${producto.nombre} marcado como DISPONIBLE',
            ),
            backgroundColor: producto.isAvailable
                ? const Color(0xFFE94560)
                : const Color(0xFF00D9A5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _mostrarFormularioProducto(Producto? producto) {
    showDialog(
      context: context,
      builder: (context) => _ProductoFormDialog(
        producto: producto,
        destinos: _destinos,
        categoriasDisponibles: _categoriasDb.isEmpty
            ? CategoriaProducto.todas
            : _categoriasDb.map((c) => c.nombre).toList(),
        onGuardar: () {
          Navigator.of(context).pop();
          _cargarDatos();
        },
      ),
    );
  }

  void _confirmarEliminar(Producto producto) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '¿Eliminar ${producto.nombre}?',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Text(
          'Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await DatabaseService.instance.eliminarProducto(producto.id!);
              _cargarDatos();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

/// Chip de categoría para filtrado
class _CategoriaChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoriaChip({
    required this.label,
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
            color: isSelected ? const Color(0xFFE94560) : const Color(0xFF0F3460),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

/// Tile de producto individual
class _ProductoTile extends StatelessWidget {
  final Producto producto;
  final List<DestinoImpresion> destinos;
  final bool showDragHandle;
  final int? reorderIndex;
  final VoidCallback onToggleDisponibilidad;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _ProductoTile({
    super.key,
    required this.producto,
    required this.destinos,
    this.showDragHandle = false,
    this.reorderIndex,
    required this.onToggleDisponibilidad,
    required this.onEditar,
    required this.onEliminar,
  });

  String get _nombreDestino {
    if (producto.destinoId == null) return 'Sin destino';
    final destino = destinos.where((d) => d.id == producto.destinoId).firstOrNull;
    return destino?.nombre ?? 'Desconocido';
  }

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: const Color(0xFF16213E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: producto.isAvailable
              ? const Color(0xFF0F3460)
              : const Color(0xFFE94560).withValues(alpha: 0.5),
          width: producto.isAvailable ? 1 : 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (showDragHandle && reorderIndex != null) ...[
              ReorderableDragStartListener(
                index: reorderIndex!,
                child: const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.drag_handle, color: Colors.white38, size: 24),
                ),
              ),
            ],
            // Indicador de disponibilidad
            Container(
              width: 8,
              height: 60,
              decoration: BoxDecoration(
                color: producto.isAvailable
                    ? const Color(0xFF00D9A5)
                    : const Color(0xFFE94560),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 16),
            
            // Info del producto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          producto.nombre,
                          style: TextStyle(
                            color: producto.isAvailable ? Colors.white : Colors.white60,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            decoration: producto.isAvailable ? null : TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                      if (producto.esBuffet)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '⭐ BUFFET',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${producto.precio.toStringAsFixed(2)}€',
                        style: const TextStyle(
                          color: Color(0xFF00D9A5),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F3460),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          producto.categoria ?? 'Sin categoría',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '→ $_nombreDestino',
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Toggle de disponibilidad
            Column(
              children: [
                Switch(
                  value: producto.isAvailable,
                  onChanged: (_) => onToggleDisponibilidad(),
                  activeTrackColor: const Color(0xFF00D9A5),
                  inactiveTrackColor: const Color(0xFFE94560).withValues(alpha: 0.5),
                  thumbColor: WidgetStateProperty.all(Colors.white),
                ),
                Text(
                  producto.isAvailable ? 'Disponible' : 'Agotado',
                  style: TextStyle(
                    color: producto.isAvailable
                        ? const Color(0xFF00D9A5)
                        : const Color(0xFFE94560),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Botón de menú (área 40x40 para no solaparse con el switch)
            Builder(
              builder: (btnContext) {
                return SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert, color: Colors.white54, size: 24),
                    onPressed: () {
                      final box = btnContext.findRenderObject() as RenderBox?;
                      final overlay = Overlay.of(btnContext).context.findRenderObject() as RenderBox?;
                      if (box != null && overlay != null) {
                        final pos = box.localToGlobal(Offset.zero, ancestor: overlay);
                        final size = box.size;
                        final position = RelativeRect.fromLTRB(
                          pos.dx,
                          pos.dy + size.height,
                          pos.dx + size.width,
                          pos.dy + size.height + 8,
                        );
                        showMenu<String>(
                          context: btnContext,
                          position: position,
                          color: const Color(0xFF16213E),
                          items: [
                            PopupMenuItem<String>(
                              value: 'editar',
                              onTap: () => onEditar(),
                              child: const Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.white70, size: 20),
                                  SizedBox(width: 12),
                                  Text('Editar', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'eliminar',
                              onTap: () => onEliminar(),
                              child: const Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red, size: 20),
                                  SizedBox(width: 12),
                                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white54,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
    return card;
  }
}

/// Diálogo para crear/editar producto
class _ProductoFormDialog extends StatefulWidget {
  final Producto? producto;
  final List<DestinoImpresion> destinos;
  final List<String> categoriasDisponibles;
  final VoidCallback onGuardar;

  const _ProductoFormDialog({
    this.producto,
    required this.destinos,
    required this.categoriasDisponibles,
    required this.onGuardar,
  });

  @override
  State<_ProductoFormDialog> createState() => _ProductoFormDialogState();
}

class _ProductoFormDialogState extends State<_ProductoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _precioController;
  late TextEditingController _descripcionController;
  late TextEditingController _categoriaController;
  late TextEditingController _stockController;
  int? _destinoId;
  bool _esBuffet = false;
  bool _isAvailable = true;
  bool _usarInventario = false;
  bool _guardando = false;
  List<String> _alergenos = [];
  /// Imagen del producto: data URL (base64) o URL existente
  String? _imagen;

  /// Lista de categorías para el dropdown, incluyendo la actual del producto si no está en la lista
  /// (evita error cuando se renombró o eliminó una categoría pero el producto sigue con la antigua)
  List<String> get _categoriasParaDropdown {
    final base = widget.categoriasDisponibles;
    final catActual = widget.producto?.categoria;
    if (catActual == null || catActual.isEmpty || base.contains(catActual)) {
      return base;
    }
    return [catActual, ...base];
  }

  static const _opcionesAlergenos = [
    ('gluten', 'Gluten'),
    ('lacteos', 'Lácteos'),
    ('frutos_secos', 'Frutos secos'),
    ('huevo', 'Huevo'),
    ('picante', 'Picante'),
    ('vegano', 'Vegano'),
  ];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.producto?.nombre ?? '');
    _precioController = TextEditingController(
      text: widget.producto?.precio.toStringAsFixed(2) ?? '',
    );
    _descripcionController = TextEditingController(text: widget.producto?.descripcion ?? '');
    _categoriaController = TextEditingController(text: widget.producto?.categoria ?? '');
    _stockController = TextEditingController(
      text: widget.producto?.stockDisponible.toString() ?? '0',
    );
    _destinoId = widget.producto?.destinoId;
    _esBuffet = widget.producto?.esBuffet ?? false;
    _isAvailable = widget.producto?.isAvailable ?? true;
    _usarInventario = widget.producto?.usarInventario ?? false;
    _alergenos = List.from(widget.producto?.alergenos ?? []);
    _imagen = widget.producto?.imagen;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _descripcionController.dispose();
    _categoriaController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _elegirFoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.single.bytes;
    if (bytes == null || bytes.isEmpty) return;
    try {
      final base64 = base64Encode(bytes);
      final ext = (result.files.single.extension ?? '').toLowerCase();
      final mime = ext == 'png' ? 'png' : 'jpeg';
      if (!mounted) return;
      setState(() => _imagen = 'data:image/$mime;base64,$base64');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar la imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _quitarFoto() {
    setState(() => _imagen = null);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final producto = widget.producto ?? Producto();
      producto.nombre = _nombreController.text;
      producto.precio = double.parse(_precioController.text);
      producto.descripcion = _descripcionController.text.isEmpty ? null : _descripcionController.text;
      producto.categoria = _categoriaController.text.isEmpty ? null : _categoriaController.text;
      producto.destinoId = _destinoId;
      producto.esBuffet = _esBuffet;
      producto.isAvailable = _isAvailable;
      producto.usarInventario = _usarInventario;
      producto.stockDisponible = int.tryParse(_stockController.text) ?? 0;
      producto.alergenos = List.from(_alergenos);
      producto.imagen = _imagen;
      producto.activo = true;
      producto.destino = _destinoId != null
          ? (widget.destinos.where((d) => d.id == _destinoId).firstOrNull?.nombre == 'Barra'
              ? DestinoProducto.barra
              : DestinoProducto.cocina)
          : DestinoProducto.cocina;
      
      // Si el inventario está activado y el stock llega a 0, marcar como no disponible
      if (producto.usarInventario && producto.stockDisponible <= 0) {
        producto.isAvailable = false;
      }
      
      if (widget.producto == null) {
        producto.fechaCreacion = DateTime.now();
      }
      producto.fechaModificacion = DateTime.now();

      await DatabaseService.instance.guardarProducto(producto);
      widget.onGuardar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esNuevo = widget.producto == null;
    
    return Dialog(
      backgroundColor: const Color(0xFF16213E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F3460),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      esNuevo ? Icons.add_circle : Icons.edit,
                      color: const Color(0xFFE94560),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      esNuevo ? 'NUEVO PRODUCTO' : 'EDITAR PRODUCTO',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              
              // Formulario
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Nombre
                      TextFormField(
                        controller: _nombreController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Nombre del producto', Icons.label),
                        validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      // Precio
                      TextFormField(
                        controller: _precioController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                        decoration: _inputDecoration('Precio (€)', Icons.euro),
                        validator: (v) {
                          if (v?.isEmpty ?? true) return 'Requerido';
                          if (double.tryParse(v!) == null) return 'Precio inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Descripción
                      TextFormField(
                        controller: _descripcionController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 2,
                        decoration: _inputDecoration('Descripción (opcional)', Icons.description),
                      ),
                      const SizedBox(height: 16),
                      
                      // Foto del producto
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Foto del producto',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (_imagen != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _imagen!.startsWith('data:')
                                  ? Image.memory(
                                      base64Decode(_imagen!.split(',').last),
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      _imagen!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.broken_image,
                                        size: 80,
                                        color: Colors.white54,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _elegirFoto,
                                  icon: const Icon(Icons.add_photo_alternate, size: 20),
                                  label: Text(_imagen == null ? 'Añadir foto' : 'Cambiar foto'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white70,
                                    side: const BorderSide(color: Colors.white38),
                                  ),
                                ),
                                if (_imagen != null) ...[
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: _quitarFoto,
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Colors.redAccent,
                                    ),
                                    label: const Text(
                                      'Quitar foto',
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Alérgenos / Características
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Alérgenos / Características',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _opcionesAlergenos.map((entry) {
                          final key = entry.$1;
                          final label = entry.$2;
                          final selected = _alergenos.contains(key);
                          return FilterChip(
                            label: Text(label),
                            selected: selected,
                            onSelected: (v) {
                              setState(() {
                                if (v) {
                                  _alergenos = List.from(_alergenos)..add(key);
                                } else {
                                  _alergenos = List.from(_alergenos)..remove(key);
                                }
                              });
                            },
                            selectedColor: const Color(0xFF00D9A5).withValues(alpha: 0.35),
                            checkmarkColor: const Color(0xFF00D9A5),
                            labelStyle: TextStyle(
                              color: selected ? const Color(0xFF00D9A5) : Colors.white70,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            ),
                            backgroundColor: const Color(0xFF0F3460),
                            side: BorderSide(
                              color: selected ? const Color(0xFF00D9A5) : Colors.white24,
                              width: selected ? 2 : 1,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      
                      // Categoría con sugerencias
                      DropdownButtonFormField<String?>(
                        initialValue: _categoriaController.text.isEmpty ? null : _categoriaController.text,
                        decoration: _inputDecoration('Categoría', Icons.category),
                        dropdownColor: const Color(0xFF0F3460),
                        style: const TextStyle(color: Colors.white),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Seleccionar...')),
                          ..._categoriasParaDropdown.map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
                          )),
                        ],
                        onChanged: (value) => setState(() => _categoriaController.text = value ?? ''),
                      ),
                      const SizedBox(height: 16),
                      
                      // Destino
                      DropdownButtonFormField<int?>(
                        initialValue: _destinoId,
                        decoration: _inputDecoration('Destino de impresión', Icons.print),
                        dropdownColor: const Color(0xFF0F3460),
                        style: const TextStyle(color: Colors.white),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Sin destino'),
                          ),
                          ...widget.destinos.map((d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(d.nombre),
                          )),
                        ],
                        onChanged: (value) => setState(() => _destinoId = value),
                      ),
                      const SizedBox(height: 20),
                      
                      // Switches
                      Row(
                        children: [
                          Expanded(
                            child: _SwitchTile(
                              label: 'Disponible',
                              value: _isAvailable,
                              activeColor: const Color(0xFF00D9A5),
                              onChanged: (v) => setState(() => _isAvailable = v),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _SwitchTile(
                              label: 'Buffet',
                              value: _esBuffet,
                              activeColor: const Color(0xFFFFD700),
                              onChanged: (v) => setState(() => _esBuffet = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Control de inventario
                      _SwitchTile(
                        label: 'Usar control de inventario',
                        value: _usarInventario,
                        activeColor: const Color(0xFFE94560),
                        onChanged: (v) => setState(() => _usarInventario = v),
                      ),
                      const SizedBox(height: 16),
                      
                      // Campo de stock (solo visible si usarInventario está activado)
                      if (_usarInventario)
                        TextFormField(
                          controller: _stockController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: _inputDecoration('Stock disponible', Icons.inventory_2),
                          validator: (v) {
                            if (_usarInventario && (v?.isEmpty ?? true)) {
                              return 'Requerido cuando el inventario está activado';
                            }
                            if (v != null && v.isNotEmpty) {
                              final stock = int.tryParse(v);
                              if (stock == null || stock < 0) {
                                return 'Debe ser un número positivo';
                              }
                            }
                            return null;
                          },
                        ),
                    ],
                  ),
                ),
              ),
              
              // Botones
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFF0F3460))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.white38),
                        ),
                        child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _guardando ? null : _guardar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D9A5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _guardando
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF0F3460),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE94560), width: 2),
      ),
    );
  }
}

/// Widget de switch con etiqueta
class _SwitchTile extends StatelessWidget {
  final String label;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.label,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3460),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: activeColor,
            thumbColor: WidgetStateProperty.all(Colors.white),
          ),
        ],
      ),
    );
  }
}
