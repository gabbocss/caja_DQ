import '../entities/buffet_session.dart';
import '../../../../core/models/models.dart';

/// Interfaz del repositorio de Buffet
abstract class BuffetRepository {
  /// Inicia una nueva sesión de buffet
  Future<void> iniciarSesion(BuffetSession session);

  /// Obtiene la sesión activa de una mesa
  Future<BuffetSession?> obtenerSesionActiva(int mesaNumero);

  /// Actualiza una sesión de buffet
  Future<void> actualizarSesion(BuffetSession session);

  /// Finaliza una sesión y genera el pedido correspondiente
  Future<Pedido> finalizarSesion(int mesaNumero);

  /// Obtiene los productos disponibles en el buffet
  Future<List<Producto>> obtenerProductosBuffet();

  /// Obtiene los productos NO incluidos en el buffet (adicionales)
  Future<List<Producto>> obtenerProductosAdicionales();

  /// Verifica si hoy es día de buffet (sábado)
  bool esDiaDeBuffet();

  /// Obtiene todas las sesiones activas
  Future<List<BuffetSession>> obtenerSesionesActivas();
}
