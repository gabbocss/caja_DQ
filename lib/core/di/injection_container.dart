import 'package:get_it/get_it.dart';

import '../database/database_service.dart';
import '../network/local_server.dart';
import '../network/api_client.dart';

/// Contenedor de inyección de dependencias usando GetIt
/// 
/// Centraliza la creación y acceso a servicios en toda la aplicación
final GetIt sl = GetIt.instance;

/// Indica si esta instancia actúa como servidor (Windows/Linux) o cliente (Android)
bool _isServer = false;

/// Verifica si la app está configurada como servidor
bool get isServer => _isServer;

/// URL del servidor cuando actuamos como cliente
String? _serverUrl;

/// Obtiene la URL del servidor configurada
String? get serverUrl => _serverUrl;

/// Inicializa todas las dependencias de la aplicación
/// 
/// [asServer]: true si esta instancia será el servidor principal (Windows/Linux)
/// [remoteServerUrl]: URL del servidor si actuamos como cliente
Future<void> initializeDependencies({
  bool asServer = false,
  String? remoteServerUrl,
}) async {
  _isServer = asServer;
  _serverUrl = remoteServerUrl;

  // ==================== SERVICIOS CORE ====================

  // Registrar DatabaseService como singleton lazy
  sl.registerLazySingleton<DatabaseService>(() => DatabaseService.instance);

  // ==================== SERVIDOR LOCAL ====================

  if (asServer) {
    // Si somos servidor, registrar el LocalServer
    sl.registerLazySingleton<LocalServer>(() => LocalServer.instance);
  }

  // ==================== CLIENTE API ====================

  if (!asServer && remoteServerUrl != null) {
    // Si somos cliente, registrar el ApiClient
    sl.registerLazySingleton<ApiClient>(() => ApiClient(remoteServerUrl));
  }
}

/// En móvil: true si el usuario aún no ha configurado la URL del servidor (primera vez o solo localhost).
bool needConfigurarConexion = false;

/// Registra de nuevo el ApiClient con la nueva URL (tras guardar en ConfigurarConexion).
/// Cierra el cliente anterior si existe.
Future<void> registerApiClientWithUrl(String url) async {
  if (sl.isRegistered<ApiClient>()) {
    sl<ApiClient>().dispose();
    sl.unregister<ApiClient>();
  }
  _serverUrl = url;
  sl.registerLazySingleton<ApiClient>(() => ApiClient(url));
  needConfigurarConexion = false;
}

/// Inicializa los servicios asíncronos
/// 
/// Debe llamarse después de initializeDependencies()
Future<void> initializeAsyncServices() async {
  // Inicializar base de datos
  final db = sl<DatabaseService>();
  await db.initialize();

  // Si somos servidor, iniciar el servidor HTTP
  if (_isServer) {
    final server = sl<LocalServer>();
    await server.start();
  }
}

/// Limpia y cierra todos los servicios
Future<void> disposeDependencies() async {
  // Cerrar servidor si está corriendo
  if (_isServer && sl.isRegistered<LocalServer>()) {
    await sl<LocalServer>().stop();
  }

  // Cerrar cliente API si existe
  if (sl.isRegistered<ApiClient>()) {
    sl<ApiClient>().dispose();
  }

  // Cerrar base de datos
  if (sl.isRegistered<DatabaseService>()) {
    await sl<DatabaseService>().close();
  }

  // Resetear el contenedor
  await sl.reset();
}
