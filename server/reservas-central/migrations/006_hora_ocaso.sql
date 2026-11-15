-- Hora a la que oscurece (puesta de sol Open-Meteo, Europe/Rome / Módena).
ALTER TABLE contexto_dia
  ADD COLUMN IF NOT EXISTS hora_ocaso TIMESTAMPTZ;
