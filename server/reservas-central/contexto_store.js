/**
 * Contexto diario: festivos (Italia/Módena) + clima Open-Meteo.
 */
const db = require('./db');
const { infoFestivo, diaSemanaYFinde } = require('./festivos_italia');

// Módena centro
const LAT = Number(process.env.CLIMA_LAT || 44.6471);
const LON = Number(process.env.CLIMA_LON || 10.9252);
const TZ = process.env.CLIMA_TZ || 'Europe/Rome';

const WMO = {
  0: 'Despejado',
  1: 'Principalmente despejado',
  2: 'Parcialmente nublado',
  3: 'Nublado',
  45: 'Niebla',
  48: 'Niebla con escarcha',
  51: 'Llovizna ligera',
  53: 'Llovizna',
  55: 'Llovizna intensa',
  61: 'Lluvia ligera',
  63: 'Lluvia',
  65: 'Lluvia intensa',
  71: 'Nieve ligera',
  73: 'Nieve',
  75: 'Nieve intensa',
  80: 'Chubascos',
  81: 'Chubascos fuertes',
  82: 'Chubascos violentos',
  95: 'Tormenta',
  96: 'Tormenta con granizo',
  99: 'Tormenta fuerte con granizo',
};

function fechaSolo(value) {
  if (!value) {
    const n = new Date();
    return n.toISOString().slice(0, 10);
  }
  return String(value).slice(0, 10);
}

/** Formatea puesta de sol en HH:MM (Europe/Rome). */
function formatHoraLocal(value) {
  if (value == null) return null;
  const d = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(d.getTime())) return null;
  return new Intl.DateTimeFormat('it-IT', {
    timeZone: TZ,
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).format(d);
}

function mapContexto(row) {
  return {
    fecha: row.fecha instanceof Date
      ? row.fecha.toISOString().slice(0, 10)
      : String(row.fecha).slice(0, 10),
    esFestivo: Boolean(row.es_festivo),
    nombreFestivo: row.nombre_festivo || null,
    esFinde: Boolean(row.es_finde),
    diaSemana: Number(row.dia_semana),
    tempMedia: row.temp_media == null ? null : Number(row.temp_media),
    tempMin: row.temp_min == null ? null : Number(row.temp_min),
    tempMax: row.temp_max == null ? null : Number(row.temp_max),
    precipitacionMm:
      row.precipitacion_mm == null ? null : Number(row.precipitacion_mm),
    codigoClima: row.codigo_clima == null ? null : Number(row.codigo_clima),
    climaResumen: row.clima_resumen || null,
    horaOcaso: row.hora_ocaso
      ? row.hora_ocaso instanceof Date
        ? row.hora_ocaso.toISOString()
        : String(row.hora_ocaso)
      : null,
    /** Hora local Módena a la que oscurece (puesta de sol), p. ej. "16:52". */
    horaOscurece: formatHoraLocal(row.hora_ocaso),
    actualizadoEn: row.actualizado_en,
  };
}

async function fetchClimaDia(fecha) {
  const dailyVars =
    'temperature_2m_max,temperature_2m_min,temperature_2m_mean,precipitation_sum,weathercode,sunset';
  const url =
    `https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}` +
    `&daily=${dailyVars}` +
    `&timezone=${encodeURIComponent(TZ)}&start_date=${fecha}&end_date=${fecha}`;
  // Histórico reciente / pasado: archive API
  const archiveUrl =
    `https://archive-api.open-meteo.com/v1/archive?latitude=${LAT}&longitude=${LON}` +
    `&daily=${dailyVars}` +
    `&timezone=${encodeURIComponent(TZ)}&start_date=${fecha}&end_date=${fecha}`;

  const hoy = new Date().toISOString().slice(0, 10);
  const useArchive = fecha < hoy;

  try {
    const res = await fetch(useArchive ? archiveUrl : url);
    if (!res.ok) throw new Error(`Open-Meteo HTTP ${res.status}`);
    const data = await res.json();
    const daily = data.daily || {};
    const idx = 0;
    if (!daily.time || !daily.time[idx]) return null;
    const code = daily.weathercode ? daily.weathercode[idx] : null;
    const tMax = daily.temperature_2m_max ? daily.temperature_2m_max[idx] : null;
    const tMin = daily.temperature_2m_min ? daily.temperature_2m_min[idx] : null;
    const tMean = daily.temperature_2m_mean
      ? daily.temperature_2m_mean[idx]
      : tMax != null && tMin != null
        ? (tMax + tMin) / 2
        : null;
    const precip = daily.precipitation_sum
      ? daily.precipitation_sum[idx]
      : null;
    const sunsetRaw = daily.sunset ? daily.sunset[idx] : null;
    const sunset =
      sunsetRaw != null && String(sunsetRaw).trim() !== ''
        ? new Date(sunsetRaw)
        : null;
    return {
      tempMedia: tMean,
      tempMin: tMin,
      tempMax: tMax,
      precipitacionMm: precip,
      codigoClima: code,
      climaResumen: code != null ? WMO[code] || `Código ${code}` : null,
      horaOcaso:
        sunset && !Number.isNaN(sunset.getTime()) ? sunset.toISOString() : null,
    };
  } catch (e) {
    console.error('Clima Open-Meteo:', e.message || e);
    return null;
  }
}

/**
 * Crea o actualiza el contexto del día (festivo + clima).
 */
async function asegurarContextoDia(fechaRaw) {
  const fecha = fechaSolo(fechaRaw);
  const fest = infoFestivo(fecha);
  const { diaSemana, esFinde } = diaSemanaYFinde(fecha);
  const clima = await fetchClimaDia(fecha);

  const res = await db.query(
    `INSERT INTO contexto_dia (
       fecha, es_festivo, nombre_festivo, es_finde, dia_semana,
       temp_media, temp_min, temp_max, precipitacion_mm, codigo_clima,
       clima_resumen, hora_ocaso, actualizado_en
     ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,now())
     ON CONFLICT (fecha) DO UPDATE SET
       es_festivo = EXCLUDED.es_festivo,
       nombre_festivo = EXCLUDED.nombre_festivo,
       es_finde = EXCLUDED.es_finde,
       dia_semana = EXCLUDED.dia_semana,
       temp_media = COALESCE(EXCLUDED.temp_media, contexto_dia.temp_media),
       temp_min = COALESCE(EXCLUDED.temp_min, contexto_dia.temp_min),
       temp_max = COALESCE(EXCLUDED.temp_max, contexto_dia.temp_max),
       precipitacion_mm = COALESCE(EXCLUDED.precipitacion_mm, contexto_dia.precipitacion_mm),
       codigo_clima = COALESCE(EXCLUDED.codigo_clima, contexto_dia.codigo_clima),
       clima_resumen = COALESCE(EXCLUDED.clima_resumen, contexto_dia.clima_resumen),
       hora_ocaso = COALESCE(EXCLUDED.hora_ocaso, contexto_dia.hora_ocaso),
       actualizado_en = now()
     RETURNING *`,
    [
      fecha,
      fest.esFestivo,
      fest.nombre,
      esFinde,
      diaSemana,
      clima?.tempMedia ?? null,
      clima?.tempMin ?? null,
      clima?.tempMax ?? null,
      clima?.precipitacionMm ?? null,
      clima?.codigoClima ?? null,
      clima?.climaResumen ?? null,
      clima?.horaOcaso ?? null,
    ],
  );
  return mapContexto(res.rows[0]);
}

async function getContextoDia(fechaRaw) {
  const fecha = fechaSolo(fechaRaw);
  const res = await db.query(
    `SELECT * FROM contexto_dia WHERE fecha = $1`,
    [fecha],
  );
  if (res.rowCount > 0) return mapContexto(res.rows[0]);
  return asegurarContextoDia(fecha);
}

async function listarContextos({ desde, hasta, limit } = {}) {
  const lim = Math.min(Math.max(Number(limit) || 90, 1), 366);
  const params = [];
  const where = [];
  if (desde) {
    params.push(fechaSolo(desde));
    where.push(`fecha >= $${params.length}`);
  }
  if (hasta) {
    params.push(fechaSolo(hasta));
    where.push(`fecha <= $${params.length}`);
  }
  params.push(lim);
  const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const res = await db.query(
    `SELECT * FROM contexto_dia
     ${whereSql}
     ORDER BY fecha DESC
     LIMIT $${params.length}`,
    params,
  );
  return res.rows.map(mapContexto);
}

module.exports = {
  asegurarContextoDia,
  getContextoDia,
  listarContextos,
  fechaSolo,
  LAT,
  LON,
};
