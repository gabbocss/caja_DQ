# Sistema de Restaurante - Programa Caja DQ

Sistema modular y escalable para gestión de restaurante desarrollado en Flutter con Clean Architecture.

## 🍽️ Características

- **Toma de Pedidos**: Gestión de comandas por mesa
- **Pantalla de Cocina**: Visualización en tiempo real de pedidos
- **Buffet del Sábado**: Sistema All You Can Eat con precios diferenciados
- **Facturación**: Generación de tickets e integración con impresora térmica
- **Conectividad Local**: Comunicación entre dispositivos vía WiFi

## 🏗️ Arquitectura

El proyecto sigue **Clean Architecture** con estructura por Features:

```
lib/
├── core/                          # Módulo central compartido
│   ├── constants/                 # Constantes de la aplicación
│   ├── database/                  # Configuración de Isar DB
│   ├── di/                        # Inyección de dependencias
│   ├── models/                    # Modelos de datos (Isar Collections)
│   ├── network/                   # Servidor HTTP local y cliente API
│   └── utils/                     # Utilidades
│
├── features/                      # Funcionalidades del sistema
│   ├── pedidos/                   # Feature de toma de comandas
│   │   ├── data/                  # Implementación de repositorios
│   │   ├── domain/                # Entidades y contratos
│   │   └── presentation/          # UI, páginas, providers
│   │
│   ├── cocina/                    # Feature de visualización cocina
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── buffet_sabado/             # Feature del All You Can Eat
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── facturacion/               # Feature de tickets e impresión
│       ├── data/
│       ├── domain/
│       └── presentation/
│
└── main.dart                      # Punto de entrada
```

## 📱 Plataformas Soportadas

| Plataforma | Rol Sugerido | Funciones Principales |
|------------|--------------|----------------------|
| **Windows** | Servidor/Caja | Base de datos central, impresión de tickets |
| **Android** | Mesero | Toma de pedidos, gestión de mesas |
| **Web** | Cocina | Visualización de pedidos en tiempo real |

## 🗄️ Modelos de Datos

### Producto
- `id`: Identificador único
- `nombre`: Nombre del producto
- `precio`: Precio unitario
- `descripcion`: Descripción detallada
- `imagen`: Ruta de imagen
- `esBuffet`: Indica si forma parte del buffet
- `categoria`: Categoría del producto

### Pedido
- `id`: Identificador único
- `mesaNumero`: Número de mesa
- `items`: Lista de productos ordenados
- `estado`: pendiente/preparando/listo/servido/cancelado/pagado
- `total`: Monto total
- `usuarioCamarero`: Quién tomó el pedido

### Mesa
- `id`: Identificador único
- `numero`: Número visible de la mesa
- `estado`: libre/ocupada/reservada/enLimpieza
- `capacidad`: Número de personas
- `ubicacion`: Interior/Terraza/Privado/Barra

## 🔧 Configuración

### Requisitos
- Flutter SDK 3.10+
- Dart 3.0+

### Instalación

```bash
# Clonar el repositorio
git clone <url-del-repo>
cd programa_caja

# Instalar dependencias
flutter pub get

# Generar código de Isar
dart run build_runner build --delete-conflicting-outputs

# Ejecutar en modo debug
flutter run
```

### Configuración de Red

El sistema utiliza un servidor HTTP local para comunicación entre dispositivos:

1. **Servidor (Windows/Linux)**: Al iniciar, automáticamente levanta un servidor HTTP
2. **Clientes (Android/Web)**: Deben configurar la URL del servidor en `main.dart`:

```dart
await initializeDependencies(
  asServer: false,
  remoteServerUrl: 'http://192.168.1.100:8080', // IP del servidor
);
```

## 📡 API Endpoints

Cuando el servidor está activo, expone los siguientes endpoints:

```
GET  /health                    - Estado del servidor
GET  /api/productos             - Listar productos
GET  /api/productos/buffet      - Productos del buffet
POST /api/productos             - Crear/actualizar producto

GET  /api/mesas                 - Listar mesas
GET  /api/mesas/<numero>        - Obtener mesa
PUT  /api/mesas/<numero>/estado - Actualizar estado de mesa

GET  /api/pedidos               - Pedidos activos
GET  /api/pedidos/cocina        - Pedidos para cocina
GET  /api/pedidos/mesa/<numero> - Pedidos de una mesa
POST /api/pedidos               - Crear pedido
PUT  /api/pedidos/<id>/estado   - Actualizar estado de pedido
```

## 💰 Configuración del Buffet

Editar constantes en `lib/core/constants/app_constants.dart`:

```dart
static const double precioBuffet = 199.00;      // Precio adulto
static const double precioBuffetNinos = 99.00;  // Precio niño
static const int edadMaximaNino = 10;           // Edad máxima niño
```

## 🖨️ Impresión

El sistema soporta impresoras térmicas vía:
- **Windows**: API nativa (win32)
- **Android**: Bluetooth (requiere configuración adicional)

## 📋 Dependencias Principales

- `isar`: Base de datos local NoSQL
- `shelf`: Servidor HTTP
- `get_it`: Inyección de dependencias
- `provider`: Manejo de estado
- `go_router`: Navegación

## 🚀 Próximos Pasos

1. [ ] Implementar páginas de UI para cada feature
2. [ ] Agregar autenticación de usuarios
3. [ ] Integrar impresora térmica real
4. [ ] Añadir reportes y estadísticas
5. [ ] Implementar sincronización offline

## 📄 Licencia

Proyecto privado - Todos los derechos reservados
