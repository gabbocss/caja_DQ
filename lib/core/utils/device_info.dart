/// Información del dispositivo para adaptar tema/UI según versión.
/// Solo se rellena en Android; en otras plataformas permanece null.
class DeviceInfo {
  DeviceInfo._();

  /// API level de Android (ej. 35 = Android 15). Null en iOS, Web, Desktop.
  static int? androidSdkInt;

  /// true si estamos en Android con API < 35 (Android 14 o inferior).
  /// Android 15 (API 35) y superior usan Material 3; solo versiones más antiguas usan legacy.
  static bool get isLegacyAndroid =>
      androidSdkInt != null && androidSdkInt! < 35;
}
