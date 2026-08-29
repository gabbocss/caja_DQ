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
| `RESERVAS_PURGE_MS` | `2592000000` (30 días) | Tras confirmar sync en caja, borrar del VPS pasado este tiempo |

### Candado de sincronización (caja → VPS)

1. La caja hace `GET /api/reservas` (pendientes nuevas, reeditadas o canceladas aún no confirmadas).
2. Fusiona en Isar + `reservas_backup.json` (el histórico local no se borra).
3. `POST /api/reservas/marcar-sincronizadas` con `{ "ids": [1, 2, 3] }`.
4. El VPS deja de devolver esas reservas en el GET de sync y, tras `RESERVAS_PURGE_MS`, las elimina de `reservas.json`.

### Edición desde la app móvil (fase 2)

- `GET /api/reservas?incluye=sincronizadas` devuelve **todas** las reservas con `estado: pendiente`, incluidas las ya confirmadas en caja (`sincronizadaEnCajaAt` presente).
- Al editar (`POST /api/reservas` con `id`), el VPS borra `sincronizadaEnCajaAt` y la caja vuelve a descargarla en el siguiente sync.
- Al cancelar (`PUT /api/reservas/<id>/estado`), también se reencola para la caja.

Tras desplegar, reinicia: `pm2 restart reservas-central`.

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
