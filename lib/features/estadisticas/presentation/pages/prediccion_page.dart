import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/core.dart';

/// Previsión de demanda (fase 6): base histórica + firmado + uplift clientes.
class PrediccionPage extends StatefulWidget {
  const PrediccionPage({super.key});

  @override
  State<PrediccionPage> createState() => _PrediccionPageState();
}

class _PrediccionPageState extends State<PrediccionPage> {
  DateTime _fecha = DateTime.now();
  String _servicio = 'comida';
  Map<String, dynamic>? _data;
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final h = DateTime.now().hour;
    _servicio = h >= 17 ? 'cena' : 'comida';
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    ApiClient? client;
    try {
      final url = await getReservasCentralUrlEfectiva();
      if (url == null || url.isEmpty) {
        throw StateError('Configura el servidor central de reservas');
      }
      client = ApiClient(url);
      final data = await client.obtenerPrediccion(
        fecha: DateFormat('yyyy-MM-dd').format(_fecha),
        servicio: _servicio,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
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

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final resumen = _data?['resumen'] as Map<String, dynamic>?;
    final ctx = _data?['contexto'] as Map<String, dynamic>?;
    final platos = (_data?['platos'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Previsión del día'),
        actions: [
          IconButton(
            onPressed: _cargando ? null : _cargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF16213E),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _fecha,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                    );
                    if (d != null && mounted) {
                      setState(() => _fecha = d);
                      await _cargar();
                    }
                  },
                  icon: const Icon(Icons.calendar_today,
                      color: Color(0xFF00D9A5), size: 20),
                  label: Text(
                    fmt.format(_fecha),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'comida', label: Text('Comida')),
                    ButtonSegment(value: 'cena', label: Text('Cena')),
                  ],
                  selected: {_servicio},
                  onSelectionChanged: (s) {
                    setState(() => _servicio = s.first);
                    _cargar();
                  },
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          if (ctx != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${ctx['esFestivo'] == true ? (ctx['nombreFestivo'] ?? 'Festivo') : (ctx['esFinde'] == true ? 'Fin de semana' : 'Laborable')}'
                  '${ctx['climaResumen'] != null ? ' · ${ctx['climaResumen']}' : ''}'
                  '${ctx['horaOscurece'] != null ? ' · oscurece ${ctx['horaOscurece']}' : ''}',
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
            ),
          if (resumen != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _chip('Total', '${resumen['prediccionTotal']}',
                      const Color(0xFF00D9A5)),
                  _chip('Base', '${resumen['baseTotal']}', Colors.white70),
                  _chip('Firmado', '${resumen['firmadoTotal']}',
                      const Color(0xFF4FC3F7)),
                  _chip('Uplift', '${resumen['upliftTotal']}',
                      const Color(0xFFFFB74D)),
                ],
              ),
            ),
          if (resumen?['aviso'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                resumen!['aviso'] as String,
                style: const TextStyle(color: Color(0xFFFFB74D), fontSize: 13),
              ),
            ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : platos.isEmpty
                    ? const Center(
                        child: Text(
                          'Sin previsión: aún no hay histórico de ventas\n'
                          'ni reservas/ítems para este servicio.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: platos.length,
                        itemBuilder: (context, i) {
                          final p =
                              Map<String, dynamic>.from(platos[i] as Map);
                          final pred =
                              (p['prediccion'] as num?)?.toDouble() ?? 0;
                          final maxPred = platos.isNotEmpty
                              ? ((platos.first as Map)['prediccion'] as num?)
                                      ?.toDouble() ??
                                  1
                              : 1;
                          final upliftClientes =
                              (p['upliftClientes'] as List<dynamic>?) ?? [];
                          return Card(
                            color: const Color(0xFF16213E),
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              title: Text(
                                p['nombreProducto'] as String? ?? 'Plato',
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                'base ${p['base']} · firmado ${p['firmado']} · uplift ${p['uplift']}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: Text(
                                pred.toStringAsFixed(pred == pred.roundToDouble()
                                    ? 0
                                    : 1),
                                style: const TextStyle(
                                  color: Color(0xFF00D9A5),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    12,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      LinearProgressIndicator(
                                        value: maxPred > 0
                                            ? pred / maxPred
                                            : 0,
                                        backgroundColor:
                                            const Color(0xFF0F3460),
                                        valueColor:
                                            const AlwaysStoppedAnimation(
                                          Color(0xFF00D9A5),
                                        ),
                                      ),
                                      if (p['fuenteBase'] != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Fuente base: ${p['fuenteBase']}',
                                          style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                      if (upliftClientes.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Uplift por cliente',
                                          style: TextStyle(
                                            color: Color(0xFFFFB74D),
                                            fontSize: 12,
                                          ),
                                        ),
                                        ...upliftClientes.map((c) {
                                          final m = Map<String, dynamic>.from(
                                            c as Map,
                                          );
                                          final freqPct = ((((m['frecuencia']
                                                          as num?) ??
                                                      0) *
                                                  100)
                                              .round());
                                          return Text(
                                            '· ${m['nombre']}: +${m['cantidad']} '
                                            '($freqPct% de visitas)',
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                            ),
                                          );
                                        }),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3460),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
