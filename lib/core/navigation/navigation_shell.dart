import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utils/platform_utils.dart';
import '../network/local_server_web.dart' if (dart.library.io) '../network/local_server.dart';
import 'app_router.dart';

/// Shell de navegación con barra lateral/inferior
/// 
/// En móvil: Mesas, Menús, WiFi. En escritorio: Pedidos, Reservas, Cocina, etc.
/// Usa NavigationRail en pantallas grandes y BottomNavigation en móviles.
class NavigationShell extends StatefulWidget {
  final Widget child;

  const NavigationShell({
    super.key,
    required this.child,
  });

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  /// En escritorio: rail extendido (etiquetas) vs compacto (solo iconos).
  bool _railExtended = true;
  bool _railPreferenceInitialized = false;

  bool get _isMobileFlow => PlatformUtils.isMobile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Valor inicial según el ancho; luego lo controla el botón del usuario.
    if (!_railPreferenceInitialized) {
      _railExtended = MediaQuery.of(context).size.width > 1200;
      _railPreferenceInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _getSelectedIndex(location);
    final isWideScreen = MediaQuery.of(context).size.width > 800;
    final showServerUrl = !PlatformUtils.isMobile &&
        LocalServer.instance.isRunning &&
        LocalServer.instance.serverUrl != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          isWideScreen
              ? Row(
                  children: [
                    _buildNavigationRail(context, selectedIndex),
                    Expanded(child: widget.child),
                  ],
                )
              : widget.child,
          if (showServerUrl)
            _ServerUrlBadge(
              url: LocalServer.instance.serverUrl!,
              // Si hay barra inferior, dejar margen para que el badge no quede tapado
              bottom: isWideScreen ? 12.0 : 72.0,
            ),
        ],
      ),
      bottomNavigationBar: isWideScreen
          ? null
          : _buildBottomNavigation(context, selectedIndex),
    );
  }

  int _getSelectedIndex(String location) {
    if (location.startsWith(AppRoutes.cocina)) return _isWebFlow ? 0 : 2;
    if (_isMobileFlow) {
      if (location.startsWith(AppRoutes.menus) ||
          location.startsWith(AppRoutes.reservas) ||
          location.startsWith(AppRoutes.listaCompra) ||
          location.startsWith(AppRoutes.configurarConexion)) {
        return 1;
      }
      if (location.startsWith(AppRoutes.wifiQr)) return 2;
      return 0;
    }
    if (location.startsWith(AppRoutes.reservas)) return 1;
    if (location.startsWith(AppRoutes.configuracion)) return _isWebFlow ? 1 : 3;
    if (location.startsWith(AppRoutes.wifiQr)) return 4;
    if (location.startsWith(AppRoutes.estadisticas)) return 5;
    if (location.startsWith(AppRoutes.caja)) return 6;
    return _isWebFlow ? 0 : 0;
  }

  /// En web solo mostramos Cocina y Config (no hay Pedidos ni DB local).
  bool get _isWebFlow => kIsWeb;

  void _onDestinationSelected(BuildContext context, int index) {
    if (_isMobileFlow) {
      switch (index) {
        case 0:
          context.go(AppRoutes.mesas);
          break;
        case 1:
          context.go(AppRoutes.menus);
          break;
        case 2:
          context.go(AppRoutes.wifiQr);
          break;
      }
      return;
    }
    if (_isWebFlow) {
      switch (index) {
        case 0:
          context.go(AppRoutes.cocina);
          break;
        case 1:
          context.go(AppRoutes.configuracion);
          break;
      }
      return;
    }
    switch (index) {
      case 0:
        context.go(AppRoutes.pedidos);
        break;
      case 1:
        context.go(AppRoutes.reservas);
        break;
      case 2:
        context.go(AppRoutes.cocina);
        break;
      case 3:
        context.go(AppRoutes.configuracion);
        break;
      case 4:
        context.go(AppRoutes.wifiQr);
        break;
      case 5:
        context.go(AppRoutes.estadisticas);
        break;
      case 6:
        context.go(AppRoutes.caja);
        break;
    }
  }

  Widget _buildNavigationRail(BuildContext context, int selectedIndex) {
    final destinations = _isMobileFlow
        ? const [
            NavigationRailDestination(
              icon: Icon(Icons.table_restaurant_outlined),
              selectedIcon: Icon(Icons.table_restaurant),
              label: Text('Mesas'),
              padding: EdgeInsets.symmetric(vertical: 8),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.menu_outlined),
              selectedIcon: Icon(Icons.menu),
              label: Text('Menús'),
              padding: EdgeInsets.symmetric(vertical: 8),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.wifi_outlined),
              selectedIcon: Icon(Icons.wifi),
              label: Text('WiFi'),
              padding: EdgeInsets.symmetric(vertical: 8),
            ),
          ]
        : _isWebFlow
            ? const [
                NavigationRailDestination(
                  icon: Icon(Icons.restaurant_outlined),
                  selectedIcon: Icon(Icons.restaurant),
                  label: Text('Cocina'),
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Config'),
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
              ]
            : const [
                NavigationRailDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: Text('Pedidos'),
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.event_seat_outlined),
                  selectedIcon: Icon(Icons.event_seat),
                  label: Text('Reservas'),
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.restaurant_outlined),
                  selectedIcon: Icon(Icons.restaurant),
                  label: Text('Cocina'),
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Config'),
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.wifi_outlined),
                  selectedIcon: Icon(Icons.wifi),
                  label: Text('WiFi'),
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart),
                  label: Text('Estadísticas'),
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.point_of_sale_outlined),
                  selectedIcon: Icon(Icons.point_of_sale),
                  label: Text('Caja'),
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
              ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(5, 0),
          ),
        ],
      ),
      child: NavigationRail(
        selectedIndex: selectedIndex.clamp(0, destinations.length - 1),
        onDestinationSelected: (index) => _onDestinationSelected(context, index),
        backgroundColor: Colors.transparent,
        extended: _railExtended,
        minWidth: 80,
        minExtendedWidth: 200,
        // Extendido: etiquetas al lado. Compacto: solo iconos.
        labelType: NavigationRailLabelType.none,
        indicatorColor: const Color(0xFFE94560).withValues(alpha: 0.2),
        selectedIconTheme: const IconThemeData(
          color: Color(0xFFE94560),
          size: 28,
        ),
        unselectedIconTheme: const IconThemeData(
          color: Colors.white54,
          size: 24,
        ),
        selectedLabelTextStyle: const TextStyle(
          color: Color(0xFFE94560),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: Colors.white54,
          fontSize: 13,
        ),
        leading: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: _buildLogo(_railExtended),
        ),
        destinations: destinations,
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, int selectedIndex) {
    final maxIndex = _isMobileFlow ? 2 : (_isWebFlow ? 1 : 6);
    final safeIndex = selectedIndex.clamp(0, maxIndex);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _isMobileFlow
                ? [
                    Expanded(child: _buildNavItem(context, index: 0, selectedIndex: safeIndex, icon: Icons.table_restaurant_outlined, selectedIcon: Icons.table_restaurant, label: 'Mesas')),
                    Expanded(child: _buildNavItem(context, index: 1, selectedIndex: safeIndex, icon: Icons.menu_outlined, selectedIcon: Icons.menu, label: 'Menús')),
                    Expanded(child: _buildNavItem(context, index: 2, selectedIndex: safeIndex, icon: Icons.wifi_outlined, selectedIcon: Icons.wifi, label: 'WiFi')),
                  ]
                : _isWebFlow
                    ? [
                        _buildNavItem(context, index: 0, selectedIndex: safeIndex, icon: Icons.restaurant_outlined, selectedIcon: Icons.restaurant, label: 'Cocina'),
                        _buildNavItem(context, index: 1, selectedIndex: safeIndex, icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Config'),
                      ]
                    : [
                        _buildNavItem(context, index: 0, selectedIndex: safeIndex, icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, label: 'Pedidos'),
                        _buildNavItem(context, index: 1, selectedIndex: safeIndex, icon: Icons.event_seat_outlined, selectedIcon: Icons.event_seat, label: 'Reservas'),
                        _buildNavItem(context, index: 2, selectedIndex: safeIndex, icon: Icons.restaurant_outlined, selectedIcon: Icons.restaurant, label: 'Cocina'),
                        _buildNavItem(context, index: 3, selectedIndex: safeIndex, icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Config'),
                        _buildNavItem(context, index: 4, selectedIndex: safeIndex, icon: Icons.wifi_outlined, selectedIcon: Icons.wifi, label: 'WiFi'),
                        _buildNavItem(context, index: 5, selectedIndex: safeIndex, icon: Icons.bar_chart_outlined, selectedIcon: Icons.bar_chart, label: 'Estadísticas'),
                        _buildNavItem(context, index: 6, selectedIndex: safeIndex, icon: Icons.point_of_sale_outlined, selectedIcon: Icons.point_of_sale, label: 'Caja'),
                      ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required int selectedIndex,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final isSelected = selectedIndex == index;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onDestinationSelected(context, index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: _isMobileFlow ? 7 : 18,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFE94560).withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? const Color(0xFFE94560) : Colors.white54,
                size: 25,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFFE94560) : Colors.white54,
                  fontSize: _isMobileFlow ? 10 : 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(bool extended) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE94560), Color(0xFFFF6B6B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE94560).withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.restaurant_menu,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        IconButton(
          tooltip: extended ? 'Compactar menú' : 'Desplegar menú',
          onPressed: () => setState(() => _railExtended = !_railExtended),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: const Text(
            '<>',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
        ),
        if (extended) ...[
          const SizedBox(height: 8),
          const Text(
            'SISTEMA',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 2,
            ),
          ),
          const Text(
            'RESTAURANTE',
            style: TextStyle(
              color: Color(0xFFE94560),
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ],
        const SizedBox(height: 20),
        Container(
          height: 1,
          width: extended ? 160 : 50,
          color: const Color(0xFF0F3460),
        ),
      ],
    );
  }
}

/// Badge abajo a la izquierda: icono cuadrado; al pulsar se expande y muestra la URL.
class _ServerUrlBadge extends StatefulWidget {
  final String url;
  final double bottom;

  const _ServerUrlBadge({
    required this.url,
    required this.bottom,
  });

  @override
  State<_ServerUrlBadge> createState() => _ServerUrlBadgeState();
}

class _ServerUrlBadgeState extends State<_ServerUrlBadge> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12,
      bottom: widget.bottom,
      child: Material(
        color: const Color(0xFF0F3460),
        borderRadius: BorderRadius.circular(8),
        elevation: 4,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.centerLeft,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Conectar la app a:',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11,
                            ),
                          ),
                          SelectableText(
                            widget.url,
                            style: const TextStyle(
                              color: Color(0xFF00D9A5),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => setState(() => _expanded = false),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : InkWell(
                  onTap: () => setState(() => _expanded = true),
                  borderRadius: BorderRadius.circular(8),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.link,
                      color: Color(0xFF00D9A5),
                      size: 20,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
