import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Utilidades para detectar la plataforma actual
/// 
/// Permite ejecutar código específico según la plataforma
class PlatformUtils {
  PlatformUtils._();

  /// Verifica si estamos corriendo en Web
  static bool get isWeb => kIsWeb;

  /// Verifica si estamos corriendo en Windows
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// Verifica si estamos corriendo en Android
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Verifica si estamos corriendo en iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Verifica si estamos corriendo en macOS
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// Verifica si estamos corriendo en Linux
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  /// Verifica si estamos en un dispositivo móvil
  static bool get isMobile => isAndroid || isIOS;

  /// Verifica si estamos en un dispositivo de escritorio
  static bool get isDesktop => isWindows || isMacOS || isLinux;

  /// Determina si esta instancia debe actuar como servidor
  /// 
  /// Por defecto, solo Windows actúa como servidor principal
  static bool get shouldActAsServer => isWindows || isLinux;

  /// Obtiene el nombre de la plataforma actual
  static String get platformName {
    if (isWeb) return 'Web';
    if (isWindows) return 'Windows';
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    if (isMacOS) return 'macOS';
    if (isLinux) return 'Linux';
    return 'Desconocida';
  }

  /// Obtiene el rol sugerido para esta plataforma
  static String get suggestedRole {
    if (isWindows || isLinux) return 'Servidor/Caja';
    if (isAndroid) return 'Mesero';
    if (isWeb) return 'Cocina';
    return 'Cliente';
  }
}
