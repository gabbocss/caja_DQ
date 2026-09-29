# API de reservas 24/7 (Node.js)

Servidor HTTP **sin Flutter**, compatible con `ApiClient` de programa_caja (`GET /api`, `GET /api/reservas`, etc.).

## Respuesta a tu pregunta

| Opción | ¿Existe? | Velocidad en VPS |
|--------|----------|------------------|
| Backend Node listo | **Este directorio** (nuevo) | **Más rápido** — ya tienes Node + PM2 |
| `local_server.dart` solo | No separado; depende de Flutter/Isar/GTK | Lento / inviable (Exit 134) |
| `dart compile exe` del monolito | Habría que extraer paquete Dart puro | Días de refactor |

## Despliegue en Ubuntu 24.04 (puerto 8888)

### 1. Subir al VPS

```bash
# En tu PC
cd /ruta/programa_caja
rsync -avz server/reservas-central/ usuario@64.227.113.139:~/reservas-central/
```

### 2. En el VPS

```bash
cd ~/reservas-central
node -v   # debe ser >= 18
npm install   # no hay dependencias npm; opcional
pm2 start ecosystem.config.cjs
pm2 save
pm2 status
```

### 3. Comprobar

```bash
curl -s http://127.0.0.1:8888/api | jq .
curl -s http://127.0.0.1:8888/api/reservas
```

Debe devolver JSON con `"endpoints"` y `"reservas": "/api/reservas"`.

### 4. Firewall / proxy

- Abre el puerto **8888** en el firewall del VPS, o
- Configura Nginx/Caddy: `https://64.227.113.139` → `http://127.0.0.1:8888`

### 5. En la app (Configuración → Servidor central)

- HTTP directo: `http://64.227.113.139:8888`
- HTTPS con proxy: `https://64.227.113.139` (si el proxy termina TLS en 443 y reenvía a 8888)

## Variables de entorno

| Variable | Default | Descripción |
|----------|---------|-------------|
| `PORT` | `8888` | Puerto de escucha |
| `HOST` | `0.0.0.0` | Interfaz |
| `DATA_DIR` | `./data` | Carpeta de `reservas.json` |
| `RESERVAS_PURGE_MS` | `2592000000` (30 días) | Borra del VPS reservas cuya `fechaHoraLlegada` es más antigua que este margen |

### Sincronización por id (caja ← VPS)

1. La caja hace `GET /api/reservas` (todas las `pendiente` y `cancelada` dentro de la ventana de retención).
2. Fusiona en Isar por **id**: inserta si no existe; actualiza si `fechaActualizacion` remota es ≥ local (sin pisar `sentada`/`cobrada` locales).
3. No hay candado `sincronizadaEnCajaAt`: el móvil no puede “robar” la entrega.
4. `POST /api/reservas/marcar-sincronizadas` queda como **no-op** (compatibilidad con clientes antiguos) y limpia marcas legacy si las hay.

### Edición desde la app móvil

- `GET /api/reservas?incluye=sincronizadas` (o el GET normal) lista pendientes editables.
- Al editar (`POST /api/reservas` con `id`) o cancelar (`PUT .../estado`), se actualiza `fechaActualizacion` y la caja aplica el cambio en el siguiente poll.

Tras desplegar, reinicia: `pm2 restart reservas-central`.

## Lista de la compra (móvil)

Endpoints adicionales (JSON en `data/lista_compra.json`):

- `GET /api/lista-compra`
- `POST /api/lista-compra` (crear/editar: `{ nombre, cantidad?, hayQueComprar?, comprado?, id? }`)
- `PUT /api/lista-compra/:id`
- `POST /api/lista-compra/vaciar-compra` — resetea `hayQueComprar`/`comprado`; **no borra el catálogo**
- `POST /api/lista-compra/reordenar` — `{ "ids": [3,1,2] }` fija el orden del catálogo
- `GET /api/lista-compra/precios` — precios por producto/súper (`?productoId=&supermercadoId=`)
- `POST /api/lista-compra/precios` — `{ productoId, supermercadoId, precioEnvase, contenidoCantidad, contenidoUnidad }` → calcula `precioPorBase`
- `DELETE /api/lista-compra/precios/:id`
- Producto admite `unidadBase` (`kilo`|`litro`|`unidad`), `contenidoCantidad`, `contenidoUnidad`, `cantidadMinima` (envases a comprar, default 1)
- `DELETE /api/lista-compra/:id` (solo mantenimiento; la app móvil no lo usa al vaciar)

### Supermercados

- `GET /api/supermercados`
- `POST /api/supermercados` (`{ nombre, id?, orden? }`)
- `POST /api/supermercados/reordenar` — `{ "ids": [...] }`
- `PUT/DELETE /api/supermercados/:id`
- Datos en `data/supermercados.json` (IDs listos para asignar productos más adelante)

## PM2 útiles

```bash
pm2 logs reservas-central
pm2 restart reservas-central
pm2 stop reservas-central
```

## Alternativa Dart (solo referencia)

Si en el futuro quisieras Dart sin Flutter:

```bash
# Ubuntu 24.04
sudo apt-get install apt-transport-https
wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/dart.gpg
echo "deb [signed-by=/usr/share/keyrings/dart.gpg] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main" | sudo tee /etc/apt/sources.list.d/dart-stable.list
sudo apt-get update && sudo apt-get install dart
```

Luego haría falta un **paquete Dart nuevo** (`server/reservas_dart/`) con solo `shelf` + JSON, sin `flutter`, `isar` ni `path_provider`. No está en el repo hoy; el camino rápido es este servidor Node.
