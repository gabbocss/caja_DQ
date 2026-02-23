/// Inyección de dependencias para Web (sin DatabaseService ni LocalServer reales).
import 'package:get_it/get_it.dart';

import '../database/database_service_web.dart';
import '../network/local_server_web.dart';
import '../network/api_client.dart';

final GetIt sl = GetIt.instance;

bool _isServer = false;
bool get isServer => _isServer;

String? _serverUrl;
String? get serverUrl => _serverUrl;

Future<void> initializeDependencies({
  bool asServer = false,
  String? remoteServerUrl,
}) async {
  _isServer = asServer;
  _serverUrl = remoteServerUrl;

  if (!asServer && remoteServerUrl != null) {
    sl.registerLazySingleton<ApiClient>(() => ApiClient(remoteServerUrl));
  }
}

bool needConfigurarConexion = false;

Future<void> registerApiClientWithUrl(String url) async {
  if (sl.isRegistered<ApiClient>()) {
    sl<ApiClient>().dispose();
    sl.unregister<ApiClient>();
  }
  _serverUrl = url;
  sl.registerLazySingleton<ApiClient>(() => ApiClient(url));
  needConfigurarConexion = false;
}

Future<void> initializeAsyncServices() async {}

Future<void> disposeDependencies() async {
  if (sl.isRegistered<ApiClient>()) {
    sl<ApiClient>().dispose();
  }
  await sl.reset();
}
