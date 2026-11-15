-- Corrige reservas guardadas como "hora de pared" en UTC (bug app ↔ VPS).
-- Interpreta el reloj UTC almacenado como hora local Europe/Rome.
UPDATE reserva
SET fecha_hora_llegada =
  ((fecha_hora_llegada AT TIME ZONE 'UTC')::timestamp)
  AT TIME ZONE 'Europe/Rome';
