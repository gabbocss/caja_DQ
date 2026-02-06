/// Feature de Pedidos - Toma de comandas
/// 
/// Este módulo maneja toda la funcionalidad relacionada con:
/// - Creación de pedidos/comandas
/// - Modificación de pedidos existentes
/// - Visualización de pedidos por mesa
/// - Gestión del estado de pedidos
library;

// Domain - Repositorios
export 'domain/repositories/pedidos_repository.dart';

// Data - Implementaciones
export 'data/repositories/pedidos_repository_impl.dart';

// Presentation - Providers
export 'presentation/providers/pedidos_provider.dart';

// Presentation - Pages
export 'presentation/pages/pedidos_page.dart';

// Presentation - Widgets
export 'presentation/widgets/categoria_selector.dart';
export 'presentation/widgets/producto_grid.dart';
export 'presentation/widgets/carrito_panel.dart';
