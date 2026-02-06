/// Constantes globales de la aplicación
/// 
/// Centraliza valores que se usan en múltiples lugares
library;

class AppConstants {
  // Evitar instanciación
  AppConstants._();

  // ==================== INFORMACIÓN DE LA APP ====================
  
  /// Nombre de la aplicación
  static const String appName = 'Sistema Restaurante';
  
  /// Versión de la aplicación
  static const String appVersion = '1.0.0';

  // ==================== CONFIGURACIÓN DE RED ====================
  
  /// Puerto por defecto del servidor local
  static const int serverPort = 8080;
  
  /// Tiempo de espera para requests HTTP (en segundos)
  static const int httpTimeout = 30;
  
  /// Intervalo de polling para actualización de datos (en segundos)
  static const int pollingInterval = 5;

  // ==================== CONFIGURACIÓN DEL BUFFET ====================
  
  /// Precio base del buffet del sábado (por persona)
  static const double precioBuffet = 199.00;
  
  /// Precio del buffet para niños
  static const double precioBuffetNinos = 99.00;
  
  /// Edad máxima para considerar niño en buffet
  static const int edadMaximaNino = 10;

  // ==================== CONFIGURACIÓN DE IMPRESIÓN ====================
  
  /// Ancho del ticket en caracteres
  static const int anchoTicket = 32;
  
  /// Nombre del establecimiento para tickets
  static const String nombreEstablecimiento = 'Mi Restaurante';
  
  /// Dirección del establecimiento
  static const String direccionEstablecimiento = 'Calle Principal #123';
  
  /// Teléfono del establecimiento
  static const String telefonoEstablecimiento = '(555) 123-4567';

  // ==================== MENSAJES ====================
  
  static const String mensajeBienvenida = '¡Bienvenido al Sistema!';
  static const String mensajeErrorConexion = 'Error de conexión. Verifique la red.';
  static const String mensajePedidoCreado = 'Pedido creado correctamente';
  static const String mensajePedidoActualizado = 'Pedido actualizado';
  static const String mensajeMesaOcupada = 'Esta mesa ya tiene un pedido activo';
}

/// Categorías predefinidas de productos
class CategoriaProducto {
  CategoriaProducto._();

  static const String tacos = 'Tacos';
  static const String antojitos = 'Antojitos';
  static const String platosFuertes = 'Platos Fuertes';
  static const String sopas = 'Sopas';
  static const String ensaladas = 'Ensaladas';
  static const String postres = 'Postres';
  static const String bebidas = 'Bebidas';
  static const String bebidasAlcoholicas = 'Bebidas Alcohólicas';
  static const String extras = 'Extras';

  /// Lista de todas las categorías disponibles
  static const List<String> todas = [
    tacos,
    antojitos,
    platosFuertes,
    sopas,
    ensaladas,
    postres,
    bebidas,
    bebidasAlcoholicas,
    extras,
  ];
}

/// Ubicaciones predefinidas de mesas
class UbicacionMesa {
  UbicacionMesa._();

  static const String interior = 'Interior';
  static const String terraza = 'Terraza';
  static const String privado = 'Privado';
  static const String barra = 'Barra';

  static const List<String> todas = [
    interior,
    terraza,
    privado,
    barra,
  ];
}
