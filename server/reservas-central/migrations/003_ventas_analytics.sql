-- Fase 3: histórico de ventas para ML / CRM (sin purge corto).

CREATE TABLE IF NOT EXISTS venta (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  idempotency_key TEXT NOT NULL,
  fecha_cierre TIMESTAMPTZ NOT NULL,
  servicio TEXT NOT NULL
    CHECK (servicio IN ('comida', 'cena', 'otro')),
  origen TEXT NOT NULL DEFAULT 'walkin'
    CHECK (origen IN ('reserva', 'walkin', 'qr', 'asporto', 'web', 'otro')),
  cliente_id BIGINT REFERENCES cliente (id) ON DELETE SET NULL,
  reserva_id BIGINT REFERENCES reserva (id) ON DELETE SET NULL,
  mesa_numero BIGINT,
  comensales BIGINT,
  duracion_minutos BIGINT,
  total NUMERIC(12, 2) NOT NULL DEFAULT 0,
  es_buffet BOOLEAN NOT NULL DEFAULT false,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS venta_idempotency_key_uidx
  ON venta (idempotency_key);

CREATE INDEX IF NOT EXISTS venta_fecha_cierre_idx
  ON venta (fecha_cierre DESC);

CREATE INDEX IF NOT EXISTS venta_servicio_fecha_idx
  ON venta (servicio, fecha_cierre);

CREATE INDEX IF NOT EXISTS venta_cliente_id_idx
  ON venta (cliente_id);

CREATE INDEX IF NOT EXISTS venta_reserva_id_idx
  ON venta (reserva_id);

CREATE TABLE IF NOT EXISTS venta_item (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  venta_id BIGINT NOT NULL REFERENCES venta (id) ON DELETE CASCADE,
  producto_id BIGINT NOT NULL,
  nombre_producto TEXT NOT NULL,
  cantidad BIGINT NOT NULL CHECK (cantidad > 0),
  precio_unitario NUMERIC(12, 2) NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS venta_item_venta_id_idx
  ON venta_item (venta_id);

CREATE INDEX IF NOT EXISTS venta_item_producto_id_idx
  ON venta_item (producto_id);
