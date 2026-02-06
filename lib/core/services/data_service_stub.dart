// Stub para data service - se usa cuando la plataforma no está determinada
library;

import 'data_service.dart';

/// Obtiene la instancia del servicio (stub - lanza excepción)
DataService getDataServiceInstance() {
  throw UnsupportedError('Plataforma no soportada');
}
