import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../../../../core/utils/platform_utils.dart';
import '../providers/reservas_provider.dart';

/// Pantalla de reservas pendientes y alta manual.
class ReservasPage extends StatefulWidget {
  const ReservasPage({super.key});

  @override
  State<ReservasPage> createState() => _ReservasPageState();
}

class _ReservasPageState extends State<ReservasPage> {
  final _nombreCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  final _buscarProductoCtrl = TextEditingController();

  int _personas = 2;
  DateTime _fechaHora = DateTime.now().add(const Duration(hours: 2));
  final Map<int, int> _cantidadesProducto = {};
  Reserva? _reservaSeleccionada;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservasProvider>().inicializar();
    });
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _notasCtrl.dispose();
    _buscarProductoCtrl.dispose();
    super.dispose();
  }

  List<ItemReserva> _itemsDesdeFormulario(List<Producto> productos) {
    final items = <ItemReserva>[];
    for (final entry in _cantidadesProducto.entries) {
      if (entry.value <= 0) continue;
      final p = productos.where((x) => x.id == entry.key).firstOrNull;
      if (p == null) continue;
      items.add(
        ItemReserva.crear(
          productoId: p.id ?? 0,
          nombreProducto: p.nombre,
          cantidad: entry.value,
          precioUnitario: p.precio,
        ),
      );
    }
    return items;
  }

  void _limpiarFormulario() {
    _nombreCtrl.clear();
    _notasCtrl.clear();
    _personas = 2;
    _fechaHora = DateTime.now().add(const Duration(hours: 2));
    _cantidadesProducto.clear();
    _reservaSeleccionada = null;
  }

  Future<void> _elegirFechaHora() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaHora,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00D9A5),
            surface: Color(0xFF16213E),
          ),
        ),
        child: child!,
      ),
    );
    if (fecha == null || !mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_fechaHora),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00D9A5),
            surface: Color(0xFF16213E),
          ),
        ),
        child: child!,
      ),
    );
    if (hora == null || !mounted) return;
    setState(() {
      _fechaHora = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        hora.hour,
        hora.minute,
      );
    });
  }

  Future<void> _guardarReserva(ReservasProvider provider) async {
    if (_nombreCtrl.text.trim().isEmpty) {
      _snack('Indique el nombre del cliente', Colors.orange);
      return;
    }
    setState(() => _guardando = true);
    try {
      final resultado = await provider.crearReserva(
        nombreCliente: _nombreCtrl.text,
        numeroPersonas: _personas,
        fechaHoraLlegada: _fechaHora,
        alergiasNotas: _notasCtrl.text,
        itemsReservados: _itemsDesdeFormulario(provider.productos),
      );
      if (mounted) {
        _limpiarFormulario();
        setState(() {});
        if (resultado == CrearReservaResultado.guardadaParaEnvio) {
          _snack(
            'Reserva guardada en el teléfono. Se enviará al VPS cuando haya conexión.',
            const Color(0xFFFFB74D),
          );
        } else {
          _snack('Reserva creada', const Color(0xFF00D9A5));
        }
      }
    } catch (e) {
      _snack('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _asignarMesa(ReservasProvider provider, Reserva reserva) async {
    final mesa = await showDialog<int>(
      context: context,
      builder: (ctx) => _DialogoSelectorMesa(mesas: provider.mesas),
    );
    if (mesa == null || !mounted) return;

    try {
      await provider.asignarMesa(reserva: reserva, mesaNumero: mesa);
      if (_reservaSeleccionada?.id == reserva.id) {
        _reservaSeleccionada = null;
      }
      if (mounted) {
        setState(() {});
        _snack('Mesa $mesa asignada a ${reserva.nombreCliente}', const Color(0xFF00D9A5));
      }
    } catch (e) {
      _snack('Error al asignar mesa: $e', Colors.red);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  String _formatoFechaHora(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReservasProvider>(
      builder: (context, provider, _) {
        final ancho = MediaQuery.of(context).size.width;
        final esAncho = ancho > 900;

        return Scaffold(
          backgroundColor: const Color(0xFF1A1A2E),
          appBar: AppBar(
            backgroundColor: const Color(0xFF16213E),
            title: const Text('Reservas'),
            actions: [
              if (provider.modoBackup && !PlatformUtils.isAndroid)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Chip(
                    label: Text('Modo offline', style: TextStyle(fontSize: 11)),
                    backgroundColor: Color(0xFFFFB74D),
                  ),
                ),
              if (provider.colaEnvioCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    avatar: const Icon(Icons.cloud_upload, size: 16, color: Colors.black87),
                    label: Text(
                      'Por enviar (${provider.colaEnvioCount})',
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: const Color(0xFFFFB74D),
                  ),
                ),
              IconButton(
                onPressed: provider.sincronizando ? null : provider.sincronizar,
                icon: provider.sincronizando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                tooltip: PlatformUtils.isAndroid
                    ? 'Actualizar carta y reservas desde VPS'
                    : 'Subir catálogo y sincronizar reservas con VPS',
              ),
            ],
          ),
          body: provider.cargando
              ? const Center(child: CircularProgressIndicator())
              : esAncho
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 4,
                          child: _panelListasReservas(provider, esMovil: false),
                        ),
                        const VerticalDivider(width: 1, color: Color(0xFF0F3460)),
                        Expanded(flex: 6, child: _formularioNueva(provider)),
                      ],
                    )
                  : Column(
                      children: [
                        _panelListasReservas(provider, esMovil: true),
                        const Divider(height: 1, color: Color(0xFF0F3460)),
                        Expanded(child: _formularioNueva(provider)),
                      ],
                    ),
        );
      },
    );
  }

  Widget _panelListasReservas(ReservasProvider provider, {required bool esMovil}) {
    final porEnviar = provider.pendientesPorEnviar;
    final enServidor = provider.reservasEnServidor;
    final enCaja = provider.pendientesCaja;
    final maxLista = esMovil ? 220.0 : double.infinity;

    Widget panel = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: esMovil ? MainAxisSize.min : MainAxisSize.max,
      children: [
        if (provider.error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Text(
              provider.error!,
              style: TextStyle(color: Colors.orange.shade300, fontSize: 12),
            ),
          ),
        _seccionReservas(
          titulo: 'Pendientes por enviar',
          subtitulo: PlatformUtils.isAndroid
              ? 'Guardadas en el teléfono sin conexión'
              : 'Cola local hacia el VPS',
          icono: Icons.cloud_upload_outlined,
          cantidad: provider.colaEnvioCount,
          lista: porEnviar,
          provider: provider,
          maxAlturaLista: maxLista,
          vacio: 'No hay reservas pendientes de envío',
          mostrarEtiquetaPorEnviar: true,
          permitirAsignarMesa: false,
        ),
        if (!PlatformUtils.isAndroid)
          _seccionReservas(
            titulo: 'Pendientes en caja',
            subtitulo: 'Base de datos local',
            icono: Icons.storefront_outlined,
            cantidad: enCaja.length,
            lista: enCaja,
            provider: provider,
            maxAlturaLista: maxLista,
            vacio: 'No hay reservas pendientes en la caja',
            mostrarEtiquetaPorEnviar: false,
            permitirAsignarMesa: true,
          ),
        _seccionReservas(
          titulo: 'En el servidor',
          subtitulo: 'Reservas ya enviadas al VPS',
          icono: Icons.cloud_done_outlined,
          cantidad: provider.reservasEnServidorCount,
          lista: enServidor,
          provider: provider,
          maxAlturaLista: maxLista,
          vacio: 'No hay reservas en el servidor (pulsa sync)',
          mostrarEtiquetaPorEnviar: false,
          permitirAsignarMesa: false,
        ),
      ],
    );

    if (esMovil) return panel;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: panel,
    );
  }

  Widget _seccionReservas({
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required int cantidad,
    required List<Reserva> lista,
    required ReservasProvider provider,
    required double maxAlturaLista,
    required String vacio,
    required bool mostrarEtiquetaPorEnviar,
    required bool permitirAsignarMesa,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: const Color(0xFF0F3460),
        splashColor: const Color(0xFF0F3460),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        collapsedBackgroundColor: const Color(0xFF16213E),
        backgroundColor: const Color(0xFF16213E),
        iconColor: const Color(0xFF00D9A5),
        collapsedIconColor: Colors.white54,
        title: Row(
          children: [
            Icon(icono, color: const Color(0xFF00D9A5), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$titulo ($cantidad)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitulo,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        children: [
          if (lista.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(vacio, style: const TextStyle(color: Colors.white54)),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: maxAlturaLista == double.infinity ? 400 : maxAlturaLista,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: lista.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _tarjetaReserva(
                  provider: provider,
                  reserva: lista[index],
                  mostrarEtiquetaPorEnviar: mostrarEtiquetaPorEnviar,
                  permitirAsignarMesa: permitirAsignarMesa,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tarjetaReserva({
    required ReservasProvider provider,
    required Reserva reserva,
    required bool mostrarEtiquetaPorEnviar,
    required bool permitirAsignarMesa,
  }) {
    final sel = _reservaSeleccionada?.id == reserva.id;
    final mostrarPorEnviar =
        mostrarEtiquetaPorEnviar && provider.pendienteDeEnvio(reserva);

    return Material(
      color: sel ? const Color(0xFF0F3460) : const Color(0xFF1A1A2E),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => setState(() => _reservaSeleccionada = reserva),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      reserva.nombreCliente,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (mostrarPorEnviar)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB74D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Por enviar',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Text(
                    _formatoFechaHora(reserva.fechaHoraLlegada),
                    style: const TextStyle(
                      color: Color(0xFF00D9A5),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${reserva.numeroPersonas} personas · '
                '${reserva.itemsReservados.length} plato(s) pre-reservado(s)',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              if (reserva.alergiasNotas.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  reserva.alergiasNotas,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.orange.shade200, fontSize: 12),
                ),
              ],
              if (permitirAsignarMesa) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () => _asignarMesa(provider, reserva),
                    icon: const Icon(Icons.table_restaurant, size: 18),
                    label: const Text('Asignar mesa'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00D9A5),
                      foregroundColor: Colors.black87,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _formularioNueva(ReservasProvider provider) {
    final filtro = _buscarProductoCtrl.text.toLowerCase();
    final productosFiltrados = provider.productos
        .where((p) => p.isAvailable && p.nombre.toLowerCase().contains(filtro))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            PlatformUtils.isAndroid
                ? 'Nueva reserva (envío al VPS)'
                : 'Nueva reserva manual',
            style: const TextStyle(
              color: Color(0xFF00D9A5),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _nombreCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: _decoration('Nombre del cliente'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Personas: $_personas',
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
              IconButton.filled(
                onPressed: () => setState(
                  () => _personas = (_personas - 1).clamp(1, 99),
                ),
                icon: const Icon(Icons.remove),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFE94560),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () => setState(() => _personas++),
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF00D9A5),
                  foregroundColor: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _elegirFechaHora,
            icon: const Icon(Icons.schedule, color: Color(0xFF00D9A5)),
            label: Text(
              'Llegada: ${_formatoFechaHora(_fechaHora)}',
              style: const TextStyle(color: Colors.white),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF0F3460)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notasCtrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: _decoration(
              'Alergias / notas (celíaco, trona, etc.)',
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Platos con preparación anticipada',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _buscarProductoCtrl,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white),
            decoration: _decoration('Buscar producto...'),
          ),
          const SizedBox(height: 8),
          ...productosFiltrados.take(12).map((p) {
            final id = p.id ?? 0;
            final qty = _cantidadesProducto[id] ?? 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0F3460),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      p.nombre,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  Text(
                    '€${p.precio.toStringAsFixed(2)}',
                    style: const TextStyle(color: Color(0xFF00D9A5), fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: qty > 0
                        ? () => setState(() {
                              if (qty <= 1) {
                                _cantidadesProducto.remove(id);
                              } else {
                                _cantidadesProducto[id] = qty - 1;
                              }
                            })
                        : null,
                    icon: const Icon(Icons.remove_circle_outline, size: 22),
                    color: const Color(0xFFE94560),
                  ),
                  Text('$qty', style: const TextStyle(color: Colors.white)),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() {
                      _cantidadesProducto[id] = qty + 1;
                    }),
                    icon: const Icon(Icons.add_circle_outline, size: 22),
                    color: const Color(0xFF00D9A5),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _guardando ? null : () => _guardarReserva(provider),
            icon: _guardando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_guardando ? 'Guardando…' : 'Guardar reserva'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00D9A5),
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF0F3460),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF16213E)),
        ),
      );
}

class _DialogoSelectorMesa extends StatelessWidget {
  final List<Mesa> mesas;

  const _DialogoSelectorMesa({required this.mesas});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF16213E),
      title: const Text(
        'Asignar mesa',
        style: TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 420,
        child: mesas.isEmpty
            ? const Text(
                'No hay mesas configuradas',
                style: TextStyle(color: Colors.white70),
              )
            : GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.2,
                ),
                itemCount: mesas.length,
                itemBuilder: (context, index) {
                  final mesa = mesas[index];
                  final ocupada = mesa.estado == EstadoMesa.ocupada;
                  return Material(
                    color: ocupada
                        ? const Color(0xFF3D2C2C)
                        : const Color(0xFF0F3460),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: ocupada
                          ? null
                          : () => Navigator.of(context).pop(mesa.numero),
                      borderRadius: BorderRadius.circular(10),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${mesa.numero}',
                              style: TextStyle(
                                color: ocupada ? Colors.white38 : Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              ocupada ? 'Ocupada' : 'Libre',
                              style: TextStyle(
                                color: ocupada
                                    ? Colors.red.shade300
                                    : const Color(0xFF00D9A5),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
