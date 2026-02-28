import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';

/// Pantalla de Configuración del sistema
/// 
/// Permite ajustar configuraciones de red, impresora y datos
class ConfiguracionPage extends StatefulWidget {
  const ConfiguracionPage({super.key});

  @override
  State<ConfiguracionPage> createState() => _ConfiguracionPageState();
}

class _ConfiguracionPageState extends State<ConfiguracionPage> {
  String? _serverUrl;
  bool _servidorActivo = false;

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  void _cargarConfiguracion() {
    _servidorActivo = isServer;
    _serverUrl = serverUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Contenido
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Sección de información del sistema
                  _buildSeccion(
                    titulo: 'Sistema',
                    icono: Icons.info_outline,
                    color: const Color(0xFF4FC3F7),
                    children: [
                      _buildInfoTile(
                        'Plataforma',
                        kIsWeb ? 'Web' : PlatformUtils.platformName,
                        Icons.devices,
                      ),
                      _buildInfoTile(
                        'Rol',
                        kIsWeb ? 'Cliente Web' : PlatformUtils.suggestedRole,
                        Icons.person_outline,
                      ),
                      _buildInfoTile(
                        'Versión',
                        AppConstants.appVersion,
                        Icons.tag,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Sección de red
                  _buildSeccion(
                    titulo: 'Conectividad',
                    icono: Icons.wifi,
                    color: const Color(0xFF00D9A5),
                    children: [
                      _buildInfoTile(
                        'Modo',
                        _servidorActivo ? 'Servidor' : 'Cliente',
                        _servidorActivo ? Icons.dns : Icons.phone_android,
                      ),
                      if (_serverUrl != null)
                        _buildInfoTile(
                          _servidorActivo ? 'URL del Servidor' : 'Conectado a',
                          _serverUrl!,
                          Icons.link,
                          copyable: true,
                        ),
                      if (_servidorActivo)
                        _buildAccionTile(
                          'Estado del servidor',
                          'Activo',
                          Icons.power_settings_new,
                          color: const Color(0xFF00D9A5),
                        ),
                      if (kIsWeb)
                        _buildAccionTile(
                          'Modo Web',
                          'Conectando vía API al servidor',
                          Icons.cloud,
                          color: const Color(0xFF4FC3F7),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Sección de destinos de impresión
                  _buildSeccion(
                    titulo: 'Destinos de Impresión',
                    icono: Icons.send,
                    color: const Color(0xFF9C27B0),
                    children: [
                      _buildAccionTile(
                        'Gestionar Destinos',
                        'Cocina, Barra, Impresoras...',
                        Icons.alt_route,
                        onTap: () => context.push(AppRoutes.destinos),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Sección de impresión (solo en desktop)
                  if (!kIsWeb)
                    _buildSeccion(
                      titulo: 'Impresión',
                      icono: Icons.print,
                      color: const Color(0xFFFFB74D),
                      children: [
                        _buildAccionTile(
                          'Impresora',
                          'No configurada',
                          Icons.print_disabled,
                          onTap: _configurarImpresora,
                        ),
                        _buildAccionTile(
                          'Prueba de impresión',
                          'Enviar ticket de prueba',
                          Icons.receipt_long,
                          onTap: _pruebaImpresion,
                        ),
                      ],
                    ),
                  
                  if (!kIsWeb) const SizedBox(height: 24),
                  
                  // Sección de datos (solo en servidor/desktop)
                  if (!kIsWeb && _servidorActivo)
                    _buildSeccion(
                      titulo: 'Base de Datos',
                      icono: Icons.storage,
                      color: const Color(0xFFE94560),
                      children: [
                        _buildAccionTile(
                          'Productos',
                          'Gestionar menú y disponibilidad',
                          Icons.restaurant_menu,
                          onTap: () => context.push(AppRoutes.gestionProductos),
                        ),
                        _buildAccionTile(
                          'Mesas',
                          'Añadir, editar o eliminar mesas',
                          Icons.table_restaurant,
                          onTap: () => context.push(AppRoutes.gestionMesas),
                        ),
                        _buildAccionTile(
                          'Categorías',
                          'Modificar, añadir o eliminar categorías del menú',
                          Icons.category,
                          onTap: () => context.push(AppRoutes.gestionCategorias),
                        ),
                        _buildAccionTile(
                          'Limpiar datos',
                          'Eliminar todos los datos',
                          Icons.delete_forever,
                          color: Colors.red,
                          onTap: _confirmarLimpiarDatos,
                        ),
                      ],
                    ),
                  
                  if (!kIsWeb && _servidorActivo) const SizedBox(height: 24),
                  
                  // Sección del buffet
                  _buildSeccion(
                    titulo: 'Buffet del Sábado',
                    icono: Icons.star,
                    color: const Color(0xFFFFD700),
                    children: [
                      _buildAccionTile(
                        'Configurar Buffet',
                        'Horarios, precios y reglas del All You Can Eat',
                        Icons.restaurant_menu,
                        onTap: () => context.push(AppRoutes.buffetConfig),
                      ),
                      _buildAccionTile(
                        'Regenerar direcciones QR',
                        'Nuevas URLs para todas las mesas. Los QR antiguos dejarán de funcionar',
                        Icons.qr_code_2,
                        color: const Color(0xFF00D9A5),
                        onTap: _confirmarRegenerarUrlsQr,
                      ),
                      _buildInfoTile(
                        'Hoy es día de buffet',
                        DateTime.now().weekday == DateTime.saturday ? 'Sí ⭐' : 'No',
                        DateTime.now().weekday == DateTime.saturday
                            ? Icons.check_circle
                            : Icons.cancel,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE94560).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.settings,
              color: Color(0xFFE94560),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'CONFIGURACIÓN',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccion({
    required String titulo,
    required IconData icono,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de sección
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Icon(icono, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  titulo.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          
          // Contenido
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    String titulo,
    String valor,
    IconData icono, {
    bool copyable = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF0F3460),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(icono, color: Colors.white54, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (copyable)
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.white54, size: 20),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('URL copiada al portapapeles'),
                    backgroundColor: Color(0xFF00D9A5),
                  ),
                );
              },
              tooltip: 'Copiar',
            ),
        ],
      ),
    );
  }

  Widget _buildAccionTile(
    String titulo,
    String subtitulo,
    IconData icono, {
    Color? color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Color(0xFF0F3460),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icono,
                color: color ?? Colors.white54,
                size: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        color: color ?? Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: color?.withValues(alpha: 0.7) ?? Colors.white38,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarRegenerarUrlsQr() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_2, color: Color(0xFF00D9A5), size: 28),
            SizedBox(width: 12),
            Text(
              'Regenerar URLs QR',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          'Se generarán nuevas direcciones para todas las mesas. '
          'Los QR que tengas impresos o guardados dejarán de funcionar.\n\n'
          '¿Continuar?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D9A5)),
            child: const Text('Regenerar', style: TextStyle(color: Color(0xFF1A1A2E))),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await DatabaseService.instance.regenerarQrTokens();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Direcciones QR regeneradas. Los QR antiguos ya no funcionarán.'),
            backgroundColor: Color(0xFF00D9A5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _configurarImpresora() {
    context.push(AppRoutes.configuracionImpresora);
  }

  void _pruebaImpresion() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Prueba de impresión - Próximamente'),
        backgroundColor: Color(0xFFFFB74D),
      ),
    );
  }

  void _confirmarLimpiarDatos() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text(
              '¿Eliminar datos?',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          'Esta acción eliminará todos los pedidos, productos y mesas. '
          'No se puede deshacer.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función disponible solo en servidor'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
