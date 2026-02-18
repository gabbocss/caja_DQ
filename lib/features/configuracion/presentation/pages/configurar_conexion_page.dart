import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';

/// Pantalla para configurar la URL del servidor (móvil, primera vez o cambio de red).
class ConfigurarConexionPage extends StatefulWidget {
  const ConfigurarConexionPage({super.key});

  @override
  State<ConfigurarConexionPage> createState() => _ConfigurarConexionPageState();
}

class _ConfigurarConexionPageState extends State<ConfigurarConexionPage> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSavedUrl();
  }

  Future<void> _loadSavedUrl() async {
    final url = await getSavedServerUrl();
    if (url != null && url.isNotEmpty && mounted) {
      _controller.text = url;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    _error = null;
    if (!_formKey.currentState!.validate()) return;

    final url = _controller.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Introduce la URL del servidor');
      return;
    }

    // Asegurar que tenga protocolo
    String urlFinal = url;
    if (!urlFinal.startsWith('http://') && !urlFinal.startsWith('https://')) {
      urlFinal = 'http://$url';
    }

    setState(() => _loading = true);

    try {
      await saveServerUrl(urlFinal);
      await registerApiClientWithUrl(urlFinal);
      if (!mounted) return;
      context.go(AppRoutes.mesas);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Conectar al servidor'),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Icon(
                  Icons.wifi_find,
                  size: 64,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Introduce la dirección del servidor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'En el PC del restaurante, mira la URL que aparece abajo a la izquierda e introdúcela aquí.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: 'URL del servidor',
                    hintText: 'http://192.168.1.100:8080',
                    prefixIcon: Icon(Icons.link, color: Color(0xFF00D9A5)),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Introduce la URL';
                    }
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
                const Spacer(),
                FilledButton.icon(
                  onPressed: _loading ? null : _guardar,
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check),
                  label: Text(_loading ? 'Guardando...' : 'Guardar y conectar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00D9A5),
                    foregroundColor: Colors.black87,
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
