import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';

/// Shell de navegación con barra lateral/inferior
/// 
/// Usa NavigationRail en pantallas grandes y BottomNavigation en móviles
class NavigationShell extends StatelessWidget {
  final Widget child;

  const NavigationShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _getSelectedIndex(location);
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: isWideScreen
          ? Row(
              children: [
                // Navigation Rail para pantallas grandes
                _buildNavigationRail(context, selectedIndex),
                
                // Contenido principal
                Expanded(child: child),
              ],
            )
          : child,
      
      // Bottom Navigation para móviles
      bottomNavigationBar: isWideScreen
          ? null
          : _buildBottomNavigation(context, selectedIndex),
    );
  }

  int _getSelectedIndex(String location) {
    if (location.startsWith(AppRoutes.cocina)) return 1;
    if (location.startsWith(AppRoutes.configuracion)) return 2;
    return 0; // pedidos por defecto
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.pedidos);
        break;
      case 1:
        context.go(AppRoutes.cocina);
        break;
      case 2:
        context.go(AppRoutes.configuracion);
        break;
    }
  }

  Widget _buildNavigationRail(BuildContext context, int selectedIndex) {
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
        selectedIndex: selectedIndex,
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
        destinations: const [
          NavigationRailDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: Text('Pedidos'),
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
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, int selectedIndex) {
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
            children: [
              _buildNavItem(
                context,
                index: 0,
                selectedIndex: selectedIndex,
                icon: Icons.receipt_long_outlined,
                selectedIcon: Icons.receipt_long,
                label: 'Pedidos',
              ),
              _buildNavItem(
                context,
                index: 1,
                selectedIndex: selectedIndex,
                icon: Icons.restaurant_outlined,
                selectedIcon: Icons.restaurant,
                label: 'Cocina',
              ),
              _buildNavItem(
                context,
                index: 2,
                selectedIndex: selectedIndex,
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings,
                label: 'Config',
              ),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
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
