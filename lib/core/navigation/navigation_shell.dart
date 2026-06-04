import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utils/platform_utils.dart';
import '../network/local_server_web.dart' if (dart.library.io) '../network/local_server.dart';
import 'app_router.dart';

/// Shell de navegación con barra lateral/inferior
/// 
/// En móvil: Mesas, Reservas, Servidor, WiFi. En escritorio: Pedidos, Reservas, Cocina, etc.
/// Usa NavigationRail en pantallas grandes y BottomNavigation en móviles.
class NavigationShell extends StatelessWidget {
  final Widget child;

  const NavigationShell({
    super.key,
    required this.child,
  });

  bool get _isMobileFlow => PlatformUtils.isMobile;

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
                    Expanded(child: child),
                  ],
                )
              : child,
          if (showServerUrl) _buildServerUrlBadge(context),
        ],
      ),
      bottomNavigationBar: isWideScreen
          ? null
          : _buildBottomNavigation(context, selectedIndex),
    );
  }

  /// Badge abajo a la izquierda con la URL para conectar la app móvil
  Widget _buildServerUrlBadge(BuildContext context) {
    final url = LocalServer.instance.serverUrl!;
    final isWideScreen = MediaQuery.of(context).size.width > 800;
    // Si hay barra inferior, dejar margen para que el badge no quede tapado
    final bottom = isWideScreen ? 12.0 : 72.0;
    return Positioned(
      left: 12,
      bottom: bottom,
      child: Material(
        color: const Color(0xFF0F3460),
        borderRadius: BorderRadius.circular(8),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
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
                url,
                style: const TextStyle(
                  color: Color(0xFF00D9A5),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getSelectedIndex(String location) {
    if (location.startsWith(AppRoutes.cocina)) return _isWebFlow ? 0 : 2;
    if (_isMobileFlow) {
      if (location.startsWith(AppRoutes.reservas)) return 1;
      if (location.startsWith(AppRoutes.configurarConexion)) return 2;
      if (location.startsWith(AppRoutes.wifiQr)) return 3;
      return 0;
    }
    if (location.startsWith(AppRoutes.reservas)) return 1;
    if (location.startsWith(AppRoutes.configuracion)) return _isWebFlow ? 1 : 3;
    if (location.startsWith(AppRoutes.wifiQr)) return 4;
    if (location.startsWith(AppRoutes.estadisticas)) return 5;
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
          context.go(AppRoutes.reservas);
          break;
        case 2:
          context.go(AppRoutes.configurarConexion);
          break;
        case 3:
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
              icon: Icon(Icons.event_seat_outlined),
              selectedIcon: Icon(Icons.event_seat),
              label: Text('Reservas'),
              padding: EdgeInsets.symmetric(vertical: 8),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.dns_outlined),
              selectedIcon: Icon(Icons.dns),
              label: Text('Servidor'),
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
              ];

    return Container(
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
        extended: MediaQuery.of(context).size.width > 1200,
        minWidth: 80,
        minExtendedWidth: 200,
        labelType: MediaQuery.of(context).size.width > 1200
            ? NavigationRailLabelType.none
            : NavigationRailLabelType.all,
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
          child: _buildLogo(MediaQuery.of(context).size.width > 1200),
        ),
        destinations: destinations,
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, int selectedIndex) {
    final maxIndex = _isMobileFlow ? 3 : (_isWebFlow ? 1 : 5);
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _isMobileFlow
                ? [
                    Expanded(child: _buildNavItem(context, index: 0, selectedIndex: safeIndex, icon: Icons.table_restaurant_outlined, selectedIcon: Icons.table_restaurant, label: 'Mesas')),
                    Expanded(child: _buildNavItem(context, index: 1, selectedIndex: safeIndex, icon: Icons.event_seat_outlined, selectedIcon: Icons.event_seat, label: 'Reservas')),
                    Expanded(child: _buildNavItem(context, index: 2, selectedIndex: safeIndex, icon: Icons.dns_outlined, selectedIcon: Icons.dns, label: 'Servidor')),
                    Expanded(child: _buildNavItem(context, index: 3, selectedIndex: safeIndex, icon: Icons.wifi_outlined, selectedIcon: Icons.wifi, label: 'WiFi')),
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
            horizontal: _isMobileFlow ? 8 : 20,
            vertical: 12,
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
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFFE94560) : Colors.white54,
                  fontSize: _isMobileFlow ? 11 : 12,
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
        if (extended) ...[
          const SizedBox(height: 12),
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
