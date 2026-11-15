import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/core.dart';

/// Ficha CRM del cliente (hábitos desde ventas del VPS).
class FichaClientePage extends StatefulWidget {
  const FichaClientePage({
    super.key,
    this.clienteId,
    this.telefono,
    this.nombreFallback,
  });

  final int? clienteId;
  final String? telefono;
  final String? nombreFallback;

  /// Abre la ficha como diálogo modal (desktop) o página.
  static Future<void> abrir(
    BuildContext context, {
    int? clienteId,
    String? telefono,
    String? nombreFallback,
  }) async {
    if ((clienteId == null || clienteId <= 0) &&
        (telefono == null || telefono.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta reserva no tiene teléfono ni ficha de cliente'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FichaClientePage(
          clienteId: clienteId,
          telefono: telefono,
          nombreFallback: nombreFallback,
        ),
      ),
    );
  }

  @override
  State<FichaClientePage> createState() => _FichaClientePageState();
}

class _FichaClientePageState extends State<FichaClientePage> {
  Map<String, dynamic>? _ficha;
  bool _cargando = true;
  String? _error;
  final _alergiasCtrl = TextEditingController();
  bool _guardandoNotas = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _alergiasCtrl.dispose();
    super.dispose();
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
      final ficha = await client.obtenerFichaCliente(
        id: widget.clienteId,
        telefono: widget.telefono,
      );
      if (!mounted) return;
      final cliente = ficha['cliente'] as Map<String, dynamic>?;
      _alergiasCtrl.text = (cliente?['alergiasNotas'] as String?) ?? '';
      setState(() {
        _ficha = ficha;
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

  Future<void> _guardarAlergias() async {
    final cliente = _ficha?['cliente'] as Map<String, dynamic>?;
    final id = cliente?['id'] as int?;
    if (id == null) return;
    setState(() => _guardandoNotas = true);
    ApiClient? client;
    try {
      final url = await getReservasCentralUrlEfectiva();
      if (url == null || url.isEmpty) throw StateError('Sin servidor central');
      client = ApiClient(url);
      await client.actualizarCliente(
        id: id,
        alergiasNotas: _alergiasCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notas del cliente guardadas'),
          backgroundColor: Color(0xFF00D9A5),
        ),
      );
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    } finally {
      client?.dispose();
      if (mounted) setState(() => _guardandoNotas = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cliente = _ficha?['cliente'] as Map<String, dynamic>?;
    final resumen = _ficha?['resumen'] as Map<String, dynamic>?;
    final platos = (_ficha?['platosHabituales'] as List<dynamic>?) ?? [];
    final reservas = (_ficha?['reservasRecientes'] as List<dynamic>?) ?? [];
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final nombre = (cliente?['nombre'] as String?)?.trim().isNotEmpty == true
        ? cliente!['nombre'] as String
        : (widget.nombreFallback ?? 'Cliente');

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: Text('Ficha · $nombre'),
        actions: [
          IconButton(
            onPressed: _cargando ? null : _cargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
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
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Card(
                      color: const Color(0xFF16213E),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone,
                                  size: 18,
                                  color: Color(0xFF00D9A5),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  (cliente?['telefono'] as String?) ??
                                      widget.telefono ??
                                      '—',
                                  style: const TextStyle(
                                    color: Color(0xFF00D9A5),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            if (cliente?['ultimaVisitaEn'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Última visita: ${fmt.format(DateTime.parse(cliente!['ultimaVisitaEn'] as String).toLocal())}',
                                style: const TextStyle(color: Colors.white54),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (resumen != null)
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _chip(
                            'Visitas',
                            '${resumen['visitas'] ?? 0}',
                            const Color(0xFF00D9A5),
                          ),
                          _chip(
                            'Ticket medio',
                            resumen['ticketMedio'] != null
                                ? '${(resumen['ticketMedio'] as num).toStringAsFixed(2)} €'
                                : '—',
                            const Color(0xFF4FC3F7),
                          ),
                          _chip(
                            'Total',
                            '${(resumen['totalGastado'] as num?)?.toStringAsFixed(2) ?? '0'} €',
                            const Color(0xFFFFB74D),
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                    const Text(
                      'Alergias / notas CRM',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _alergiasCtrl,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF16213E),
                        hintText: 'Celíaco, trona, preferencias…',
                        hintStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: _guardandoNotas ? null : _guardarAlergias,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF00D9A5),
                          foregroundColor: Colors.black87,
                        ),
                        child: _guardandoNotas
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Guardar notas'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Platos habituales',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (platos.isEmpty)
                      const Text(
                        'Aún no hay cobros enlazados a este cliente.',
                        style: TextStyle(color: Colors.white54),
                      )
                    else
                      ...platos.map((raw) {
                        final p = Map<String, dynamic>.from(raw as Map);
                        return Card(
                          color: const Color(0xFF16213E),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              p['nombreProducto'] as String? ?? 'Plato',
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              '${p['veces']} visita(s) · '
                              '${p['frecuenciaPct']}% · '
                              'media ${p['qtyMedia']} ud',
                              style: const TextStyle(color: Colors.white54),
                            ),
                            trailing: Text(
                              '${p['unidades']}',
                              style: const TextStyle(
                                color: Color(0xFF00D9A5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 24),
                    const Text(
                      'Reservas recientes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (reservas.isEmpty)
                      const Text(
                        'Sin reservas registradas con ficha.',
                        style: TextStyle(color: Colors.white54),
                      )
                    else
                      ...reservas.map((raw) {
                        final r = Map<String, dynamic>.from(raw as Map);
                        final llegada = r['fechaHoraLlegada'] != null
                            ? fmt.format(
                                DateTime.parse(
                                  r['fechaHoraLlegada'] as String,
                                ).toLocal(),
                              )
                            : '—';
                        return Card(
                          color: const Color(0xFF16213E),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              llegada,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              '${r['estado']} · ${r['numeroPersonas']} pers.'
                              '${r['mesaAsignada'] != null ? ' · mesa ${r['mesaAsignada']}' : ''}',
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
    );
  }

  Widget _chip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3460),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
