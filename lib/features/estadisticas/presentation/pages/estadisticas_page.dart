import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/core.dart';
import '../../data/estadisticas_service.dart';
import '../utils/estadisticas_pdf_export.dart';

/// Pantalla de estadísticas: platos más pedidos y tiempos de preparación (Empezar → Listo).
/// Acceso desde menú servidor, debajo de WiFi. Exportación a PDF con gráficos.
class EstadisticasPage extends StatefulWidget {
  const EstadisticasPage({super.key});

  @override
  State<EstadisticasPage> createState() => _EstadisticasPageState();
}

class _EstadisticasPageState extends State<EstadisticasPage> {
  DateTime _desde = DateTime.now().subtract(const Duration(days: 30));
  DateTime _hasta = DateTime.now();
  String? _categoria;
  List<String> _categorias = [];
  List<PlatoMasPedido> _platos = [];
  List<TiempoMedioPlato> _tiemposPlato = [];
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
    _cargarDatos();
  }

  Future<void> _cargarCategorias() async {
    try {
      final list = await EstadisticasService.obtenerCategoriasDisponibles();
      if (mounted) setState(() => _categorias = list);
    } catch (_) {}
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final platos = await EstadisticasService.obtenerPlatosMasPedidos(
        desde: _desde,
        hasta: _hasta,
        categoria: _categoria,
      );
      final tiemposPlato = await EstadisticasService.obtenerTiemposMediosPorPlato(
        desde: _desde,
        hasta: _hasta,
      );
      if (mounted) {
        setState(() {
          _platos = platos;
          _tiemposPlato = tiemposPlato;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _cargando = false;
        });
      }
    }
  }

  double get _tiempoMedioGeneralMinutos {
    if (_tiemposPlato.isEmpty) return 0;
    final totalMin = _tiemposPlato.fold<double>(0, (s, t) => s + t.tiempoMedioMinutos * t.cantidadRegistros);
    final totalReg = _tiemposPlato.fold<int>(0, (s, t) => s + t.cantidadRegistros);
    return totalReg > 0 ? totalMin / totalReg : 0;
  }

  Future<void> _exportarPdf() async {
    // Muestra progreso mientras se genera el PDF (evita el diálogo de impresión del SO).
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFFE94560)),
                SizedBox(height: 16),
                Text('Generando PDF…'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final ruta = await EstadisticasPdfExport.exportar(
        desde: _desde,
        hasta: _hasta,
        categoria: _categoria,
        platos: _platos,
        tiemposPlato: _tiemposPlato,
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      final messenger = ScaffoldMessenger.of(context);
      if (ruta == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Exportación cancelada')),
        );
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('PDF guardado:\n$ruta'),
          duration: const Duration(seconds: 5),
          backgroundColor: const Color(0xFF00A878),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar PDF: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
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
            Icon(Icons.bar_chart, color: Color(0xFFE94560)),
            SizedBox(width: 12),
            Text('ESTADÍSTICAS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.push(AppRoutes.prediccion),
            icon: const Icon(Icons.insights, color: Color(0xFFFFB74D)),
            label: const Text(
              'Previsión',
              style: TextStyle(color: Color(0xFFFFB74D)),
            ),
          ),
          IconButton(
            onPressed: _cargando ? null : () => _exportarPdf(),
            icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF00D9A5)),
            tooltip: 'Exportar PDF',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFiltros(),
          if (_error != null) _buildError(),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildTarjetaPrevision(),
                      const SizedBox(height: 24),
                      _buildSeccionPlatos(),
                      const SizedBox(height: 24),
                      _buildSeccionTiempos(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaPrevision() {
    return Card(
      color: const Color(0xFF0F3460),
      child: InkWell(
        onTap: () => context.push(AppRoutes.prediccion),
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.insights, color: Color(0xFFFFB74D), size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Previsión del día',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Demanda esperada por plato: histórico + reservas + clientes habituales',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    final fmt = DateFormat('dd/MM/yyyy');
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF16213E),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _desde,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (d != null && mounted) setState(() { _desde = d; _cargarDatos(); });
            },
            icon: const Icon(Icons.calendar_today, color: Color(0xFF00D9A5), size: 20),
            label: Text(fmt.format(_desde), style: const TextStyle(color: Colors.white70)),
          ),
          const Text(' — ', style: TextStyle(color: Colors.white54)),
          TextButton.icon(
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _hasta,
                firstDate: _desde,
                lastDate: DateTime.now(),
              );
              if (d != null && mounted) setState(() { _hasta = d; _cargarDatos(); });
            },
            icon: const Icon(Icons.calendar_today, color: Color(0xFF00D9A5), size: 20),
            label: Text(fmt.format(_hasta), style: const TextStyle(color: Colors.white70)),
          ),
          const SizedBox(width: 24),
          DropdownButton<String>(
            value: _categoria,
            hint: const Text('Todas las categorías', style: TextStyle(color: Colors.white54)),
            dropdownColor: const Color(0xFF16213E),
            style: const TextStyle(color: Colors.white),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todas las categorías')),
              ..._categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))),
            ],
            onChanged: (v) {
              setState(() { _categoria = v; _cargarDatos(); });
            },
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: _cargando ? null : () => _cargarDatos(),
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('Actualizar'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE94560)),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
    );
  }

  Widget _buildSeccionPlatos() {
    return Card(
      color: const Color(0xFF16213E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.restaurant, color: Color(0xFF00D9A5)),
                SizedBox(width: 8),
                Text('Platos más pedidos', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            if (_platos.isEmpty)
              const Text('Sin datos en el período seleccionado.', style: TextStyle(color: Colors.white54))
            else
              Column(
                children: _platos.take(15).toList().asMap().entries.map((e) {
                  final i = e.key;
                  final p = e.value;
                  final maxCant = _platos.isNotEmpty ? _platos.first.cantidadTotal.toDouble() : 1.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: Text('${i + 1}', style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.nombreProducto, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                              if (p.categoria != null && p.categoria!.isNotEmpty)
                                Text(p.categoria!, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text('${p.cantidadTotal}', style: const TextStyle(color: Color(0xFF00D9A5), fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 120,
                          height: 20,
                          child: LinearProgressIndicator(
                            value: maxCant > 0 ? p.cantidadTotal / maxCant : 0,
                            backgroundColor: const Color(0xFF0F3460),
                            valueColor: const AlwaysStoppedAnimation(Color(0xFF00D9A5)),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionTiempos() {
    return Card(
      color: const Color(0xFF16213E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.timer, color: Color(0xFFFFB74D)),
                SizedBox(width: 8),
                Text('Tiempo medio por plato (desde que empiezas hasta Hecho)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Platos con tiempo registrado: ${_tiemposPlato.fold<int>(0, (s, t) => s + t.cantidadRegistros)}. '
              'Tiempo medio general: ${_tiempoMedioGeneralMinutos.toStringAsFixed(1)} min.',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (_tiemposPlato.isEmpty)
              const Text(
                'Sin datos. Los tiempos se registran en cocina al marcar cada plato como "preparando" (checkbox o empezar) y luego "listo" (Hecho).',
                style: TextStyle(color: Colors.white54),
              )
            else
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                },
                border: TableBorder.all(color: Colors.white24),
                children: [
                  const TableRow(
                    decoration: BoxDecoration(color: Color(0xFF0F3460)),
                    children: [
                      Padding(padding: EdgeInsets.all(10), child: Text('Plato', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      Padding(padding: EdgeInsets.all(10), child: Text('Registros', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      Padding(padding: EdgeInsets.all(10), child: Text('Media (min)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ],
                  ),
                  ..._tiemposPlato.map((t) => TableRow(
                    children: [
                      Padding(padding: const EdgeInsets.all(10), child: Text(t.nombreProducto, style: const TextStyle(color: Colors.white70))),
                      Padding(padding: const EdgeInsets.all(10), child: Text('${t.cantidadRegistros}', style: const TextStyle(color: Colors.white70))),
                      Padding(padding: const EdgeInsets.all(10), child: Text(t.tiempoMedioMinutos.toStringAsFixed(1), style: const TextStyle(color: Color(0xFFFFB74D)))),
                    ],
                  )),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
