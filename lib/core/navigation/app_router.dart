import 'package:go_router/go_router.dart';

import '../../features/pedidos/presentation/pages/pedidos_page.dart';
import '../../features/cocina/presentation/pages/cocina_page.dart';
import '../../features/configuracion/presentation/pages/configuracion_page.dart';
import '../../features/configuracion/presentation/pages/configuracion_impresora_page.dart';
import '../../features/configuracion/presentation/pages/destinos_page.dart';
import '../../features/configuracion/presentation/pages/gestion_productos_page.dart';
import '../../features/configuracion/presentation/pages/gestion_mesas_page.dart';
import '../../features/buffet_sabado/presentation/pages/configuracion_buffet_page.dart';
import 'navigation_shell.dart';

/// Rutas de la aplicación
class AppRoutes {
  static const String pedidos = '/pedidos';
  static const String cocina = '/cocina';
  static const String configuracion = '/configuracion';
  static const String destinos = '/destinos';
  static const String buffetConfig = '/buffet-config';
  static const String gestionProductos = '/gestion-productos';
  static const String gestionMesas = '/gestion-mesas';
  static const String configuracionImpresora = '/configuracion-impresora';
}

/// Configuración del router de la aplicación
final appRouter = GoRouter(
  initialLocation: AppRoutes.pedidos,
  routes: [
    // Shell de navegación con bottom navigation
    ShellRoute(
      builder: (context, state, child) {
        return NavigationShell(child: child);
      },
      routes: [
        GoRoute(
          path: AppRoutes.pedidos,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: PedidosPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.cocina,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CocinaPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.configuracion,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ConfiguracionPage(),
          ),
        ),
      ],
    ),
    // Rutas independientes (sin shell de navegación)
    GoRoute(
      path: AppRoutes.destinos,
      builder: (context, state) => const DestinosPage(),
    ),
    GoRoute(
      path: AppRoutes.buffetConfig,
      builder: (context, state) => const ConfiguracionBuffetPage(),
    ),
    GoRoute(
      path: AppRoutes.gestionProductos,
      builder: (context, state) => const GestionProductosPage(),
    ),
    GoRoute(
      path: AppRoutes.gestionMesas,
      builder: (context, state) => const GestionMesasPage(),
    ),
    GoRoute(
      path: AppRoutes.configuracionImpresora,
      builder: (context, state) => const ConfiguracionImpresoraPage(),
    ),
  ],
);
