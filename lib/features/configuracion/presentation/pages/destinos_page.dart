import 'package:flutter/material.dart';

import '../../../../core/core.dart';

/// Pantalla de gestión de destinos de impresión
/// 
/// Permite crear, editar y eliminar destinos donde se envían los productos
class DestinosPage extends StatefulWidget {
  const DestinosPage({super.key});

  @override
  State<DestinosPage> createState() => _DestinosPageState();
}

class _DestinosPageState extends State<DestinosPage> {
  List<DestinoImpresion> _destinos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDestinos();
  }

  Future<void> _cargarDestinos() async {
    setState(() => _cargando = true);
    try {
      final db = DatabaseService.instance;
      _destinos = await db.obtenerDestinos();
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('DESTINOS DE IMPRESIÓN'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFF00D9A5)),
            onPressed: () => _mostrarDialogoDestino(),
            tooltip: 'Agregar destino',
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _destinos.isEmpty
              ? _buildEmptyState()
              : _buildListaDestinos(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.print_disabled,
            size: 80,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'No hay destinos configurados',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () => _mostrarDialogoDestino(),
            icon: const Icon(Icons.add),
            label: const Text('Agregar Destino'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D9A5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaDestinos() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _destinos.length,
      onReorder: _reordenarDestinos,
      itemBuilder: (context, index) {
        final destino = _destinos[index];
        return _DestinoCard(
          key: ValueKey(destino.id),
          destino: destino,
          onEdit: () => _mostrarDialogoDestino(destino: destino),
          onDelete: () => _confirmarEliminar(destino),
          onToggleActivo: () => _toggleActivo(destino),
        );
      },
    );
  }

  Future<void> _reordenarDestinos(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _destinos.removeAt(oldIndex);
      _destinos.insert(newIndex, item);
    });

    // Actualizar orden en la base de datos
    final db = DatabaseService.instance;
    for (int i = 0; i < _destinos.length; i++) {
      _destinos[i].orden = i;
      await db.guardarDestino(_destinos[i]);
    }
  }

  Future<void> _toggleActivo(DestinoImpresion destino) async {
    destino.activo = !destino.activo;
    await DatabaseService.instance.guardarDestino(destino);
    await _cargarDestinos();
  }

  Future<void> _confirmarEliminar(DestinoImpresion destino) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          '¿Eliminar destino?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Estás seguro de eliminar "${destino.nombre}"?\n\n'
          'Los productos asignados a este destino quedarán sin destino.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await DatabaseService.instance.eliminarDestino(destino.id!);
      await _cargarDestinos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Destino eliminado'),
            backgroundColor: Color(0xFFE94560),
          ),
        );
      }
    }
  }

  void _mostrarDialogoDestino({DestinoImpresion? destino}) {
    showDialog(
      context: context,
      builder: (context) => _DialogoDestino(
        destino: destino,
        onGuardar: (nuevoDestino) async {
          await DatabaseService.instance.guardarDestino(nuevoDestino);
          await _cargarDestinos();
        },
      ),
    );
  }
}

/// Card de destino individual
class _DestinoCard extends StatelessWidget {
  final DestinoImpresion destino;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActivo;

  const _DestinoCard({
    super.key,
    required this.destino,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActivo,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(destino.color);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF16213E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: destino.activo ? color.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: destino.activo ? color.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getIconData(destino.icono),
            color: destino.activo ? color : Colors.grey,
            size: 28,
          ),
        ),
        title: Row(
          children: [
            Text(
              destino.nombre,
              style: TextStyle(
                color: destino.activo ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 8),
            _TipoBadge(tipo: destino.tipo),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (destino.descripcion != null)
              Text(
                destino.descripcion!,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              ),
            if (destino.nombreImpresora != null)
              Text(
                '🖨️ ${destino.nombreImpresora}',
                style: const TextStyle(color: Color(0xFF00D9A5), fontSize: 12),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: destino.activo,
              onChanged: (_) => onToggleActivo(),
              activeTrackColor: const Color(0xFF00D9A5).withValues(alpha: 0.5),
              activeThumbColor: const Color(0xFF00D9A5),
            ),
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

/// Badge del tipo de destino
class _TipoBadge extends StatelessWidget {
  final TipoDestino tipo;

  const _TipoBadge({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  ({Color color, String label}) _getConfig() {
    switch (tipo) {
      case TipoDestino.pantalla:
        return (color: const Color(0xFF4FC3F7), label: 'PANTALLA');
      case TipoDestino.impresora:
        return (color: const Color(0xFFFFB74D), label: 'IMPRESORA');
      case TipoDestino.ambos:
        return (color: const Color(0xFF00D9A5), label: 'AMBOS');
    }
  }
}

/// Diálogo para crear/editar destino
class _DialogoDestino extends StatefulWidget {
  final DestinoImpresion? destino;
  final Future<void> Function(DestinoImpresion) onGuardar;

  const _DialogoDestino({
    this.destino,
    required this.onGuardar,
  });

  @override
  State<_DialogoDestino> createState() => _DialogoDestinoState();
}

class _DialogoDestinoState extends State<_DialogoDestino> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _impresoraController;
  late TextEditingController _direccionController;
  late TextEditingController _puertoController;

  String _iconoSeleccionado = 'restaurant';
  String _colorSeleccionado = '#E94560';
  TipoDestino _tipoSeleccionado = TipoDestino.pantalla;

  final List<String> _iconos = [
    'restaurant',
    'local_bar',
    'cake',
    'local_cafe',
    'local_pizza',
    'icecream',
    'print',
  ];

  final List<String> _colores = [
    '#E94560',
    '#00D9A5',
    '#4FC3F7',
    '#FFB74D',
    '#9C27B0',
    '#FF5722',
    '#8BC34A',
  ];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.destino?.nombre);
    _descripcionController = TextEditingController(text: widget.destino?.descripcion);
    _impresoraController = TextEditingController(text: widget.destino?.nombreImpresora);
    _direccionController = TextEditingController(text: widget.destino?.direccionImpresora);
    _puertoController = TextEditingController(
      text: widget.destino?.puertoImpresora != null
          ? widget.destino!.puertoImpresora.toString()
          : '',
    );

    if (widget.destino != null) {
      _iconoSeleccionado = widget.destino!.icono;
      _colorSeleccionado = widget.destino!.color;
      _tipoSeleccionado = widget.destino!.tipo;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _impresoraController.dispose();
    _direccionController.dispose();
    _puertoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF16213E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Text(
                  widget.destino == null ? 'NUEVO DESTINO' : 'EDITAR DESTINO',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Nombre
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    hintText: 'Ej: Cocina Principal',
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El nombre es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Descripción
                TextFormField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Ej: Platos principales y entrantes',
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 24),
                
                // Selector de icono
                const Text(
                  'Icono',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _iconos.map((icono) {
                    final isSelected = icono == _iconoSeleccionado;
                    return InkWell(
                      onTap: () => setState(() => _iconoSeleccionado = icono),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? const Color(0xFF00D9A5).withValues(alpha: 0.3) 
                              : const Color(0xFF0F3460),
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected 
                              ? Border.all(color: const Color(0xFF00D9A5), width: 2)
                              : null,
                        ),
                        child: Icon(
                          _getIconData(icono),
                          color: Colors.white,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                
                // Selector de color
                const Text(
                  'Color',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _colores.map((color) {
                    final isSelected = color == _colorSeleccionado;
                    return InkWell(
                      onTap: () => setState(() => _colorSeleccionado = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _parseColor(color),
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected 
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                        ),
                        child: isSelected 
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                
                // Tipo de destino
                const Text(
                  'Tipo de destino',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                SegmentedButton<TipoDestino>(
                  segments: const [
                    ButtonSegment(
                      value: TipoDestino.pantalla,
                      label: Text('Pantalla'),
                      icon: Icon(Icons.tv),
                    ),
                    ButtonSegment(
                      value: TipoDestino.impresora,
                      label: Text('Impresora'),
                      icon: Icon(Icons.print),
                    ),
                    ButtonSegment(
                      value: TipoDestino.ambos,
                      label: Text('Ambos'),
                      icon: Icon(Icons.devices),
                    ),
                  ],
                  selected: {_tipoSeleccionado},
                  onSelectionChanged: (selection) {
                    setState(() => _tipoSeleccionado = selection.first);
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return const Color(0xFF00D9A5);
                      }
                      return const Color(0xFF0F3460);
                    }),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Configuración de impresora (si aplica)
                if (_tipoSeleccionado != TipoDestino.pantalla) ...[
                  const Divider(color: Color(0xFF0F3460)),
                  const SizedBox(height: 16),
                  const Text(
                    'Configuración de Impresora',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _impresoraController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de impresora',
                      hintText: 'Ej: EPSON TM-T20',
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _direccionController,
                    decoration: const InputDecoration(
                      labelText: 'IP / Dirección (red)',
                      hintText: 'Ej: 192.168.1.100',
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _puertoController,
                    decoration: const InputDecoration(
                      labelText: 'Puerto (opcional)',
                      hintText: 'Vacío = por defecto. Ej: 9100',
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        final n = int.tryParse(v);
                        if (n == null || n < 1 || n > 65535) return 'Puerto inválido (1-65535)';
                      }
                      return null;
                    },
                  ),
                ],
                
                const SizedBox(height: 32),
                
                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D9A5),
                      ),
                      child: Text(widget.destino == null ? 'Crear' : 'Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (_formKey.currentState!.validate()) {
      final destino = widget.destino ?? DestinoImpresion();
      
      destino.nombre = _nombreController.text;
      destino.descripcion = _descripcionController.text.isEmpty 
          ? null 
          : _descripcionController.text;
      destino.icono = _iconoSeleccionado;
      destino.color = _colorSeleccionado;
      destino.tipo = _tipoSeleccionado;
      destino.nombreImpresora = _impresoraController.text.isEmpty 
          ? null 
          : _impresoraController.text;
      destino.direccionImpresora = _direccionController.text.isEmpty
          ? null
          : _direccionController.text;
      final puertoStr = _puertoController.text.trim();
      destino.puertoImpresora = puertoStr.isEmpty
          ? null
          : int.tryParse(puertoStr);

      if (widget.destino == null) {
        destino.activo = true;
        destino.orden = 999;
        destino.fechaCreacion = DateTime.now();
      }

      await widget.onGuardar(destino);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.destino == null 
                ? 'Destino creado' 
                : 'Destino actualizado'),
            backgroundColor: const Color(0xFF00D9A5),
          ),
        );
      }
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

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFFE94560);
    }
  }
}
