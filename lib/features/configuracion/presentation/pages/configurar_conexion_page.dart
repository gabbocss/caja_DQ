import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../../core/services/reserva_carta_cache_service.dart';

/// Pantalla para configurar la URL del servidor (móvil, primera vez o cambio de red).
class ConfigurarConexionPage extends StatefulWidget {
  const ConfigurarConexionPage({super.key});

  @override
  State<ConfigurarConexionPage> createState() => _ConfigurarConexionPageState();
}

class _ConfigurarConexionPageState extends State<ConfigurarConexionPage> {
  final _cajaController = TextEditingController();
  final _vpsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _sincronizandoCaja = false;
  bool _sincronizandoVps = false;
  String? _error;

  static const _inputDecorationTheme = InputDecoration(
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    labelStyle: TextStyle(fontSize: 13),
    hintStyle: TextStyle(fontSize: 12),
  );

  @override
  void initState() {
    super.initState();
    _loadSavedUrls();
  }

  Future<void> _loadSavedUrls() async {
    final caja = await getSavedServerUrl();
    final vps = await getReservasCentralUrl();
    if (!mounted) return;
    if (caja != null && caja.isNotEmpty) {
      _cajaController.text = caja;
    }
    if (vps != null && vps.isNotEmpty) {
      _vpsController.text = vps;
    }
  }

  @override
  void dispose() {
    _cajaController.dispose();
    _vpsController.dispose();
    super.dispose();
  }

  String _normalizarUrl(String url) {
    var urlFinal = url.trim();
    if (!urlFinal.startsWith('http://') && !urlFinal.startsWith('https://')) {
      urlFinal = 'http://$urlFinal';
    }
    return urlFinal;
  }

  Future<void> _guardar() async {
    _error = null;
    if (!_formKey.currentState!.validate()) return;

    final urlCaja = _normalizarUrl(_cajaController.text);
    final urlVpsRaw = _vpsController.text.trim();
    final urlVps = urlVpsRaw.isEmpty ? null : _normalizarUrl(urlVpsRaw);

    setState(() => _loading = true);

    try {
      await saveServerUrl(urlCaja);
      if (urlVps != null) {
        await saveReservasCentralUrl(urlVps);
      }
      await registerApiClientWithUrl(urlCaja);
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

  /// Descarga el menú desde [url] y lo guarda en la caché local del móvil.
  /// No modifica la base de datos de la caja de escritorio.
  Future<void> _sincronizarMenuDesdeUrl({
    required String urlRaw,
    required String origenLabel,
    required void Function(bool) setSincronizando,
  }) async {
    final trimmed = urlRaw.trim();
    if (trimmed.isEmpty) {
      _mostrarSnack(
        'Introduce primero la URL de $origenLabel',
        error: true,
      );
      return;
    }

    final url = _normalizarUrl(trimmed);
    setSincronizando(true);
    ApiClient? client;
    try {
      client = ApiClient(url);
      if (!await client.verificarApiProgramaCaja()) {
        throw Exception(
          'La URL no responde con la API esperada (GET /api/productos).',
        );
      }
      final productos = await client.obtenerProductos();
      if (productos.isEmpty) {
        throw Exception('No se recibieron productos desde $origenLabel.');
      }
      await ReservaCartaCacheService.instance.guardar(productos);
      if (!mounted) return;
      _mostrarSnack(
        'Menú sincronizado desde $origenLabel (${productos.length} productos)',
      );
    } catch (e) {
      if (!mounted) return;
      _mostrarSnack('Error al sincronizar desde $origenLabel: $e', error: true);
    } finally {
      client?.dispose();
      if (mounted) setSincronizando(false);
    }
  }

  void _mostrarSnack(String mensaje, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: error ? Colors.red : const Color(0xFF00D9A5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _sincronizarDesdeCaja() async {
    await _sincronizarMenuDesdeUrl(
      urlRaw: _cajaController.text,
      origenLabel: 'la caja',
      setSincronizando: (v) => setState(() => _sincronizandoCaja = v),
    );
  }

  Future<void> _sincronizarDesdeVps() async {
    await _sincronizarMenuDesdeUrl(
      urlRaw: _vpsController.text,
      origenLabel: 'el servidor',
      setSincronizando: (v) => setState(() => _sincronizandoVps = v),
    );
  }

  Widget _buildCampoConSync({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    required Color prefixColor,
    required bool sincronizando,
    required VoidCallback onSync,
    String? Function(String?)? validator,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: _inputDecorationTheme.copyWith(
              labelText: labelText,
              hintText: hintText,
              prefixIcon: Icon(prefixIcon, color: prefixColor, size: 20),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            keyboardType: TextInputType.url,
            autocorrect: false,
            validator: validator,
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: (sincronizando || _loading) ? null : onSync,
          tooltip: 'Sincronizar menú',
          icon: sincronizando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF00D9A5),
                  ),
                )
              : const Icon(Icons.sync, color: Color(0xFF00D9A5)),
        ),
      ],
    );
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
                const SizedBox(height: 16),
                Icon(
                  Icons.wifi_find,
                  size: 64,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Servidores del restaurante',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'La caja local sirve mesas y pedidos. El VPS central guarda las reservas en la nube. '
                  'Usa el icono de sync para descargar el menú a este móvil.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                _buildCampoConSync(
                  controller: _cajaController,
                  labelText: 'URL de la caja (local)',
                  hintText: 'http://192.168.1.100:8080',
                  prefixIcon: Icons.computer,
                  prefixColor: const Color(0xFF00D9A5),
                  sincronizando: _sincronizandoCaja,
                  onSync: _sincronizarDesdeCaja,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Introduce la URL de la caja';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildCampoConSync(
                  controller: _vpsController,
                  labelText: 'URL servidor central / VPS (opcional)',
                  hintText: 'https://mi-vps.ejemplo:8888',
                  prefixIcon: Icons.cloud_outlined,
                  prefixColor: const Color(0xFFE94560),
                  sincronizando: _sincronizandoVps,
                  onSync: _sincronizarDesdeVps,
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
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
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
