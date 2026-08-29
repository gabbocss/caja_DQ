import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../../../../core/utils/platform_utils.dart';
import '../../domain/franja_reserva.dart';
import '../providers/reservas_provider.dart';

/// Flujo de la pantalla Reservas en Android (menú → nueva / editar).
enum _VistaAndroidReservas { menu, nueva, editar }

/// Pantalla de reservas pendientes y alta manual.
class ReservasPage extends StatefulWidget {
  const ReservasPage({super.key});

  @override
  State<ReservasPage> createState() => _ReservasPageState();
}

class _ReservasPageState extends State<ReservasPage>
    with SingleTickerProviderStateMixin {
  final _nombreCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  final _buscarProductoCtrl = TextEditingController();

  int _personas = 2;
  DateTime _fechaHora = DateTime.now().add(const Duration(hours: 2));
  final Map<int, int> _cantidadesProducto = {};
  Reserva? _reservaSeleccionada;
  int? _reservaEditandoId;
  bool _guardando = false;
  ReservasProvider? _provider;
  _VistaAndroidReservas _vistaAndroid = _VistaAndroidReservas.menu;

  FranjaReserva _franjaActiva = FranjaReserva.comida;
  HorariosReservas _horarios = HorariosReservas.defaults;
  late final AnimationController _asportoBlinkCtrl;

  /// Proporción del panel agenda (0–1) en layout horizontal escritorio.
  double _ratioAgendaHorizontal = 0.6;

  /// Proporción del panel agenda (0–1) en layout vertical escritorio.
  double _ratioAgendaVertical = 0.55;

  static const double _ratioMin = 0.28;
  static const double _ratioMax = 0.78;
  static const double _grosorDivisor = 6;

  static final _formatoHora = DateFormat('HH:mm');
  bool _localeEsListo = false;

  String _tituloDiaAgenda(DateTime dia) {
    if (!_localeEsListo) {
      return DateFormat('EEEE, d MMMM y').format(dia);
    }
    final t = DateFormat('EEEE, d MMMM y', 'es').format(dia);
    if (t.isEmpty) return t;
    return '${t[0].toUpperCase()}${t.substring(1)}';
  }

  @override
  void initState() {
    super.initState();
    _asportoBlinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    unawaited(
      initializeDateFormatting('es', null).then((_) {
        if (mounted) setState(() => _localeEsListo = true);
      }),
    );
    unawaited(_cargarHorarios());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider = context.read<ReservasProvider>();
      _provider!.inicializar();
    });
  }

  Future<void> _cargarHorarios() async {
    final h = await getHorariosReservas();
    if (!mounted) return;
    setState(() => _horarios = h);
  }

  @override
  void dispose() {
    _asportoBlinkCtrl.dispose();
    _provider?.desmontar();
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
    _reservaEditandoId = null;
  }

  void _cargarReservaEnFormulario(Reserva reserva) {
    _reservaEditandoId = reserva.id;
    _reservaSeleccionada = reserva;
    _nombreCtrl.text = reserva.nombreCliente;
    _notasCtrl.text = reserva.alergiasNotas;
    _personas = reserva.numeroPersonas;
    _fechaHora = reserva.fechaHoraLlegada;
    _cantidadesProducto.clear();
    for (final item in reserva.itemsReservados) {
      _cantidadesProducto[item.productoId] = item.cantidad;
    }
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
      final items = _itemsDesdeFormulario(provider.productos);
      if (_reservaEditandoId != null) {
        await provider.actualizarReserva(
          id: _reservaEditandoId!,
          nombreCliente: _nombreCtrl.text,
          numeroPersonas: _personas,
          fechaHoraLlegada: _fechaHora,
          alergiasNotas: _notasCtrl.text,
          itemsReservados: items,
        );
        if (mounted) {
          _limpiarFormulario();
          setState(() {});
          _snack('Reserva actualizada', const Color(0xFF00D9A5));
        }
      } else {
        final resultado = await provider.crearReserva(
          nombreCliente: _nombreCtrl.text,
          numeroPersonas: _personas,
          fechaHoraLlegada: _fechaHora,
          alergiasNotas: _notasCtrl.text,
          itemsReservados: items,
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
      }
    } catch (e) {
      _snack('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _volverMenuAndroid() {
    _limpiarFormulario();
    setState(() => _vistaAndroid = _VistaAndroidReservas.menu);
  }

  String get _tituloAppBar {
    if (!PlatformUtils.isAndroid) return 'Reservas';
    switch (_vistaAndroid) {
      case _VistaAndroidReservas.menu:
        return 'Reservas';
      case _VistaAndroidReservas.nueva:
        return 'Nueva reserva';
      case _VistaAndroidReservas.editar:
        return 'Editar reserva';
    }
  }

  Future<void> _elegirDiaAgenda(ReservasProvider provider) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: provider.diaAgenda,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 730)),
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
    await provider.establecerDiaAgenda(fecha);
  }

  Future<void> _confirmarEliminarReserva(
    ReservasProvider provider,
    Reserva reserva,
  ) async {
    if (reserva.id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Cancelar reserva', style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Cancelar la reserva de ${reserva.nombreCliente}? '
          'Pasará a la pestaña canceladas.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE94560)),
            child: const Text('Cancelar reserva'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await provider.eliminarReserva(reserva.id!);
      if (_reservaEditandoId == reserva.id) {
        _limpiarFormulario();
      }
      if (mounted) {
        setState(() {});
        _snack('Reserva cancelada', const Color(0xFF00D9A5));
      }
    } catch (e) {
      _snack('Error al cancelar: $e', Colors.red);
    }
  }

  Future<void> _reactivarReserva(
    ReservasProvider provider,
    Reserva reserva,
  ) async {
    if (reserva.id == null) return;
    try {
      await provider.reactivarReserva(reserva.id!);
      if (_reservaEditandoId == reserva.id) {
        _limpiarFormulario();
      }
      if (mounted) {
        setState(() {});
        _snack(
          'Reserva reactivada: ${reserva.nombreCliente}',
          const Color(0xFF00D9A5),
        );
      }
    } catch (e) {
      _snack('Error al reactivar: $e', Colors.red);
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

  Future<void> _imprimirAsporto(Reserva reserva) async {
    if (reserva.itemsReservados.isEmpty) {
      _snack('No hay productos para imprimir', Colors.orange);
      return;
    }
    try {
      await ImprimirPedidoService.instance.imprimirTicketReservaCocina(
        mesaNumero: 0,
        reserva: reserva,
        etiquetaCabecera: 'ASPORTO',
      );
      if (mounted) {
        _snack('Ticket asporto enviado a cocina', const Color(0xFF00D9A5));
      }
    } catch (e) {
      _snack('Error al imprimir: $e', Colors.red);
    }
  }

  Future<void> _cobrarAsporto(
    ReservasProvider provider,
    Reserva reserva,
  ) async {
    if (reserva.itemsReservados.isEmpty) {
      _snack('No hay productos para cobrar', Colors.orange);
      return;
    }
    final total = reserva.totalItemsReservados;
    if (total <= 0) {
      _snack('El total es 0; revisa los precios', Colors.orange);
      return;
    }

    final resultado = await showDialog<_ResultadoCobroAsporto>(
      context: context,
      builder: (ctx) => _DialogoCobroAsporto(
        nombreCliente: reserva.nombreCliente,
        total: total,
      ),
    );
    if (resultado == null || !mounted) return;

    try {
      await provider.cobrarAsporto(
        reserva: reserva,
        metodo: resultado.metodo,
        importeRecibido: resultado.importeRecibido,
      );
      if (_reservaEditandoId == reserva.id) {
        _limpiarFormulario();
      }
      if (mounted) {
        setState(() {});
        _snack(
          'Asporto cobrado: €${total.toStringAsFixed(2)} (${resultado.metodo})',
          const Color(0xFF00D9A5),
        );
      }
    } catch (e) {
      _snack('Error al cobrar: $e', Colors.red);
    }
  }

  Future<void> _abrirConfigHorarios() async {
    final actualizado = await showDialog<HorariosReservas>(
      context: context,
      builder: (ctx) => _DialogoHorariosReservas(inicial: _horarios),
    );
    if (actualizado == null || !mounted) return;
    await saveHorariosReservas(actualizado);
    setState(() => _horarios = actualizado);
  }

  List<Reserva> _filtrarPorFranja(List<Reserva> lista) {
    return lista
        .where((r) => clasificarReserva(r, _horarios) == _franjaActiva)
        .toList();
  }

  String _textoCubiertos(Reserva reserva) {
    if (reserva.numeroPersonas <= 0) {
      final total = reserva.totalItemsReservados;
      return 'Asporto · ${reserva.itemsReservados.length} plato(s)'
          '${total > 0 ? ' · €${total.toStringAsFixed(2)}' : ''}';
    }
    return '${reserva.numeroPersonas} personas · '
        '${reserva.itemsReservados.length} plato(s)';
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
        final enSubvistaAndroid = PlatformUtils.isAndroid &&
            _vistaAndroid != _VistaAndroidReservas.menu;

        return Scaffold(
          backgroundColor: const Color(0xFF1A1A2E),
          appBar: AppBar(
            backgroundColor: const Color(0xFF16213E),
            title: Text(_tituloAppBar),
            leading: enSubvistaAndroid
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      if (_vistaAndroid == _VistaAndroidReservas.editar &&
                          _reservaEditandoId != null) {
                        setState(_limpiarFormulario);
                      } else {
                        _volverMenuAndroid();
                      }
                    },
                    tooltip: 'Volver',
                  )
                : null,
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
              if (!PlatformUtils.isAndroid ||
                  _vistaAndroid != _VistaAndroidReservas.menu)
                IconButton(
                  onPressed: _abrirConfigHorarios,
                  icon: const Icon(Icons.settings),
                  tooltip: 'Configurar horarios comida / cena',
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
                    ? 'Actualizar carta, reservas del VPS y reenviar pendientes'
                    : 'Subir catálogo y sincronizar reservas con VPS',
              ),
            ],
          ),
          body: provider.cargando
              ? const Center(child: CircularProgressIndicator())
              : PlatformUtils.isAndroid
                  ? _cuerpoAndroid(provider, esAncho: esAncho)
                  : (esAncho
                      ? _layoutEscritorioHorizontal(provider)
                      : _layoutEscritorioVertical(provider)),
        );
      },
    );
  }

  Widget _cuerpoAndroid(ReservasProvider provider, {required bool esAncho}) {
    switch (_vistaAndroid) {
      case _VistaAndroidReservas.menu:
        return _menuAndroidReservas(provider);
      case _VistaAndroidReservas.nueva:
        return esAncho
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 4,
                    child: _panelListasReservas(provider, esMovil: false),
                  ),
                  const VerticalDivider(
                    width: 1,
                    color: Color(0xFF0F3460),
                  ),
                  Expanded(flex: 6, child: _formularioNueva(provider)),
                ],
              )
            : Column(
                children: [
                  _panelListasReservas(provider, esMovil: true),
                  const Divider(height: 1, color: Color(0xFF0F3460)),
                  Expanded(child: _formularioNueva(provider)),
                ],
              );
      case _VistaAndroidReservas.editar:
        if (_reservaEditandoId != null) {
          return _formularioNueva(provider);
        }
        return _panelEditarReservasAndroid(provider);
    }
  }

  Widget _menuAndroidReservas(ReservasProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (provider.error != null) ...[
            Text(
              provider.error!,
              style: TextStyle(color: Colors.orange.shade300, fontSize: 13),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            '¿Qué quieres hacer?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las reservas se envían al servidor y llegan a la caja.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 28),
          _tarjetaMenuAndroid(
            icono: Icons.add_circle_outline,
            titulo: 'Nueva reserva',
            subtitulo: 'Crear y enviar una reserva al VPS',
            onTap: () {
              _limpiarFormulario();
              setState(() => _vistaAndroid = _VistaAndroidReservas.nueva);
            },
          ),
          const SizedBox(height: 16),
          _tarjetaMenuAndroid(
            icono: Icons.edit_calendar_outlined,
            titulo: 'Editar reserva',
            subtitulo: provider.reservasEnServidorCount > 0
                ? '${provider.reservasEnServidorCount} pendiente(s) en el servidor'
                : 'Ver y modificar reservas del VPS (también las de la caja)',
            onTap: () async {
              _limpiarFormulario();
              setState(() => _vistaAndroid = _VistaAndroidReservas.editar);
              await provider.sincronizar();
            },
          ),
          if (provider.colaEnvioCount > 0) ...[
            const SizedBox(height: 24),
            Text(
              '${provider.colaEnvioCount} reserva(s) guardadas sin conexión. '
              'Pulsa sync para enviarlas.',
              style: const TextStyle(color: Color(0xFFFFB74D), fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tarjetaMenuAndroid({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF16213E),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF00D9A5).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icono, color: const Color(0xFF00D9A5), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitulo,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }

  Widget _panelEditarReservasAndroid(ReservasProvider provider) {
    final enServidor = provider.reservasEnServidor;
    final porEnviar = provider.pendientesPorEnviar;

    return RefreshIndicator(
      color: const Color(0xFF00D9A5),
      onRefresh: provider.sincronizar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (provider.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                provider.error!,
                style: TextStyle(color: Colors.orange.shade300, fontSize: 12),
              ),
            ),
          const Text(
            'Toca una reserva para editarla. Incluye las ya descargadas '
            'en la caja de escritorio.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (porEnviar.isNotEmpty) ...[
            Text(
              'Pendientes por enviar (${porEnviar.length})',
              style: const TextStyle(
                color: Color(0xFFFFB74D),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Estas aún no están en el servidor: pulsa sync para enviarlas. '
              'No se pueden editar hasta entonces.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 8),
            for (final r in porEnviar) ...[
              _tarjetaReserva(
                provider: provider,
                reserva: r,
                mostrarEtiquetaPorEnviar: true,
                permitirAsignarMesa: false,
                permitirEditar: false,
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 12),
          ],
          Text(
            'Pendientes (${enServidor.length})',
            style: const TextStyle(
              color: Color(0xFF00D9A5),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          if (enServidor.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No hay reservas pendientes.\n'
                'Pulsa sync o crea una nueva reserva.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
            )
          else
            for (final r in enServidor) ...[
              _tarjetaReserva(
                provider: provider,
                reserva: r,
                mostrarEtiquetaPorEnviar: false,
                permitirAsignarMesa: false,
                permitirEditar: true,
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  /// Agenda | divisor arrastrable | formulario (ancho).
  Widget _layoutEscritorioHorizontal(ReservasProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final total = constraints.maxWidth;
        final agendaW =
            ((total - _grosorDivisor) * _ratioAgendaHorizontal)
                .clamp(160.0, total - _grosorDivisor - 160);
        final formW = total - _grosorDivisor - agendaW;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: agendaW,
              child: _panelAgendaCaja(provider),
            ),
            _divisorHorizontalArrastrable(
              onDrag: (dx) {
                setState(() {
                  _ratioAgendaHorizontal = (_ratioAgendaHorizontal +
                          dx / (total - _grosorDivisor))
                      .clamp(_ratioMin, _ratioMax);
                });
              },
            ),
            SizedBox(
              width: formW,
              child: _formularioNueva(provider),
            ),
          ],
        );
      },
    );
  }

  /// Agenda / divisor arrastrable / formulario (alto, pantallas estrechas).
  Widget _layoutEscritorioVertical(ReservasProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final total = constraints.maxHeight;
        final agendaH =
            ((total - _grosorDivisor) * _ratioAgendaVertical)
                .clamp(120.0, total - _grosorDivisor - 120);
        final formH = total - _grosorDivisor - agendaH;
        return Column(
          children: [
            SizedBox(
              height: agendaH,
              child: _panelAgendaCaja(provider),
            ),
            _divisorVerticalArrastrable(
              onDrag: (dy) {
                setState(() {
                  _ratioAgendaVertical = (_ratioAgendaVertical +
                          dy / (total - _grosorDivisor))
                      .clamp(_ratioMin, _ratioMax);
                });
              },
            ),
            SizedBox(
              height: formH,
              child: _formularioNueva(provider),
            ),
          ],
        );
      },
    );
  }

  Widget _divisorHorizontalArrastrable({
    required void Function(double dx) onDrag,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (d) => onDrag(d.delta.dx),
        child: SizedBox(
          width: _grosorDivisor,
          child: Center(
            child: Container(
              width: 2,
              color: const Color(0xFF0F3460),
            ),
          ),
        ),
      ),
    );
  }

  Widget _divisorVerticalArrastrable({
    required void Function(double dy) onDrag,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeRow,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (d) => onDrag(d.delta.dy),
        child: SizedBox(
          height: _grosorDivisor,
          child: Center(
            child: Container(
              height: 2,
              color: const Color(0xFF0F3460),
            ),
          ),
        ),
      ),
    );
  }

  Widget _panelAgendaCaja(ReservasProvider provider) {
    final lista = _filtrarPorFranja(provider.reservasDelDia);
    final tituloCapitalizado = _tituloDiaAgenda(provider.diaAgenda);
    final totalPersonas =
        lista.fold<int>(0, (s, r) => s + r.numeroPersonas);
    final totalMesas = lista.length;
    final resumenFranja = _franjaActiva == FranjaReserva.canceladas
        ? '$totalMesas cancelada${totalMesas == 1 ? '' : 's'}'
        : _franjaActiva == FranjaReserva.asporto
            ? '$totalMesas asporto${totalMesas == 1 ? '' : 's'}'
            : '$totalPersonas persona${totalPersonas == 1 ? '' : 's'}, '
                '$totalMesas mesa${totalMesas == 1 ? '' : 's'}';
    final hayAsporto = provider.reservasDelDia.any(
      (r) =>
          r.estaPendiente &&
          clasificarReserva(r, _horarios) == FranjaReserva.asporto,
    );
    final hayCanceladas = provider.reservasDelDia.any(
      (r) => r.estado == EstadoReserva.cancelada,
    );
    final debeParpadearAnimacion =
        (hayAsporto && _franjaActiva != FranjaReserva.asporto) ||
        (hayCanceladas && _franjaActiva != FranjaReserva.canceladas);
    _sincronizarParpadeoFranjas(debeParpadearAnimacion);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (provider.error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Text(
              provider.error!,
              style: TextStyle(color: Colors.orange.shade300, fontSize: 12),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Row(
            children: [
              IconButton(
                onPressed: provider.sincronizando
                    ? null
                    : () => provider.irDiaAnteriorAgenda(),
                icon: const Icon(Icons.chevron_left, color: Color(0xFF00D9A5)),
                tooltip: 'Día anterior',
              ),
              Expanded(
                child: InkWell(
                  onTap: provider.sincronizando
                      ? null
                      : () => _elegirDiaAgenda(provider),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        Text(
                          tituloCapitalizado,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          resumenFranja,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: provider.sincronizando
                    ? null
                    : () => provider.irDiaSiguienteAgenda(),
                icon: const Icon(Icons.chevron_right, color: Color(0xFF00D9A5)),
                tooltip: 'Día siguiente',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: _botonFranja(
                  franja: FranjaReserva.comida,
                  color: const Color(0xFF00D9A5),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _botonFranja(
                  franja: FranjaReserva.cena,
                  color: const Color(0xFFE94560),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _botonFranja(
                  franja: FranjaReserva.asporto,
                  color: const Color(0xFFFFB74D),
                  parpadear: hayAsporto,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _botonFranja(
                  franja: FranjaReserva.canceladas,
                  color: const Color(0xFF9E9E9E),
                  parpadear: hayCanceladas,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFF0F3460)),
        Expanded(
          child: lista.isEmpty
              ? Center(
                  child: Text(
                    'No hay reservas de ${_franjaActiva.etiqueta} este día',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: (lista.length + 1) ~/ 2,
                  itemBuilder: (context, fila) {
                    final i = fila * 2;
                    final izq = lista[i];
                    final der = i + 1 < lista.length ? lista[i + 1] : null;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: fila < (lista.length + 1) ~/ 2 - 1 ? 8 : 0,
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _tarjetaAgendaReserva(
                                provider: provider,
                                reserva: izq,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: der != null
                                  ? _tarjetaAgendaReserva(
                                      provider: provider,
                                      reserva: der,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _sincronizarParpadeoFranjas(bool debeParpadear) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (debeParpadear) {
        if (!_asportoBlinkCtrl.isAnimating) {
          unawaited(_asportoBlinkCtrl.repeat(reverse: true));
        }
      } else if (_asportoBlinkCtrl.isAnimating) {
        _asportoBlinkCtrl
          ..stop()
          ..value = 1;
      }
    });
  }

  Widget _botonFranja({
    required FranjaReserva franja,
    required Color color,
    bool parpadear = false,
  }) {
    final activo = _franjaActiva == franja;
    final debeParpadear = parpadear && !activo;

    Widget boton({required Color fondo, required Color texto}) {
      return Material(
        color: fondo,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => setState(() => _franjaActiva = franja),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              franja.etiqueta,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: texto,
                fontWeight: FontWeight.bold,
                fontSize: franja == FranjaReserva.canceladas ? 11 : 13,
              ),
            ),
          ),
        ),
      );
    }

    if (!debeParpadear) {
      return boton(
        fondo: activo ? color : color.withValues(alpha: 0.18),
        texto: activo ? Colors.black87 : color,
      );
    }

    return AnimatedBuilder(
      animation: _asportoBlinkCtrl,
      builder: (context, _) {
        final t = _asportoBlinkCtrl.value;
        // Pico más brillante: mezcla hacia blanco y alpha alto.
        final fondo = Color.lerp(
          color.withValues(alpha: 0.45),
          Color.lerp(color, Colors.white, 0.55)!,
          t,
        )!;
        return boton(
          fondo: fondo,
          texto: Color.lerp(Colors.black87, Colors.black, t) ?? Colors.black87,
        );
      },
    );
  }

  Widget _tarjetaAgendaReserva({
    required ReservasProvider provider,
    required Reserva reserva,
  }) {
    final sel = _reservaEditandoId == reserva.id;
    final mesa = reserva.mesaAsignada;
    final estado = reserva.estado;

    Color colorEstado;
    String textoEstado;
    switch (estado) {
      case EstadoReserva.sentada:
        colorEstado = const Color(0xFF4FC3F7);
        textoEstado = 'Sentada';
        break;
      case EstadoReserva.cancelada:
        colorEstado = const Color(0xFFE94560);
        textoEstado = 'Cancelada';
        break;
      case EstadoReserva.cobrada:
        colorEstado = const Color(0xFF81C784);
        textoEstado = 'Cobrada';
        break;
      case EstadoReserva.pendiente:
        colorEstado = const Color(0xFFFFB74D);
        textoEstado = 'Pendiente';
    }

    return Material(
      color: sel ? const Color(0xFF0F3460) : const Color(0xFF16213E),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _cargarReservaEnFormulario(reserva)),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _formatoHora.format(reserva.fechaHoraLlegada),
                    style: const TextStyle(
                      color: Color(0xFF00D9A5),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (mesa != null)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D9A5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'M$mesa',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorEstado.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorEstado.withValues(alpha: 0.6)),
                    ),
                    child: Text(
                      textoEstado,
                      style: TextStyle(color: colorEstado, fontSize: 11),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: reserva.estado == EstadoReserva.cancelada
                        ? null
                        : () => _confirmarEliminarReserva(provider, reserva),
                    icon: const Icon(Icons.cancel_outlined, color: Color(0xFFE94560)),
                    tooltip: 'Cancelar reserva',
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                reserva.nombreCliente,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _textoCubiertos(reserva),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              _previewPlatosReserva(reserva),
              if (reserva.alergiasNotas.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  reserva.alergiasNotas,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.orange.shade200, fontSize: 12),
                ),
              ],
              if (reserva.estado == EstadoReserva.cancelada) ...[
                const Spacer(),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () => _reactivarReserva(provider, reserva),
                    icon: const Icon(Icons.undo, size: 16),
                    label: const Text('Reactivar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00D9A5),
                      foregroundColor: Colors.black87,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ] else if (reserva.estaPendiente) ...[
                const Spacer(),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: reserva.numeroPersonas <= 0
                      ? Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          alignment: WrapAlignment.end,
                          children: [
                            FilledButton.icon(
                              onPressed: () => _imprimirAsporto(reserva),
                              icon: const Icon(Icons.print, size: 16),
                              label: const Text('Imprimir'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFFFB74D),
                                foregroundColor: Colors.black87,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: () =>
                                  _cobrarAsporto(provider, reserva),
                              icon: const Icon(Icons.payments, size: 16),
                              label: const Text('Cobrar'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF00D9A5),
                                foregroundColor: Colors.black87,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        )
                      : FilledButton.icon(
                          onPressed: () => _asignarMesa(provider, reserva),
                          icon: const Icon(Icons.table_restaurant, size: 16),
                          label: const Text('Asignar mesa'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF00D9A5),
                            foregroundColor: Colors.black87,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
          permitirEditar: false,
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
            permitirEditar: true,
          ),
        if (!PlatformUtils.isAndroid)
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
            permitirEditar: false,
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
    bool permitirEditar = false,
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
                  permitirEditar: permitirEditar,
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
    bool permitirEditar = false,
  }) {
    final sel = permitirEditar
        ? _reservaEditandoId == reserva.id
        : _reservaSeleccionada?.id == reserva.id;
    final mostrarPorEnviar =
        mostrarEtiquetaPorEnviar && provider.pendienteDeEnvio(reserva);

    return Material(
      color: sel ? const Color(0xFF0F3460) : const Color(0xFF1A1A2E),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          if (permitirEditar && reserva.id != null && reserva.id! > 0) {
            setState(() => _cargarReservaEnFormulario(reserva));
          } else {
            setState(() => _reservaSeleccionada = reserva);
          }
        },
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
                  if (permitirEditar && reserva.sincronizadaEnCaja)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4FC3F7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'En caja',
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
                reserva.numeroPersonas <= 0
                    ? 'Asporto · ${reserva.itemsReservados.length} plato(s) pre-reservado(s)'
                    : '${reserva.numeroPersonas} personas · '
                        '${reserva.itemsReservados.length} plato(s) pre-reservado(s)',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              _previewPlatosReserva(reserva),
              if (reserva.alergiasNotas.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  reserva.alergiasNotas,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.orange.shade200, fontSize: 12),
                ),
              ],
              if (permitirEditar) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () =>
                        setState(() => _cargarReservaEnFormulario(reserva)),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Editar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00D9A5),
                      foregroundColor: Colors.black87,
                    ),
                  ),
                ),
              ],
              if (permitirAsignarMesa && reserva.numeroPersonas > 0) ...[
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
              if (permitirAsignarMesa &&
                  reserva.numeroPersonas <= 0 &&
                  reserva.estaPendiente) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _imprimirAsporto(reserva),
                        icon: const Icon(Icons.print, size: 18),
                        label: const Text('Imprimir pedido'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB74D),
                          foregroundColor: Colors.black87,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => _cobrarAsporto(provider, reserva),
                        icon: const Icon(Icons.payments, size: 18),
                        label: const Text('Cobrar'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF00D9A5),
                          foregroundColor: Colors.black87,
                        ),
                      ),
                    ],
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

    final itemsComanda = <({Producto producto, int cantidad})>[];
    for (final entry in _cantidadesProducto.entries) {
      if (entry.value <= 0) continue;
      final p = provider.productos.where((x) => x.id == entry.key).firstOrNull;
      if (p == null) continue;
      itemsComanda.add((producto: p, cantidad: entry.value));
    }
    itemsComanda.sort(
      (a, b) => a.producto.nombre.compareTo(b.producto.nombre),
    );
    final totalComanda = itemsComanda.fold<double>(
      0,
      (s, e) => s + e.producto.precio * e.cantidad,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _reservaEditandoId != null
                      ? 'Editar reserva'
                      : (PlatformUtils.isAndroid
                          ? 'Nueva reserva (envío al VPS)'
                          : 'Nueva reserva manual'),
                  style: const TextStyle(
                    color: Color(0xFF00D9A5),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_reservaEditandoId != null)
                TextButton(
                  onPressed: () => setState(_limpiarFormulario),
                  child: const Text('Cancelar edición'),
                ),
            ],
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
                  _personas <= 0
                      ? 'Cubiertos: 0 (asporto)'
                      : 'Personas: $_personas',
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
              IconButton.filled(
                onPressed: () => setState(
                  () => _personas = (_personas - 1).clamp(0, 99),
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
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Platos de esta reserva',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (itemsComanda.isNotEmpty)
                Text(
                  '€${totalComanda.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF00D9A5),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (itemsComanda.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F3460),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF16213E)),
              ),
              child: const Text(
                'Ningún plato aún. Añade desde el catálogo abajo.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            )
          else
            ...itemsComanda.map((e) {
              final id = e.producto.id ?? 0;
              final qty = e.cantidad;
              final sub = e.producto.precio * qty;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F3460),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF00D9A5).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.producto.nombre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '€${e.producto.precio.toStringAsFixed(2)} · '
                            'subtotal €${sub.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() {
                        if (qty <= 1) {
                          _cantidadesProducto.remove(id);
                        } else {
                          _cantidadesProducto[id] = qty - 1;
                        }
                      }),
                      icon: const Icon(Icons.remove_circle, size: 26),
                      color: const Color(0xFFE94560),
                    ),
                    Text(
                      '$qty',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() {
                        _cantidadesProducto[id] = qty + 1;
                      }),
                      icon: const Icon(Icons.add_circle, size: 26),
                      color: const Color(0xFF00D9A5),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Quitar',
                      onPressed: () => setState(() {
                        _cantidadesProducto.remove(id);
                      }),
                      icon: const Icon(Icons.delete_outline, size: 22),
                      color: Colors.white38,
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 20),
          const Text(
            'Añadir del catálogo',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (PlatformUtils.isAndroid && provider.productos.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Sin carta cargada. Pulsa sync (↑) para descargar los platos.',
                style: TextStyle(color: Colors.orange.shade300, fontSize: 12),
              ),
            ),
          TextField(
            controller: _buscarProductoCtrl,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white),
            decoration: _decoration('Buscar producto...'),
          ),
          const SizedBox(height: 8),
          ...productosFiltrados.take(12).map((p) {
            final id = p.id ?? 0;
            final qtyEnComanda = _cantidadesProducto[id] ?? 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
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
                    style: const TextStyle(
                      color: Color(0xFF00D9A5),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (qtyEnComanda > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        'x$qtyEnComanda',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  FilledButton(
                    onPressed: () => setState(() {
                      _cantidadesProducto[id] = qtyEnComanda + 1;
                    }),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00D9A5),
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Añadir'),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
          if (_reservaEditandoId != null && PlatformUtils.isAndroid) ...[
            OutlinedButton.icon(
              onPressed: _guardando || _reservaSeleccionada == null
                  ? null
                  : () => _confirmarEliminarReserva(
                        provider,
                        _reservaSeleccionada!,
                      ),
              icon: const Icon(Icons.cancel_outlined, color: Color(0xFFE94560)),
              label: const Text(
                'Cancelar reserva',
                style: TextStyle(color: Color(0xFFE94560)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE94560)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton.icon(
            onPressed: _guardando ? null : () => _guardarReserva(provider),
            icon: _guardando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(
              _guardando
                  ? 'Guardando…'
                  : (_reservaEditandoId != null
                      ? 'Guardar cambios'
                      : 'Guardar reserva'),
            ),
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

  /// Líneas cortas de platos para preview en tarjetas.
  Widget _previewPlatosReserva(Reserva reserva) {
    if (reserva.itemsReservados.isEmpty) {
      return const SizedBox.shrink();
    }
    final lineas = reserva.itemsReservados
        .map((i) => '${i.nombreProducto} x${i.cantidad}')
        .toList();
    final mostrar = lineas.take(4).toList();
    final resto = lineas.length - mostrar.length;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final l in mostrar)
            Text(
              l,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          if (resto > 0)
            Text(
              '+$resto más…',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
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

/// Diálogo simple para ajustar franjas de comida y cena.
class _DialogoHorariosReservas extends StatefulWidget {
  const _DialogoHorariosReservas({required this.inicial});

  final HorariosReservas inicial;

  @override
  State<_DialogoHorariosReservas> createState() =>
      _DialogoHorariosReservasState();
}

class _DialogoHorariosReservasState extends State<_DialogoHorariosReservas> {
  late int _comidaInicio;
  late int _comidaFin;
  late int _cenaInicio;
  late int _cenaFin;

  @override
  void initState() {
    super.initState();
    _comidaInicio = widget.inicial.comidaInicioMin;
    _comidaFin = widget.inicial.comidaFinMin;
    _cenaInicio = widget.inicial.cenaInicioMin;
    _cenaFin = widget.inicial.cenaFinMin;
  }

  Future<void> _elegir(String titulo, int actual, ValueChanged<int> onOk) async {
    final tod = TimeOfDay(hour: actual ~/ 60, minute: actual % 60);
    final elegido = await showTimePicker(
      context: context,
      initialTime: tod,
      helpText: titulo,
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
    if (elegido == null) return;
    onOk(minutosDesdeTimeOfDay(hour: elegido.hour, minute: elegido.minute));
  }

  Widget _fila(String label, int minutos, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(color: Colors.white70)),
      trailing: TextButton(
        onPressed: onTap,
        child: Text(
          formatoMinutosDelDia(minutos),
          style: const TextStyle(
            color: Color(0xFF00D9A5),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF16213E),
      title: const Text(
        'Horarios comida / cena',
        style: TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Asporto = reserva con 0 cubiertos',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            _fila(
              'Comida desde',
              _comidaInicio,
              () => _elegir('Comida desde', _comidaInicio, (v) {
                setState(() => _comidaInicio = v);
              }),
            ),
            _fila(
              'Comida hasta',
              _comidaFin,
              () => _elegir('Comida hasta', _comidaFin, (v) {
                setState(() => _comidaFin = v);
              }),
            ),
            const Divider(color: Color(0xFF0F3460)),
            _fila(
              'Cena desde',
              _cenaInicio,
              () => _elegir('Cena desde', _cenaInicio, (v) {
                setState(() => _cenaInicio = v);
              }),
            ),
            _fila(
              'Cena hasta',
              _cenaFin,
              () => _elegir('Cena hasta', _cenaFin, (v) {
                setState(() => _cenaFin = v);
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              HorariosReservas(
                comidaInicioMin: _comidaInicio,
                comidaFinMin: _comidaFin,
                cenaInicioMin: _cenaInicio,
                cenaFinMin: _cenaFin,
              ),
            );
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF00D9A5),
            foregroundColor: Colors.black87,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _ResultadoCobroAsporto {
  const _ResultadoCobroAsporto({
    required this.metodo,
    this.importeRecibido,
  });

  final String metodo;
  final double? importeRecibido;
}

/// Diálogo de cobro total para asporto (efectivo / tarjeta / otros).
class _DialogoCobroAsporto extends StatefulWidget {
  const _DialogoCobroAsporto({
    required this.nombreCliente,
    required this.total,
  });

  final String nombreCliente;
  final double total;

  @override
  State<_DialogoCobroAsporto> createState() => _DialogoCobroAsportoState();
}

class _DialogoCobroAsportoState extends State<_DialogoCobroAsporto> {
  String? _metodo;
  final _importeCtrl = TextEditingController();
  var _procesando = false;

  @override
  void initState() {
    super.initState();
    _importeCtrl.text = widget.total.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _importeCtrl.dispose();
    super.dispose();
  }

  double? _parseImporte() {
    final t = _importeCtrl.text.replaceAll(',', '.').trim();
    if (t.isEmpty) return null;
    final v = double.tryParse(t);
    if (v == null || v.isNaN || v.isInfinite || v < 0) return null;
    return v;
  }

  Future<void> _confirmar() async {
    if (_metodo == null) return;
    final recibido = _parseImporte();
    if (_metodo == 'efectivo') {
      if (recibido == null || recibido + 0.009 < widget.total) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Importe recibido insuficiente'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }
    setState(() => _procesando = true);
    Navigator.of(context).pop(
      _ResultadoCobroAsporto(
        metodo: _metodo!,
        importeRecibido: _metodo == 'efectivo' ? recibido : null,
      ),
    );
  }

  Widget _botonMetodo(String id, String label, IconData icon) {
    final sel = _metodo == id;
    return Expanded(
      child: Material(
        color: sel ? const Color(0xFF00D9A5) : const Color(0xFF0F3460),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: _procesando
              ? null
              : () => setState(() {
                    _metodo = id;
                    if (id != 'efectivo') {
                      _importeCtrl.text = widget.total.toStringAsFixed(2);
                    }
                  }),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: sel ? Colors.black87 : Colors.white70,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: sel ? Colors.black87 : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recibido = _parseImporte() ?? 0;
    final vuelto = _metodo == 'efectivo' && recibido >= widget.total
        ? recibido - widget.total
        : null;

    return AlertDialog(
      backgroundColor: const Color(0xFF16213E),
      title: Text(
        'Cobrar asporto — ${widget.nombreCliente}',
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Total: €${widget.total.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF00D9A5),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _botonMetodo('efectivo', 'Efectivo', Icons.payments),
                const SizedBox(width: 8),
                _botonMetodo('tarjeta', 'Tarjeta', Icons.credit_card),
                const SizedBox(width: 8),
                _botonMetodo('otros', 'Otros', Icons.more_horiz),
              ],
            ),
            if (_metodo == 'efectivo') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _importeCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Importe recibido',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF0F3460),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (vuelto != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Vuelto: €${vuelto.toStringAsFixed(2)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ],
            if (_metodo == 'tarjeta') ...[
              const SizedBox(height: 12),
              Text(
                'Cobre €${widget.total.toStringAsFixed(2)} en el datáfono',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.orange.shade200, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _procesando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _procesando || _metodo == null ? null : _confirmar,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF00D9A5),
            foregroundColor: Colors.black87,
          ),
          child: const Text('Confirmar cobro'),
        ),
      ],
    );
  }
}
