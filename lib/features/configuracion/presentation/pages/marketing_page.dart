import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/core.dart';

/// Alta de campañas y eventos (fase 5) contra el VPS.
class MarketingPage extends StatefulWidget {
  const MarketingPage({super.key});

  @override
  State<MarketingPage> createState() => _MarketingPageState();
}

class _MarketingPageState extends State<MarketingPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<Map<String, dynamic>> _campanias = [];
  List<Map<String, dynamic>> _eventos = [];
  Map<String, dynamic>? _contextoHoy;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _cargar();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<ApiClient?> _cliente() async {
    final url = await getReservasCentralUrlEfectiva();
    if (url == null || url.isEmpty) {
      throw StateError('Configura el servidor central de reservas');
    }
    return ApiClient(url);
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    ApiClient? client;
    try {
      client = await _cliente();
      final hoy = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final campanias = await client!.listarCampanias();
      final eventos = await client.listarEventos();
      Map<String, dynamic>? ctx;
      try {
        ctx = await client.obtenerContextoDia(hoy);
      } catch (_) {
        ctx = null;
      }
      if (!mounted) return;
      setState(() {
        _campanias = campanias;
        _eventos = eventos;
        _contextoHoy = ctx;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    } finally {
      client?.dispose();
    }
  }

  Future<void> _guardarCampania({Map<String, dynamic>? existente}) async {
    final nombreCtrl = TextEditingController(
      text: existente?['nombre'] as String? ?? '',
    );
    final canalCtrl = TextEditingController(
      text: existente?['canal'] as String? ?? '',
    );
    final notasCtrl = TextEditingController(
      text: existente?['notas'] as String? ?? '',
    );
    var tipo = existente?['tipo'] as String? ?? 'general';
    var inicio = existente?['fechaInicio'] != null
        ? DateTime.parse(existente!['fechaInicio'] as String)
        : DateTime.now();
    var fin = existente?['fechaFin'] != null
        ? DateTime.parse(existente!['fechaFin'] as String)
        : DateTime.now().add(const Duration(days: 7));
    var activa = existente?['activa'] as bool? ?? true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          title: Text(
            existente == null ? 'Nueva campaña' : 'Editar campaña',
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: tipo,
                  dropdownColor: const Color(0xFF16213E),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: 'general', child: Text('General')),
                    DropdownMenuItem(value: 'plato', child: Text('Plato')),
                    DropdownMenuItem(value: 'evento', child: Text('Evento')),
                  ],
                  onChanged: (v) => setLocal(() => tipo = v ?? 'general'),
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                TextField(
                  controller: canalCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Canal (IG, flyer…)',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Inicio: ${DateFormat('dd/MM/yyyy').format(inicio)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: inicio,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setLocal(() => inicio = d);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Fin: ${DateFormat('dd/MM/yyyy').format(fin)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: fin,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setLocal(() => fin = d);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Activa',
                    style: TextStyle(color: Colors.white70),
                  ),
                  value: activa,
                  onChanged: (v) => setLocal(() => activa = v),
                ),
                TextField(
                  controller: notasCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Notas',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    ApiClient? client;
    try {
      client = await _cliente();
      await client!.guardarCampania({
        if (existente?['id'] != null) 'id': existente!['id'],
        'nombre': nombreCtrl.text.trim(),
        'tipo': tipo,
        'canal': canalCtrl.text.trim(),
        'fechaInicio': DateFormat('yyyy-MM-dd').format(inicio),
        'fechaFin': DateFormat('yyyy-MM-dd').format(fin),
        'notas': notasCtrl.text.trim(),
        'activa': activa,
      });
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    } finally {
      client?.dispose();
      nombreCtrl.dispose();
      canalCtrl.dispose();
      notasCtrl.dispose();
    }
  }

  Future<void> _guardarEvento({Map<String, dynamic>? existente}) async {
    final nombreCtrl = TextEditingController(
      text: existente?['nombre'] as String? ?? '',
    );
    final tipoCtrl = TextEditingController(
      text: existente?['tipo'] as String? ?? 'musica',
    );
    final notasCtrl = TextEditingController(
      text: existente?['notas'] as String? ?? '',
    );
    final aforoCtrl = TextEditingController(
      text: existente?['aforoEsperado']?.toString() ?? '',
    );
    var inicio = existente?['fechaInicio'] != null
        ? DateTime.parse(existente!['fechaInicio'] as String)
        : DateTime.now();
    var fin = existente?['fechaFin'] != null
        ? DateTime.parse(existente!['fechaFin'] as String)
        : DateTime.now();
    var activo = existente?['activo'] as bool? ?? true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          title: Text(
            existente == null ? 'Nuevo evento' : 'Editar evento',
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                TextField(
                  controller: tipoCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Tipo (musica, deporte…)',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                TextField(
                  controller: aforoCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Aforo esperado',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Inicio: ${DateFormat('dd/MM/yyyy').format(inicio)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: inicio,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setLocal(() => inicio = d);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Fin: ${DateFormat('dd/MM/yyyy').format(fin)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: fin,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setLocal(() => fin = d);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Activo',
                    style: TextStyle(color: Colors.white70),
                  ),
                  value: activo,
                  onChanged: (v) => setLocal(() => activo = v),
                ),
                TextField(
                  controller: notasCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Notas',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    ApiClient? client;
    try {
      client = await _cliente();
      await client!.guardarEvento({
        if (existente?['id'] != null) 'id': existente!['id'],
        'nombre': nombreCtrl.text.trim(),
        'tipo': tipoCtrl.text.trim(),
        'fechaInicio': DateFormat('yyyy-MM-dd').format(inicio),
        'fechaFin': DateFormat('yyyy-MM-dd').format(fin),
        'aforoEsperado': int.tryParse(aforoCtrl.text.trim()),
        'notas': notasCtrl.text.trim(),
        'activo': activo,
      });
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    } finally {
      client?.dispose();
      nombreCtrl.dispose();
      tipoCtrl.dispose();
      notasCtrl.dispose();
      aforoCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctx = _contextoHoy;
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Campañas y eventos'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Campañas'),
            Tab(text: 'Eventos'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _cargando ? null : _cargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00D9A5),
        onPressed: () {
          if (_tabs.index == 0) {
            _guardarCampania();
          } else {
            _guardarEvento();
          }
        },
        child: const Icon(Icons.add, color: Colors.black87),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  children: [
                    if (ctx != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F3460),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Hoy (${ctx['fecha']}): '
                          '${ctx['esFestivo'] == true ? (ctx['nombreFestivo'] ?? 'Festivo') : (ctx['esFinde'] == true ? 'Fin de semana' : 'Laborable')}'
                          '${ctx['climaResumen'] != null ? ' · ${ctx['climaResumen']}' : ''}'
                          '${ctx['tempMedia'] != null ? ' · ${ctx['tempMedia']}°C' : ''}'
                          '${ctx['horaOscurece'] != null ? ' · oscurece ${ctx['horaOscurece']}' : ''}'
                          ' · Módena',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          _lista(
                            _campanias,
                            titulo: (c) =>
                                '${c['nombre']} (${c['tipo']})'
                                '${c['activa'] == true ? '' : ' · inactiva'}',
                            subtitulo: (c) =>
                                '${c['fechaInicio']} → ${c['fechaFin']}'
                                '${(c['canal'] as String?)?.isNotEmpty == true ? ' · ${c['canal']}' : ''}',
                            onEdit: (c) => _guardarCampania(existente: c),
                            onDelete: (c) async {
                              final client = await _cliente();
                              try {
                                await client!.eliminarCampania(c['id'] as int);
                                await _cargar();
                              } finally {
                                client?.dispose();
                              }
                            },
                          ),
                          _lista(
                            _eventos,
                            titulo: (e) =>
                                '${e['nombre']} (${e['tipo']})'
                                '${e['activo'] == true ? '' : ' · inactivo'}',
                            subtitulo: (e) =>
                                '${e['fechaInicio']} → ${e['fechaFin']}',
                            onEdit: (e) => _guardarEvento(existente: e),
                            onDelete: (e) async {
                              final client = await _cliente();
                              try {
                                await client!.eliminarEvento(e['id'] as int);
                                await _cargar();
                              } finally {
                                client?.dispose();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _lista(
    List<Map<String, dynamic>> items, {
    required String Function(Map<String, dynamic>) titulo,
    required String Function(Map<String, dynamic>) subtitulo,
    required void Function(Map<String, dynamic>) onEdit,
    required Future<void> Function(Map<String, dynamic>) onDelete,
  }) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Nada todavía. Pulsa + para añadir.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return Card(
          color: const Color(0xFF16213E),
          child: ListTile(
            title: Text(
              titulo(item),
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              subtitulo(item),
              style: const TextStyle(color: Colors.white54),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF00D9A5)),
                  onPressed: () => onEdit(item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('¿Eliminar?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('No'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Sí'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) await onDelete(item);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
