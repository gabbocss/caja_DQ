import 'package:flutter/material.dart';

import '../../../../core/core.dart';

/// Pantalla de gestión de categorías del menú
///
/// Permite crear, editar y eliminar categorías de productos
class GestionCategoriasPage extends StatefulWidget {
  const GestionCategoriasPage({super.key});

  @override
  State<GestionCategoriasPage> createState() => _GestionCategoriasPageState();
}

class _GestionCategoriasPageState extends State<GestionCategoriasPage> {
  List<Categoria> _categorias = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    setState(() => _cargando = true);
    try {
      _categorias = await DatabaseService.instance.obtenerCategorias();
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('CATEGORÍAS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFF00D9A5)),
            onPressed: () => _mostrarDialogoCategoria(),
            tooltip: 'Agregar categoría',
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _categorias.isEmpty
              ? _buildEmptyState()
              : _buildListaCategorias(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category,
            size: 80,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'No hay categorías configuradas',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () => _mostrarDialogoCategoria(),
            icon: const Icon(Icons.add),
            label: const Text('Agregar categoría'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D9A5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaCategorias() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _categorias.length,
      onReorder: _reordenarCategorias,
      itemBuilder: (context, index) {
        final cat = _categorias[index];
        return _CategoriaCard(
          key: ValueKey(cat.id),
          categoria: cat,
          onEdit: () => _mostrarDialogoCategoria(categoria: cat),
          onDelete: () => _confirmarEliminar(cat),
        );
      },
    );
  }

  Future<void> _reordenarCategorias(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _categorias.removeAt(oldIndex);
      _categorias.insert(newIndex, item);
    });

    final db = DatabaseService.instance;
    try {
      // Guardar nuevo orden de categorías
      for (int i = 0; i < _categorias.length; i++) {
        _categorias[i].orden = i;
        await db.guardarCategoria(_categorias[i]);
      }
      // Recalcular orden global de productos para que vistas "TODOS" (cliente QR) respeten el orden.
      await db.recalcularOrdenProductosPorCategorias();
    } catch (e) {
      debugPrint('Error al reordenar categorías: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmarEliminar(Categoria categoria) async {
    final count = await DatabaseService.instance
        .contarProductosPorCategoria(categoria.nombre);

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '¿Eliminar categoría?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Eliminar "${categoria.nombre}"?\n\n'
          '${count > 0 ? "Hay $count producto(s) con esta categoría. Quedarán sin categoría." : "No hay productos con esta categoría."}',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      await DatabaseService.instance.eliminarCategoria(categoria.id!);
      await _cargarCategorias();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Categoría eliminada'),
            backgroundColor: Color(0xFFE94560),
          ),
        );
      }
    }
  }

  void _mostrarDialogoCategoria({Categoria? categoria}) {
    showDialog(
      context: context,
      builder: (context) => _DialogoCategoria(
        categoria: categoria,
        ordenNuevo: _categorias.length,
        onGuardar: (nuevaCategoria) async {
          if (categoria != null && categoria.nombre != nuevaCategoria.nombre) {
            await DatabaseService.instance.renombrarCategoria(
              categoria.id!,
              nuevaCategoria.nombre,
            );
          } else {
            await DatabaseService.instance.guardarCategoria(nuevaCategoria);
          }
          await _cargarCategorias();
        },
      ),
    );
  }
}

class _CategoriaCard extends StatelessWidget {
  final Categoria categoria;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoriaCard({
    super.key,
    required this.categoria,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF16213E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(0xFF00D9A5).withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF00D9A5).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.category,
            color: Color(0xFF00D9A5),
            size: 28,
          ),
        ),
        title: Text(
          categoria.nombre,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF4FC3F7)),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Color(0xFFE94560)),
              onPressed: onDelete,
            ),
            const Icon(Icons.drag_handle, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

class _DialogoCategoria extends StatefulWidget {
  final Categoria? categoria;
  final int ordenNuevo;
  final Future<void> Function(Categoria) onGuardar;

  const _DialogoCategoria({
    this.categoria,
    this.ordenNuevo = 0,
    required this.onGuardar,
  });

  @override
  State<_DialogoCategoria> createState() => _DialogoCategoriaState();
}

class _DialogoCategoriaState extends State<_DialogoCategoria> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.categoria?.nombre);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      final cat = widget.categoria ?? Categoria();
      cat.nombre = _nombreController.text.trim();
      cat.orden = widget.categoria?.orden ?? widget.ordenNuevo;

      await widget.onGuardar(cat);
      if (mounted) Navigator.pop(context);
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
    return Dialog(
      backgroundColor: const Color(0xFF16213E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.categoria == null ? 'NUEVA CATEGORÍA' : 'EDITAR CATEGORÍA',
                style: const TextStyle(
                  color: Color(0xFF00D9A5),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nombreController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF0F3460),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _guardando ? null : _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D9A5),
                    ),
                    child: _guardando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Guardar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
