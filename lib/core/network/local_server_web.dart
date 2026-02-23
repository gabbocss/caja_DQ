/// Stub de LocalServer para compilación Web.
/// El servidor solo corre en Windows/Linux; en web no aplica.

/// Stub: mismo nombre que el servidor real para que el resto del código compile.
class LocalServer {
  static LocalServer? _instance;
  static LocalServer get instance => _instance ??= LocalServer._();

  LocalServer._();

  static const int defaultPort = 8080;

  bool get isRunning => false;
  String? get serverIp => null;
  String? get serverUrl => null;

  Future<void> start({int port = defaultPort}) async {}
  Future<void> stop() async {}
}
