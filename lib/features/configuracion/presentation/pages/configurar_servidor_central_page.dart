import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';

/// Configuración protegida de la URL del servidor central de reservas 24/7.
class ConfigurarServidorCentralPage extends StatefulWidget {
  const ConfigurarServidorCentralPage({super.key});

  @override
  State<ConfigurarServidorCentralPage> createState() =>
      _ConfigurarServidorCentralPageState();
}

class _ConfigurarServidorCentralPageState
    extends State<ConfigurarServidorCentralPage> {
  final _formKey = GlobalKey<FormState>();
  final _urlCtrl = TextEditingController();
  bool _cargando = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarUrl();
  }

  Future<void> _cargarUrl() async {
    final url = await getReservasCentralUrl();
    if (!mounted) return;
    if (url != null && url.isNotEmpty) {
      _urlCtrl.text = url;
    }
    setState(() => _cargando = false);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    var url = _urlCtrl.text.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }

    setState(() => _guardando = true);
    try {
      await saveReservasCentralUrl(url);
      await ReservaVpsPollingService.instance.refrescarAhora();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL del servidor central guardada correctamente'),
          backgroundColor: Color(0xFF00D9A5),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Servidor central de reservas'),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF00D9A5)),
              )
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.cloud_sync,
                        size: 64,
                        color: Color(0xFF4FC3F7),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'URL del servidor central',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Nodo remoto de reservas 24/7 (p. ej. VPS o Lightning en casa). '
                        'No compartas esta dirección con el personal operativo.',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _urlCtrl,
                        decoration: const InputDecoration(
                          labelText: 'IP / URL del servidor',
                          hintText: 'http://192.168.1.X:8080',
                          prefixIcon: Icon(
                            Icons.link,
                            color: Color(0xFF00D9A5),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Introduce la URL del servidor';
                          }
                          return null;
                        },
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _guardando ? null : _guardar,
                        icon: _guardando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          _guardando ? 'Guardando...' : 'Guardar URL',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF00D9A5),
                          foregroundColor: const Color(0xFF1A1A2E),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
