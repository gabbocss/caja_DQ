import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

import 'core/core.dart';

void main() async {
  // Asegurar que los bindings de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Determinar si actuamos como servidor basándonos en la plataforma
  // En Web siempre somos cliente
  final bool actAsServer = kIsWeb ? false : PlatformUtils.shouldActAsServer;

  debugPrint('═══════════════════════════════════════════════════════════════');
  debugPrint('  🍽️  Sistema de Restaurante - ${AppConstants.appVersion}');
  debugPrint('  📱  Plataforma: ${kIsWeb ? 'Web' : PlatformUtils.platformName}');
  debugPrint('  🎯  Rol: ${kIsWeb ? 'Cliente Web' : PlatformUtils.suggestedRole}');
  debugPrint('  🖥️  Modo servidor: $actAsServer');
  debugPrint('═══════════════════════════════════════════════════════════════');

  try {
    // Inicializar inyección de dependencias
    await initializeDependencies(
      asServer: actAsServer,
      // URL del servidor para clientes (Web/Android)
      // Cambiar esta URL a la IP de tu servidor
      remoteServerUrl: 'http://localhost:8080',
    );

    // Inicializar servicios asíncronos (DB, servidor)
    await initializeAsyncServices();

    debugPrint('✅ Servicios inicializados correctamente');
  } catch (e) {
    debugPrint('❌ Error inicializando servicios: $e');
  }

  runApp(const RestauranteApp());
}

/// Aplicación principal del sistema de restaurante
class RestauranteApp extends StatelessWidget {
  const RestauranteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      
      // Configuración del router
      routerConfig: appRouter,
      
      // Tema oscuro moderno para restaurante
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
      
      // Esquema de colores
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: Color(0xFF00D9A5),
        surface: surfaceColor,
        error: Color(0xFFFF6B6B),
      ),
      
      // Scaffold
      scaffoldBackgroundColor: backgroundColor,
      
      // AppBar
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
      
      // Cards
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Botones elevados
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
      
      // Botones de texto
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
      
      // Input decoration
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
      
      // Diálogos
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
      
      // Snackbars
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceColor,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 8,
      ),
      
      // Tipografía
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
