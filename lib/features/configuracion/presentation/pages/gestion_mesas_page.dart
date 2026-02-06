import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/core.dart';

/// Pantalla de gestión de mesas del restaurante
/// 
/// Permite ver, añadir, editar y eliminar mesas
class GestionMesasPage extends StatefulWidget {
  const GestionMesasPage({super.key});

  @override
  State<GestionMesasPage> createState() => _GestionMesasPageState();
}

class _GestionMesasPageState extends State<GestionMesasPage> {
  List<Mesa> _mesas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarMesas();
  }

  Future<void> _cargarMesas() async {
    setState(() => _cargando = true);
    try {
      _mesas = await DatabaseService.instance.obtenerMesas();
    } catch (e) {
      debugPrint('Error al cargar mesas: $e');
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
        title: const Row(
          children: [
            Icon(Icons.table_restaurant, color: Color(0xFF00D9A5)),
            SizedBox(width: 12),
            Text(
              'GESTIÓN DE MESAS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          // Botón añadir mesa
          IconButton(
            onPressed: _mostrarFormularioMesa,
            icon: const Icon(Icons.add_circle, color: Color(0xFF00D9A5)),
            tooltip: 'Añadir mesa',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D9A5)))
          : Column(
              children: [
                // Resumen de mesas
                _buildResumen(),
                
                // Grid de mesas
                Expanded(
                  child: _mesas.isEmpty
                      ? _buildSinMesas()
                      : _buildGridMesas(),
                ),
              ],
            ),
    );
  }

  Widget _buildResumen() {
    final libres = _mesas.where((m) => m.estado == EstadoMesa.libre).length;
    final ocupadas = _mesas.where((m) => m.estado == EstadoMesa.ocupada).length;
    final reservadas = _mesas.where((m) => m.estado == EstadoMesa.reservada).length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF16213E),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ResumenItem(
            label: 'Total',
            count: _mesas.length,
            color: Colors.white,
            icon: Icons.table_restaurant,
          ),
          _ResumenItem(
            label: 'Libres',
            count: libres,
            color: const Color(0xFF00D9A5),
            icon: Icons.check_circle,
          ),
          _ResumenItem(
            label: 'Ocupadas',
            count: ocupadas,
            color: const Color(0xFFE94560),
            icon: Icons.people,
          ),
          _ResumenItem(
            label: 'Reservadas',
            count: reservadas,
            color: const Color(0xFFFFB74D),
            icon: Icons.event_seat,
          ),
        ],
      ),
    );
  }

  Widget _buildSinMesas() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_restaurant_outlined,
            size: 100,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 20),
          const Text(
            'No hay mesas configuradas',
            style: TextStyle(color: Colors.white54, fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _mostrarFormularioMesa,
            icon: const Icon(Icons.add),
            label: const Text('Añadir primera mesa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D9A5),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridMesas() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _mesas.length,
      itemBuilder: (context, index) {
        final mesa = _mesas[index];
        return _MesaCard(
          mesa: mesa,
          onTap: () => _mostrarOpcionesMesa(mesa),
          onLongPress: () => _confirmarEliminar(mesa),
        );
      },
    );
  }

  void _mostrarFormularioMesa([Mesa? mesa]) {
    showDialog(
      context: context,
      builder: (context) => _MesaFormDialog(
        mesa: mesa,
        mesasExistentes: _mesas.map((m) => m.numero).toList(),
        onGuardar: () {
          Navigator.pop(context);
          _cargarMesas();
        },
      ),
    );
  }

  void _mostrarOpcionesMesa(Mesa mesa) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _MesaOptionsSheet(
        mesa: mesa,
        onEditar: () {
          Navigator.pop(context);
          _mostrarFormularioMesa(mesa);
        },
        onCambiarEstado: (estado) async {
          Navigator.pop(context);
          await DatabaseService.instance.actualizarEstadoMesa(mesa.numero, estado);
          _cargarMesas();
        },
        onEliminar: () {
          Navigator.pop(context);
          _confirmarEliminar(mesa);
        },
      ),
    );
  }

  void _confirmarEliminar(Mesa mesa) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 12),
            Text(
              '¿Eliminar Mesa ${mesa.numero}?',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Esta acción eliminará la mesa y no se puede deshacer.\n\n'
          'Los pedidos asociados a esta mesa permanecerán en el historial.',
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
              if (mesa.id != null) {
                await DatabaseService.instance.isar.writeTxn(() => 
                  DatabaseService.instance.isar.mesas.delete(mesa.id!));
                _cargarMesas();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Mesa ${mesa.numero} eliminada'),
                      backgroundColor: const Color(0xFFE94560),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

/// Widget de resumen de estadísticas
class _ResumenItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _ResumenItem({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
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
    );
  }
}

/// Tarjeta visual de mesa
class _MesaCard extends StatelessWidget {
  final Mesa mesa;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _MesaCard({
    required this.mesa,
    required this.onTap,
    required this.onLongPress,
  });

  Color get _colorEstado {
    switch (mesa.estado) {
      case EstadoMesa.libre:
        return const Color(0xFF00D9A5);
      case EstadoMesa.ocupada:
        return const Color(0xFFE94560);
      case EstadoMesa.reservada:
        return const Color(0xFFFFB74D);
      case EstadoMesa.enLimpieza:
        return Colors.grey;
    }
  }

  IconData get _iconEstado {
    switch (mesa.estado) {
      case EstadoMesa.libre:
        return Icons.check_circle;
      case EstadoMesa.ocupada:
        return Icons.people;
      case EstadoMesa.reservada:
        return Icons.event_seat;
      case EstadoMesa.enLimpieza:
        return Icons.cleaning_services;
    }
  }

  String get _textoEstado {
    switch (mesa.estado) {
      case EstadoMesa.libre:
        return 'LIBRE';
      case EstadoMesa.ocupada:
        return 'OCUPADA';
      case EstadoMesa.reservada:
        return 'RESERVADA';
      case EstadoMesa.enLimpieza:
        return 'EN LIMPIEZA';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF16213E),
                _colorEstado.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _colorEstado,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _colorEstado.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: mesa.estado == EstadoMesa.ocupada ? 2 : 0,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Número de mesa grande
              Text(
                '${mesa.numero}',
                style: TextStyle(
                  color: _colorEstado,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Estado con icono
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_iconEstado, color: _colorEstado, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _textoEstado,
                    style: TextStyle(
                      color: _colorEstado,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Info adicional
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, color: Colors.white38, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${mesa.capacidad}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  if (mesa.ubicacion != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.place, color: Colors.white38, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        mesa.ubicacion!,
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet con opciones de mesa
class _MesaOptionsSheet extends StatelessWidget {
  final Mesa mesa;
  final VoidCallback onEditar;
  final Function(EstadoMesa) onCambiarEstado;
  final VoidCallback onEliminar;

  const _MesaOptionsSheet({
    required this.mesa,
    required this.onEditar,
    required this.onCambiarEstado,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          // Título
          Text(
            'Mesa ${mesa.numero}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Cambiar estado
          const Text(
            'CAMBIAR ESTADO',
            style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _EstadoButton(
                label: 'Libre',
                icon: Icons.check_circle,
                color: const Color(0xFF00D9A5),
                isSelected: mesa.estado == EstadoMesa.libre,
                onTap: () => onCambiarEstado(EstadoMesa.libre),
              ),
              _EstadoButton(
                label: 'Ocupada',
                icon: Icons.people,
                color: const Color(0xFFE94560),
                isSelected: mesa.estado == EstadoMesa.ocupada,
                onTap: () => onCambiarEstado(EstadoMesa.ocupada),
              ),
              _EstadoButton(
                label: 'Reservada',
                icon: Icons.event_seat,
                color: const Color(0xFFFFB74D),
                isSelected: mesa.estado == EstadoMesa.reservada,
                onTap: () => onCambiarEstado(EstadoMesa.reservada),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          
          // Acciones
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEditar,
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEliminar,
                  icon: const Icon(Icons.delete),
                  label: const Text('Eliminar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// Botón de estado en el bottom sheet
class _EstadoButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _EstadoButton({
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
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.white24,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.white54, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.white54,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Diálogo para crear/editar mesa
class _MesaFormDialog extends StatefulWidget {
  final Mesa? mesa;
  final List<int> mesasExistentes;
  final VoidCallback onGuardar;

  const _MesaFormDialog({
    this.mesa,
    required this.mesasExistentes,
    required this.onGuardar,
  });

  @override
  State<_MesaFormDialog> createState() => _MesaFormDialogState();
}

class _MesaFormDialogState extends State<_MesaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _numeroController;
  late TextEditingController _capacidadController;
  late TextEditingController _ubicacionController;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _numeroController = TextEditingController(
      text: widget.mesa?.numero.toString() ?? '',
    );
    _capacidadController = TextEditingController(
      text: widget.mesa?.capacidad.toString() ?? '4',
    );
    _ubicacionController = TextEditingController(
      text: widget.mesa?.ubicacion ?? '',
    );
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _capacidadController.dispose();
    _ubicacionController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final mesa = widget.mesa ?? Mesa();
      mesa.numero = int.parse(_numeroController.text);
      mesa.capacidad = int.tryParse(_capacidadController.text) ?? 4;
      mesa.ubicacion = _ubicacionController.text.isEmpty ? null : _ubicacionController.text;
      mesa.estado = widget.mesa?.estado ?? EstadoMesa.libre;
      mesa.ultimaActualizacion = DateTime.now();

      await DatabaseService.instance.guardarMesa(mesa);
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
    final esNueva = widget.mesa == null;
    
    return Dialog(
      backgroundColor: const Color(0xFF16213E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    esNueva ? Icons.add_circle : Icons.edit,
                    color: const Color(0xFF00D9A5),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    esNueva ? 'NUEVA MESA' : 'EDITAR MESA',
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
              const SizedBox(height: 24),
              
              // Número de mesa
              TextFormField(
                controller: _numeroController,
                style: const TextStyle(color: Colors.white, fontSize: 24),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                enabled: esNueva, // No editable si ya existe
                decoration: InputDecoration(
                  labelText: 'Número de mesa',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF0F3460),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00D9A5), width: 2),
                  ),
                ),
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Requerido';
                  final numero = int.tryParse(v!);
                  if (numero == null || numero <= 0) return 'Número inválido';
                  if (esNueva && widget.mesasExistentes.contains(numero)) {
                    return 'Este número ya existe';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Capacidad y ubicación
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _capacidadController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Capacidad',
                        labelStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.people, color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF0F3460),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _ubicacionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Ubicación',
                        labelStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.place, color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF0F3460),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Botones
              Row(
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
            ],
          ),
        ),
      ),
    );
  }
}
