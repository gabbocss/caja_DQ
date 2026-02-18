import 'package:flutter/material.dart';

import '../../../../core/core.dart';

/// Configuración de cómo se imprimen los tickets (papel térmico 80mm).
class ConfiguracionImpresoraPage extends StatefulWidget {
  const ConfiguracionImpresoraPage({super.key});

  @override
  State<ConfiguracionImpresoraPage> createState() => _ConfiguracionImpresoraPageState();
}

class _ConfiguracionImpresoraPageState extends State<ConfiguracionImpresoraPage> {
  final _formKey = GlobalKey<FormState>();
  bool _cargando = true;
  bool _guardando = false;

  late TextEditingController _textoCabeceraController;
  late TextEditingController _textoPieController;
  late TextEditingController _caracterSeparadorController;
  late TextEditingController _margenIzqController;
  late TextEditingController _margenSupController;
  late TextEditingController _margenInfController;
  late TextEditingController _escalaAnchoCabeceraController;
  late TextEditingController _escalaAltoCabeceraController;
  late TextEditingController _escalaAnchoCuerpoController;
  late TextEditingController _escalaAltoCuerpoController;

  String _modoTamanio = 'presets';
  String _tamanioCabecera = 'normal';
  String _tamanioCuerpo = 'normal';
  bool _negritaCabecera = true;
  bool _negritaCuerpo = false;
  int _anchoCaracteres = 48;
  String _tipoCorte = 'completo';
  bool _mostrarFechaHora = true;

  @override
  void initState() {
    super.initState();
    _textoCabeceraController = TextEditingController();
    _textoPieController = TextEditingController();
    _caracterSeparadorController = TextEditingController(text: '=');
    _margenIzqController = TextEditingController(text: '2');
    _margenSupController = TextEditingController(text: '0');
    _margenInfController = TextEditingController(text: '1');
    _escalaAnchoCabeceraController = TextEditingController(text: '2');
    _escalaAltoCabeceraController = TextEditingController(text: '2');
    _escalaAnchoCuerpoController = TextEditingController(text: '1');
    _escalaAltoCuerpoController = TextEditingController(text: '1');
    _cargar();
  }

  @override
  void dispose() {
    _textoCabeceraController.dispose();
    _textoPieController.dispose();
    _caracterSeparadorController.dispose();
    _margenIzqController.dispose();
    _margenSupController.dispose();
    _margenInfController.dispose();
    _escalaAnchoCabeceraController.dispose();
    _escalaAltoCabeceraController.dispose();
    _escalaAnchoCuerpoController.dispose();
    _escalaAltoCuerpoController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final config = await ConfiguracionImpresionService.instance.cargar();
      _modoTamanio = config.modoTamanio;
      _tamanioCabecera = config.tamanioCabecera;
      _tamanioCuerpo = config.tamanioCuerpo;
      _escalaAnchoCabeceraController.text = config.escalaAnchoCabecera.toString();
      _escalaAltoCabeceraController.text = config.escalaAltoCabecera.toString();
      _escalaAnchoCuerpoController.text = config.escalaAnchoCuerpo.toString();
      _escalaAltoCuerpoController.text = config.escalaAltoCuerpo.toString();
      _negritaCabecera = config.negritaCabecera;
      _negritaCuerpo = config.negritaCuerpo;
      _anchoCaracteres = config.anchoCaracteres;
      _tipoCorte = config.tipoCorte;
      _mostrarFechaHora = config.mostrarFechaHora;
      _textoCabeceraController.text = config.textoCabecera ?? '';
      _textoPieController.text = config.textoPie ?? '';
      _caracterSeparadorController.text = config.caracterSeparador;
      _margenIzqController.text = config.margenIzquierdoMm.toString();
      _margenSupController.text = config.margenSuperiorLineas.toString();
      _margenInfController.text = config.margenInferiorLineas.toString();
    } finally {
      setState(() => _cargando = false);
    }
  }

  int _parseEscala(String s, int def) {
    final n = int.tryParse(s.trim());
    if (n == null || n < 1 || n > 8) return def;
    return n;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final config = ConfiguracionImpresion(
        modoTamanio: _modoTamanio,
        tamanioCabecera: _tamanioCabecera,
        tamanioCuerpo: _tamanioCuerpo,
        escalaAnchoCabecera: _parseEscala(_escalaAnchoCabeceraController.text, 2),
        escalaAltoCabecera: _parseEscala(_escalaAltoCabeceraController.text, 2),
        escalaAnchoCuerpo: _parseEscala(_escalaAnchoCuerpoController.text, 1),
        escalaAltoCuerpo: _parseEscala(_escalaAltoCuerpoController.text, 1),
        negritaCabecera: _negritaCabecera,
        negritaCuerpo: _negritaCuerpo,
        margenIzquierdoMm: int.tryParse(_margenIzqController.text) ?? 2,
        margenSuperiorLineas: int.tryParse(_margenSupController.text) ?? 0,
        margenInferiorLineas: int.tryParse(_margenInfController.text) ?? 1,
        textoCabecera: _textoCabeceraController.text.isEmpty ? null : _textoCabeceraController.text.trim(),
        textoPie: _textoPieController.text.isEmpty ? null : _textoPieController.text.trim(),
        caracterSeparador: _caracterSeparadorController.text.isEmpty ? '=' : _caracterSeparadorController.text.substring(0, 1),
        mostrarFechaHora: _mostrarFechaHora,
        anchoCaracteres: _anchoCaracteres,
        tipoCorte: _tipoCorte,
      );
      await ConfiguracionImpresionService.instance.guardar(config);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración de impresora guardada'),
            backgroundColor: Color(0xFF00D9A5),
          ),
        );
      }
    } finally {
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('CONFIGURACIÓN IMPRESORA'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D9A5)))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSeccion('Tipografía', Icons.text_fields, [
                    _dropdown('Método de tamaño', _modoTamanio, ConfiguracionImpresion.opcionesModoTamanio, (v) => setState(() => _modoTamanio = v!), const ['Presets (ESC !, compatible)', 'Numérico 1-8 (GS !)']),
                    const SizedBox(height: 12),
                    if (_modoTamanio == 'presets') ...[
                      _dropdown('Tamaño cabecera (MESA, Ticket #)', _tamanioCabecera, ConfiguracionImpresion.opcionesTamanioCabecera, (v) => setState(() => _tamanioCabecera = v!), const ['Normal', 'Doble altura', 'Doble ancho', 'Doble ambos']),
                      const SizedBox(height: 12),
                      _dropdown('Tamaño cuerpo (ítems)', _tamanioCuerpo, ConfiguracionImpresion.opcionesTamanioCuerpo, (v) => setState(() => _tamanioCuerpo = v!), const ['Pequeño (condensado)', 'Normal', 'Grande (doble altura)']),
                    ] else ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text('Escala 1-8 (ancho × alto). Usa solo si tu impresora soporta GS !', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Cabecera', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(child: _campoEscala(_escalaAnchoCabeceraController, 'Ancho')),
                                    const SizedBox(width: 8),
                                    Expanded(child: _campoEscala(_escalaAltoCabeceraController, 'Alto')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Cuerpo', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(child: _campoEscala(_escalaAnchoCuerpoController, 'Ancho')),
                                    const SizedBox(width: 8),
                                    Expanded(child: _campoEscala(_escalaAltoCuerpoController, 'Alto')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Negrita cabecera', style: TextStyle(color: Colors.white)),
                      value: _negritaCabecera,
                      onChanged: (v) => setState(() => _negritaCabecera = v),
                      activeColor: const Color(0xFF00D9A5),
                    ),
                    SwitchListTile(
                      title: const Text('Negrita cuerpo', style: TextStyle(color: Colors.white)),
                      value: _negritaCuerpo,
                      onChanged: (v) => setState(() => _negritaCuerpo = v),
                      activeColor: const Color(0xFF00D9A5),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSeccion('Márgenes', Icons.margin, [
                    TextFormField(
                      controller: _margenIzqController,
                      decoration: const InputDecoration(
                        labelText: 'Margen izquierdo (mm)',
                        hintText: '0-10',
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 0 || n > 10) return 'Entre 0 y 10';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _margenSupController,
                      decoration: const InputDecoration(
                        labelText: 'Líneas en blanco al inicio',
                        hintText: '0-5',
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 0 || n > 10) return 'Entre 0 y 10';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _margenInfController,
                      decoration: const InputDecoration(
                        labelText: 'Líneas en blanco antes del corte',
                        hintText: '1-5',
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 0 || n > 10) return 'Entre 0 y 10';
                        return null;
                      },
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSeccion('Contenido', Icons.receipt_long, [
                    TextFormField(
                      controller: _textoCabeceraController,
                      decoration: const InputDecoration(
                        labelText: 'Texto cabecera (opcional)',
                        hintText: 'Ej: Nombre del restaurante',
                      ),
                      style: const TextStyle(color: Colors.white),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _textoPieController,
                      decoration: const InputDecoration(
                        labelText: 'Texto pie (opcional)',
                        hintText: 'Ej: Gracias por su visita',
                      ),
                      style: const TextStyle(color: Colors.white),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _caracterSeparadorController,
                      decoration: const InputDecoration(
                        labelText: 'Carácter separador',
                        hintText: '=, -, *',
                      ),
                      style: const TextStyle(color: Colors.white),
                      maxLength: 1,
                    ),
                    SwitchListTile(
                      title: const Text('Mostrar fecha y hora', style: TextStyle(color: Colors.white)),
                      value: _mostrarFechaHora,
                      onChanged: (v) => setState(() => _mostrarFechaHora = v),
                      activeColor: const Color(0xFF00D9A5),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSeccion('Papel (80mm)', Icons.straighten, [
                    _dropdown('Ancho en caracteres', _anchoCaracteres.toString(), ConfiguracionImpresion.opcionesAnchoCaracteres.map((e) => e.toString()).toList(), (v) => setState(() => _anchoCaracteres = int.parse(v!)), const ['32', '42', '48']),
                    const SizedBox(height: 12),
                    _dropdown('Tipo de corte', _tipoCorte, ConfiguracionImpresion.opcionesTipoCorte, (v) => setState(() => _tipoCorte = v!), const ['Completo', 'Parcial', 'Ninguno']),
                  ]),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _guardando ? null : _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D9A5),
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _guardando
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87),
                            )
                          : const Text('GUARDAR CONFIGURACIÓN', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _campoEscala(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: '1-8',
        isDense: true,
      ),
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.number,
      validator: (v) {
        final n = int.tryParse(v ?? '');
        if (n == null || n < 1 || n > 8) return '1-8';
        return null;
      },
    );
  }

  Widget _buildSeccion(String titulo, IconData icono, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0F3460)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: const Color(0xFFFFB74D), size: 22),
              const SizedBox(width: 10),
              Text(
                titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> options, ValueChanged<String?> onChanged, List<String> labels) {
    return DropdownButtonFormField<String>(
      value: options.contains(value) ? value : options.first,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
      ),
      dropdownColor: const Color(0xFF16213E),
      style: const TextStyle(color: Colors.white),
      items: List.generate(options.length, (i) {
        return DropdownMenuItem(value: options[i], child: Text(labels.length > i ? labels[i] : options[i]));
      }),
      onChanged: onChanged,
    );
  }
}
