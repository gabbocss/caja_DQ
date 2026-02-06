/// Feature de Buffet Sabado - Lógica del All You Can Eat
/// 
/// Este módulo maneja la funcionalidad del buffet de los sábados:
/// - Registro de comensales con precio fijo
/// - Control de productos incluidos en el buffet
/// - Gestión de bebidas adicionales (no incluidas)
/// - Cálculo automático de precios por persona
library;

// Domain
export 'domain/entities/buffet_session.dart';
export 'domain/repositories/buffet_repository.dart';

// Data
export 'data/repositories/buffet_repository_impl.dart';

// Presentation
export 'presentation/providers/buffet_provider.dart';
