-- Fase 6: índices para predicción diaria (histórico × servicio × producto).

CREATE INDEX IF NOT EXISTS venta_fecha_rome_servicio_idx
  ON venta (
    (date(timezone('Europe/Rome', fecha_cierre))),
    servicio
  );

CREATE INDEX IF NOT EXISTS venta_cliente_servicio_idx
  ON venta (cliente_id, servicio)
  WHERE cliente_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS reserva_llegada_rome_estado_idx
  ON reserva (
    (date(timezone('Europe/Rome', fecha_hora_llegada))),
    estado
  );
