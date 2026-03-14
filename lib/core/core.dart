/// Exportaciones centralizadas del módulo core
library;

// Modelos (en Web: versiones sin Isar para evitar enteros 64-bit en JS)
export 'models/models.dart';

// Base de datos (en Web: stub; en VM: Isar). Si hay dart.library.io → real.
export 'database/database_service_web.dart' if (dart.library.io) 'database/database_service.dart';

// Network (en Web: stub; en VM: servidor Shelf)
export 'network/local_server_web.dart' if (dart.library.io) 'network/local_server.dart';
export 'network/api_client.dart';

// Inyección de dependencias
export 'di/injection_container.dart';

// Constantes
export 'constants/app_constants.dart';

// Utilidades
export 'utils/platform_utils.dart';
export 'utils/device_info.dart';

// Preferencias (URL del servidor en móvil)
export 'prefs/server_url_prefs.dart';

// Servicios
export 'services/imprimir_pedido_service.dart';
export 'services/configuracion_impresion_service.dart';

// Navegación
export 'navigation/app_router.dart';
export 'navigation/navigation_shell.dart';
