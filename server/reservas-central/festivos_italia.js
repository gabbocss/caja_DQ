/**
 * Festivos nacionales italianos + patrono de Módena (San Geminiano, 31 ene).
 * Zona: Europe/Rome.
 */

function pad(n) {
  return String(n).padStart(2, '0');
}

function ymd(y, m, d) {
  return `${y}-${pad(m)}-${pad(d)}`;
}

/** Domingo de Pascua (algoritmo de Meeus/Jones/Butcher). */
function pascua(year) {
  const a = year % 19;
  const b = Math.floor(year / 100);
  const c = year % 100;
  const d = Math.floor(b / 4);
  const e = b % 4;
  const f = Math.floor((b + 8) / 25);
  const g = Math.floor((b - f + 1) / 3);
  const h = (19 * a + b - d - g + 15) % 30;
  const i = Math.floor(c / 4);
  const k = c % 4;
  const l = (32 + 2 * e + 2 * i - h - k) % 7;
  const m = Math.floor((a + 11 * h + 22 * l) / 451);
  const month = Math.floor((h + l - 7 * m + 114) / 31);
  const day = ((h + l - 7 * m + 114) % 31) + 1;
  return { year, month, day };
}

function addDays(y, m, d, delta) {
  const dt = new Date(Date.UTC(y, m - 1, d + delta));
  return ymd(dt.getUTCFullYear(), dt.getUTCMonth() + 1, dt.getUTCDate());
}

/**
 * Mapa fecha ISO (YYYY-MM-DD) → nombre del festivo.
 */
function festivosDelAnio(year) {
  const map = new Map();
  const add = (fecha, nombre) => map.set(fecha, nombre);

  add(ymd(year, 1, 1), 'Capodanno');
  add(ymd(year, 1, 6), 'Epifania');
  add(ymd(year, 1, 31), 'San Geminiano (Módena)');
  add(ymd(year, 4, 25), 'Liberazione');
  add(ymd(year, 5, 1), 'Festa del Lavoro');
  add(ymd(year, 6, 2), 'Festa della Repubblica');
  add(ymd(year, 8, 15), 'Ferragosto');
  add(ymd(year, 11, 1), 'Ognissanti');
  add(ymd(year, 12, 8), 'Immacolata Concezione');
  add(ymd(year, 12, 25), 'Natale');
  add(ymd(year, 12, 26), 'Santo Stefano');

  const p = pascua(year);
  add(ymd(p.year, p.month, p.day), 'Pasqua');
  add(addDays(p.year, p.month, p.day, 1), 'Lunedì dell’Angelo');

  return map;
}

function infoFestivo(fechaIso) {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(String(fechaIso).slice(0, 10));
  if (!m) return { esFestivo: false, nombre: null };
  const year = Number(m[1]);
  const nombre = festivosDelAnio(year).get(`${m[1]}-${m[2]}-${m[3]}`) || null;
  return { esFestivo: Boolean(nombre), nombre };
}

/** 0=domingo … 6=sábado en Europe/Rome aproximado vía UTC+offset simple no; usamos Date local parse. */
function diaSemanaYFinde(fechaIso) {
  const [y, mo, d] = String(fechaIso).slice(0, 10).split('-').map(Number);
  // Mediodía UTC para evitar bordes DST al calcular weekday en IT.
  const dt = new Date(Date.UTC(y, mo - 1, d, 12, 0, 0));
  // getUTCDay: 0 domingo — correcto para calendario civil.
  const dow = dt.getUTCDay();
  return { diaSemana: dow, esFinde: dow === 0 || dow === 6 };
}

module.exports = {
  festivosDelAnio,
  infoFestivo,
  diaSemanaYFinde,
  pascua,
};
