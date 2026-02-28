import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';

import '../di/injection_container.dart';
import '../utils/platform_utils.dart';
import '../../features/pedidos/presentation/pages/pedidos_page.dart';
import '../../features/pedidos/presentation/pages/mesas_page.dart';
import '../../features/pedidos/presentation/pages/mesa_categorias_page.dart';
import '../../features/pedidos/presentation/pages/mesa_platos_page.dart';
import '../../features/cocina/presentation/pages/cocina_page.dart';
import '../../features/configuracion/presentation/pages/configuracion_page.dart';
import '../../features/configuracion/presentation/pages/configurar_conexion_page.dart';
import '../../features/configuracion/presentation/pages/wifi_qr_page.dart';
import '../../features/configuracion/presentation/pages/configuracion_impresora_page.dart';
import '../../features/configuracion/presentation/pages/destinos_page.dart';
import '../../features/configuracion/presentation/pages/gestion_productos_page.dart';
import '../../features/configuracion/presentation/pages/gestion_mesas_page.dart';
import '../../features/configuracion/presentation/pages/gestion_categorias_page.dart';
import '../../features/buffet_sabado/presentation/pages/configuracion_buffet_page.dart';
import 'navigation_shell.dart';

/// Rutas de la aplicación
class AppRoutes {
  static const String pedidos = '/pedidos';
  static const String mesas = '/mesas';
  static const String configurarConexion = '/configurar-conexion';
  static const String cocina = '/cocina';
  static const String configuracion = '/configuracion';
  static const String destinos = '/destinos';
  static const String buffetConfig = '/buffet-config';
  static const String gestionProductos = '/gestion-productos';
  static const String gestionMesas = '/gestion-mesas';
  static const String gestionCategorias = '/gestion-categorias';
  static const String configuracionImpresora = '/configuracion-impresora';
  static const String wifiQr = '/wifi-qr';
}

/// Configuración del router de la aplicación
final appRouter = GoRouter(
  initialLocation: kIsWeb
      ? AppRoutes.cocina
      : (PlatformUtils.isMobile ? AppRoutes.mesas : AppRoutes.pedidos),
  redirect: (context, state) {
    if (PlatformUtils.isMobile && needConfigurarConexion) {
      final loc = state.matchedLocation;
      if (loc != AppRoutes.configurarConexion) return AppRoutes.configurarConexion;
    }
    return null;
  },
  routes: [
    ShellRoute(
      builder: (context, state, child) => NavigationShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.pedidos,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: PedidosPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.mesas,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MesasPage(),
          ),
          routes: [
            GoRoute(
              path: 'categorias/:numero',
              pageBuilder: (context, state) {
                final numero = int.tryParse(state.pathParameters['numero'] ?? '1') ?? 1;
                return NoTransitionPage(
                  child: MesaCategoriasPage(numeroMesa: numero),
                );
              },
            ),
            GoRoute(
              path: ':numero/platos/:categoriaSlug',
              pageBuilder: (context, state) {
                final numero = int.tryParse(state.pathParameters['numero'] ?? '1') ?? 1;
                final slug = state.pathParameters['categoriaSlug'] ?? '';
                return NoTransitionPage(
                  child: MesaPlatosPage(numeroMesa: numero, categoriaSlug: slug),
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.cocina,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CocinaPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.configurarConexion,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ConfigurarConexionPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.wifiQr,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: WifiQrPage(),
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
      path: AppRoutes.gestionCategorias,
      builder: (context, state) => const GestionCategoriasPage(),
    ),
    GoRoute(
      path: AppRoutes.configuracionImpresora,
      builder: (context, state) => const ConfiguracionImpresoraPage(),
    ),
  ],
);
