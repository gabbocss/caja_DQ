/// Feature de Facturación - Gestión de tickets e impresora fiscal
/// 
/// Este módulo maneja la funcionalidad de facturación:
/// - Generación de tickets de venta
/// - Integración con impresora fiscal/térmica
/// - Historial de ventas
/// - Reportes diarios/semanales/mensuales
library;

// Domain
export 'domain/entities/ticket.dart';
export 'domain/repositories/facturacion_repository.dart';

// Data
export 'data/repositories/facturacion_repository_impl.dart';
export 'data/services/printer_service.dart';

// Presentation
export 'presentation/providers/facturacion_provider.dart';
