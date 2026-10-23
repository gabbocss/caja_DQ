# Sistema de Restaurante — Programa Caja

Sistema modular de gestión de restaurante en Flutter (escritorio, Android y web). La caja de Windows o Linux es el servidor local: guarda los datos del servicio, imprime tickets y atiende a camareros, cocina y clientes. Un servidor Node aparte, en un VPS, mantiene reservas y la lista de la compra disponibles las 24 horas, aunque la caja esté apagada.

## Qué hace

- **Pedidos y mesas.** Comandas por mesa, categorías, búsqueda, orden de platos (1º, 2º…), notas, stock y pagos parciales o totales (efectivo, tarjeta, otros).
- **Cocina.** Pantalla en tiempo real, estado por plato (pendiente, preparando, listo), pitido en web y tickets por destino.
- **Reservas.** Agenda de comida, cena y asporto (para llevar, 0 cubiertos). Estados: pendiente, sentada, cancelada y cobrada. El móvil crea y edita; la caja sincroniza con el VPS cada 15 segundos y puede sentar, cobrar asporto e imprimir.
- **Lista de paellas.** Impresión automática de reservas nuevas antes de abrir (mesas, asporto y aviso en barra), según los horarios de la agenda.
- **Buffet.** All you can eat con precios de adulto, niño y menor, horario, cubierto fuera de buffet y límite de tipos distintos por comensal en el pedido QR.
- **Pedido por QR.** Cada mesa tiene una URL. El cliente arma el carrito en el móvil y lo envía a cocina. Se pueden regenerar los enlaces para invalidar los antiguos.
- **Caja.** Fondo inicial por denominaciones de euro, retiros, arqueo, cierre de turno e historial. Los cobros quedan ligados a la sesión.
- **Estadísticas.** Platos más pedidos y tiempos de preparación (desde «Empezar» hasta «Listo»), con gráficos y exportación a PDF.
- **Lista de la compra.** Catálogo en el VPS, zonas Cocina y Sala, supermercados, precios por envase y precio por kilo, litro o unidad. En el móvil: comprar o hacer la lista. En escritorio: pantalla de compra.
- **Carta y destinos.** Productos, categorías, mesas, alérgenos, inventario opcional y destinos de impresión (cocina, barra, impresora de red).
- **WiFi.** QR para que el personal se una a la red del local.
- **SumUp.** Aviso de cobro en terminal cuando el pago es con tarjeta (Cloud API, opcional).

## Plataformas

| Plataforma | Rol | Arranque | Qué muestra |
|------------|-----|----------|-------------|
| **Windows / Linux** | Caja y servidor local (puerto 8080) | Pedidos | Pedidos, Reservas, Cocina, Configuración, WiFi, Estadísticas, Caja, Compra |
| **Android** | Camarero | Mesas (pide la URL del servidor la primera vez) | Mesas, Menús (reservas, servidor, lista de la compra), WiFi |
| **Web** | Cocina | Cocina (`lib/main_web.dart`) | Cocina y Configuración, contra la API del servidor local |

La compilación de Windows empaqueta también la web de cocina junto al ejecutable (ver el workflow de GitHub Actions).

## Arquitectura

Clean Architecture por features. La lógica de datos y de red vive fuera de los widgets. Inyección con GetIt; estado de UI con Provider; rutas con go_router.

```
lib/
├── core/
│   ├── constants/          # Precios, puerto, intervalos
│   ├── database/           # Isar (solo escritorio y Android)
│   ├── di/                 # GetIt
│   ├── models/             # Colecciones Isar y modelos de red
│   ├── network/            # Servidor HTTP local (shelf) y ApiClient
│   ├── navigation/         # Rutas y barra lateral
│   ├── prefs/              # Preferencias (URL, horarios, impresión)
│   └── services/           # Impresión, sync de reservas, pagos, paellas
│
├── features/
│   ├── pedidos/            # Comandas, mesas, carrito, cobro
│   ├── cocina/             # Pantalla de cocina
│   ├── reservas/           # Agenda, asporto, cobro
│   ├── buffet_sabado/      # Reglas del buffet
│   ├── caja/               # Apertura, retiros, cierre
│   ├── estadisticas/       # Consultas, gráficos y PDF
│   ├── lista_compra/       # Catálogo, compra y supermercados (VPS)
│   ├── configuracion/      # Carta, mesas, destinos, red, impresora
│   └── facturacion/        # Tickets
│
├── main.dart               # Escritorio y Android
└── main_web.dart           # Cocina web

server/reservas-central/    # API Node 24/7 (reservas, carta, compra)
tool/                       # Empaquetado Windows + web
```

En web no hay base de datos local: cocina habla solo por HTTP. En Android la URL del servidor se guarda con `shared_preferences`.

## Modelos principales (Isar, en la caja)

**Producto.** Nombre, precio, categoría, orden, imagen, alérgenos, buffet, destino de impresión, activo, disponible y stock opcional.

**Pedido.** Mesa, ítems (notas, destino, orden de salida, tiempos de preparación), estado (`pendiente`, `preparando`, `listo`, `servido`, `cancelado`, `pagado`), total con IVA incluido, pendiente y cobrado acumulado, camarero, origen (`camarero`, `qr`, `web`).

**Mesa.** Número único, estado (`libre`, `ocupada`, `reservada`, `enLimpieza`), capacidad y ubicación.

**Reserva.** Cliente, personas, llegada, alergias, ítems anticipados, mesa asignada y estado (`pendiente`, `sentada`, `cancelada`, `cobrada`).

**Destino de impresión.** Pantalla, impresora de red (IP y puerto, por defecto 9100) o ambos.

**Configuración de buffet.** Día, horario, precios, cubierto y límites del pedido QR.

La caja (sesiones, retiros, cierres y registro de cobros) y la lista de la compra no van en Isar: la caja se guarda en archivos locales del PC y la compra vive en JSON del VPS.

## Puesta en marcha

Requisitos: Flutter estable con el SDK de Dart indicado en `pubspec.yaml` (3.10+).

```bash
git clone <url-del-repo>
cd programa_caja
flutter pub get

# Solo si cambian los modelos Isar
dart run build_runner build --delete-conflicting-outputs

# Caja (Windows o Linux): levanta el servidor en :8080
flutter run -d windows   # o -d linux

# Camarero
flutter run -d android

# Cocina en el navegador
flutter run -d chrome -t lib/main_web.dart
```

En el móvil, la primera apertura pide la URL de la caja, por ejemplo `http://192.168.1.100:8080`. Escritorio y Linux arrancan solos como servidor; no hace falta tocar `main.dart`.

### Compilar para el local

El workflow `.github/workflows/build_windows.yml` (push a `main` o ejecución manual) genera el release de Windows, parchea Isar para la web, construye la cocina con `lib/main_web.dart` y la mete en el paquete de Windows.

En local, los mismos pasos están en `tool/`:

```bash
flutter build windows --release
dart run tool/patch_g_for_web.dart
flutter build web -t lib/main_web.dart
dart run tool/package_windows_with_web.dart
```

## Red

Hay dos servidores distintos:

1. **Caja (shelf, puerto 8080).** Mesas, pedidos, cocina, carta, pagos, QR y una copia de las reservas. Solo está encendido con la app de escritorio.
2. **Central (Node, puerto 8888, PM2).** Reservas, copia de productos, lista de la compra y supermercados. Sigue activo con la caja apagada. Detalle de despliegue, variables y JSON en [`server/reservas-central/README.md`](server/reservas-central/README.md).

La caja hace `GET /api/reservas` cada 15 segundos, fusiona por id (no pisa una reserva ya `sentada` o `cobrada` en local) y el móvil edita o cancela en el VPS. `POST /api/reservas/marcar-sincronizadas` se mantiene por compatibilidad y no bloquea la entrega.

En la app: **Configuración → Configurar Servidor Central** (pide contraseña de administrador). Ejemplo de URL: `http://<ip-del-vps>:8888` o la URL HTTPS del proxy.

## API de la caja (puerto 8080)

Índice: `GET /api`. Salud: `GET /health` y `GET /api/health`.

```
GET    /api/productos
GET    /api/productos/buffet
GET    /api/productos/disponibles
POST   /api/productos
PUT    /api/productos/<id>/disponibilidad
DELETE /api/productos/<id>
POST   /api/productos/validar-stock
GET    /api/categorias

GET    /api/mesas
GET    /api/mesas/cuentas-abiertas
GET    /api/mesas/<numero>
GET    /api/mesas/<numero>/qr
GET    /api/mesas/<numero>/cuenta
PUT    /api/mesas/<numero>/estado
POST   /api/mesas/pago
POST   /api/mesas/liberar

GET    /api/pedidos
GET    /api/pedidos/cocina
GET    /api/pedidos/mesa/<numero>
GET    /api/pedidos/destino/<destinoId>
POST   /api/pedidos
PUT    /api/pedidos/<id>/estado
PUT    /api/pedidos/<id>/item/<index>/estado
POST   /api/cocina/imprimir-ticket

GET    /api/reservas
POST   /api/reservas
PUT    /api/reservas/<id>/estado

GET    /api/destinos
GET    /api/destinos/activos
GET    /api/destinos/<id>
POST   /api/destinos
DELETE /api/destinos/<id>

GET    /api/configuracion-buffet

GET    /qr/<token>                         # Carta del cliente
GET    /api/qr/carrito/<token>
POST   /api/qr/carrito/<token>/add|set|remove|clear
POST   /api/qr/pedido
```

## API central (VPS, puerto 8888)

Reservas, productos (copia para el móvil), lista de la compra y supermercados. La compra no borra el catálogo al vaciar: solo resetea `hayQueComprar` y `comprado`.

```
GET/POST  /api/reservas
PUT       /api/reservas/<id>/estado
POST      /api/reservas/marcar-sincronizadas

GET/POST  /api/productos

GET/POST  /api/lista-compra
PUT/DELETE /api/lista-compra/<id>
POST      /api/lista-compra/vaciar-compra
POST      /api/lista-compra/reordenar
GET/POST  /api/lista-compra/precios
DELETE    /api/lista-compra/precios/<id>

GET/POST  /api/supermercados
PUT/DELETE /api/supermercados/<id>
POST      /api/supermercados/reordenar
```

Datos en `data/*.json` del proceso Node. Retención de reservas: 30 días (`RESERVAS_PURGE_MS`).

## Buffet

La configuración viva está en la app (**Configuración → Configurar Buffet**): día, horario, precios y reglas del QR. Los valores de `lib/core/constants/app_constants.dart` son el respaldo inicial:

```dart
static const double precioBuffet = 199.00;
static const double precioBuffetNinos = 99.00;
static const int edadMaximaNino = 10;
```

En buffet se puede enviar el ticket de «Hecho» a una impresora concreta (IP y puerto) en lugar del destino habitual del plato.

## Impresión

Destinos configurables (pantalla, impresora de red o ambos). Los tickets salen por TCP al puerto 9100 de la impresora. También hay prueba de impresión desde Configuración y la lista automática de paellas ligada a los horarios de reservas.

## Dependencias

- `isar_community` — base local
- `shelf` / `shelf_router` — servidor de la caja
- `get_it`, `provider`, `go_router`
- `http`, `shared_preferences`, `network_info_plus`
- `qr_flutter` — QR de mesa y de WiFi
- `pdf`, `printing`, `fl_chart` — estadísticas
- `file_picker`, `path_provider`, `intl`, `uuid`

El servidor central es Node 18+ sin dependencias npm, gestionado con PM2 (`server/reservas-central`).

## Licencia

Proyecto privado. Todos los derechos reservados.
