# API de reservas 24/7 (Node.js + PostgreSQL)

Servidor HTTP **sin Flutter**, compatible con `ApiClient` de programa_caja (`GET /api`, `GET /api/reservas`, etc.).

**Fase 0–3:** reservas y **ventas/analytics** en **PostgreSQL**. Teléfono opcional → `cliente`. Cierres de mesa → `POST /api/analytics/venta` (sin purge de 30 días). Productos / lista compra / supermercados aún en JSON hasta la fase 4.

## Requisitos

- Node.js ≥ 18
- PostgreSQL ≥ 14 (16 recomendado)
- Variable `DATABASE_URL` (obligatoria)

## Arranque rápido (Docker Compose)

```bash
cd server/reservas-central
cp .env.example .env
docker compose up -d
npm install
npm run migrate
# Opcional: importar el JSON antiguo
npm run import:reservas
npm start
```

`DATABASE_URL` por defecto en `.env.example`:

`postgresql://caja:caja@127.0.0.1:5432/programa_caja`

## Instalación en VPS (Ubuntu)

### 1. PostgreSQL

```bash
cd ~/reservas-central
sudo bash scripts/setup-postgres-vps.sh
# Opcional: DB_PASS=secreto sudo -E bash scripts/setup-postgres-vps.sh
```

### 2. Subir código y dependencias

```bash
# En tu PC
rsync -avz --exclude node_modules --exclude data \
  server/reservas-central/ usuario@TU_VPS:~/reservas-central/
```

```bash
# En el VPS
cd ~/reservas-central
cp .env.example .env   # edita DATABASE_URL y contraseña
npm install
npm run migrate
# Si aún tienes el JSON antiguo en data/reservas.json:
npm run import:reservas
pm2 start ecosystem.config.cjs   # o: pm2 restart reservas-central
pm2 save
```

### 3. Comprobar

```bash
curl -s http://127.0.0.1:8888/api | jq .
curl -s http://127.0.0.1:8888/health | jq .
curl -s http://127.0.0.1:8888/api/reservas
```

`/health` debe indicar `"reservas": "postgresql"`.

### 4. Firewall / proxy

- Puerto **8888**, o Nginx/Caddy → `127.0.0.1:8888`

### 5. App (Configuración → Servidor central)

- HTTP: `http://TU_VPS:8888`
- HTTPS con proxy en 443

## Variables de entorno

| Variable | Default | Descripción |
|----------|---------|-------------|
| `DATABASE_URL` | *(obligatoria)* | Conexión Postgres |
| `PORT` | `8888` | Puerto HTTP |
| `HOST` | `0.0.0.0` | Interfaz |
| `DATA_DIR` | `./data` | JSON legacy (productos, compra, …) |
| `RESERVAS_PURGE_MS` | `2592000000` (30 días) | Borra reservas operativas antiguas por `fecha_hora_llegada` |
| `PG_POOL_MAX` | `10` | Tamaño del pool `pg` |

Puedes ponerlas en `.env` (cargado al arrancar) o en `ecosystem.config.cjs`.

## Scripts npm

| Script | Qué hace |
|--------|----------|
| `npm start` | Arranca API (aplica migraciones al inicio) |
| `npm run migrate` | Solo aplica `migrations/*.sql` |
| `npm run import:reservas` | Importa `data/reservas.json` → Postgres |

## Esquema (fase 0)

- `schema_migrations` — control de migraciones
- `reserva` — cabecera (mismo contrato API camelCase)
- `reserva_item` — ítems anticipados (`ON DELETE CASCADE`)

Migraciones en `migrations/001_init_reservas.sql`.

## Sincronización caja ← VPS

1. La caja hace `GET /api/reservas` (`pendiente` y `cancelada` dentro de la retención).
2. Fusiona en Isar por **id** (sin pisar `sentada`/`cobrada` locales).
3. `POST /api/reservas/marcar-sincronizadas` es **no-op** (compatibilidad).

## Lista de la compra / supermercados

Siguen en JSON bajo `DATA_DIR` (misma API de siempre). Se migrarán a Postgres en la fase 4.

## PM2

```bash
pm2 logs reservas-central
pm2 restart reservas-central
pm2 stop reservas-central
```
