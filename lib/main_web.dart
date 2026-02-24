/// Punto de entrada para compilación Web (cocina).
/// No importa Isar ni DatabaseService; usa core_web.
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:provider/provider.dart';

import 'core/core_web.dart';
import 'features/pedidos/presentation/providers/pedidos_mobile_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? remoteUrl;
  if (PlatformUtils.isMobile) {
    final saved = await getSavedServerUrl();
    if (saved != null && saved.isNotEmpty && saved != 'http://localhost:8080') {
      remoteUrl = saved;
    } else {
      needConfigurarConexion = true;
      remoteUrl = 'http://localhost:8080';
    }
  } else {
    // En navegador (cocina): usar el mismo origen que la página (PC, tablet, etc.)
    remoteUrl = Uri.base.origin;
  }

  debugPrint('═══════════════════════════════════════════════════════════════');
  debugPrint('  🍽️  Sistema de Restaurante (Web) - ${AppConstants.appVersion}');
  debugPrint('  📱  Plataforma: Web');
  debugPrint('  🎯  Rol: Cocina');
  debugPrint('═══════════════════════════════════════════════════════════════');

  try {
    await initializeDependencies(
      asServer: false,
      remoteServerUrl: remoteUrl,
    );
    await initializeAsyncServices();
    debugPrint('✅ Servicios inicializados correctamente');
  } catch (e) {
    debugPrint('❌ Error inicializando servicios: $e');
  }

  runApp(
    PlatformUtils.isMobile
        ? ChangeNotifierProvider(
            create: (_) => PedidosMobileProvider(),
            child: const RestauranteApp(),
          )
        : const RestauranteApp(),
  );
}

/// Misma app que main.dart; el tema se define en RestauranteApp en main.dart.
/// Para no duplicar, importamos el widget desde main.dart... pero main.dart
/// importa core (no core_web). Así que duplicamos solo el MaterialApp.
class RestauranteApp extends StatelessWidget {
  const RestauranteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: _buildTheme(),
      darkTheme: _buildTheme(),
      themeMode: ThemeMode.dark,
    );
  }

  ThemeData _buildTheme() {
    const primaryColor = Color(0xFFE94560);
    const surfaceColor = Color(0xFF16213E);
    const backgroundColor = Color(0xFF1A1A2E);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: Color(0xFF00D9A5),
        surface: surfaceColor,
        error: Color(0xFFFF6B6B),
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F3460),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white38),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(
          color: Colors.white70,
          fontSize: 16,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceColor,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 8,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
        headlineMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
    );
  }
}
