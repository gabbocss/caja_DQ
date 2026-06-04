const fs = require('fs');
const path = require('path');

const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, 'data');
const DATA_FILE = path.join(DATA_DIR, 'reservas.json');
const PRODUCTOS_FILE = path.join(DATA_DIR, 'productos.json');

/** Tras marcar sincronizadas en caja, el VPS puede purgar pasado este tiempo (ms). */
const RESERVAS_PURGE_MS = Number(
  process.env.RESERVAS_PURGE_MS || String(30 * 24 * 60 * 60 * 1000),
);

function ensureDataDir() {
  if (!fs.existsSync(DATA_DIR)) {
    fs.mkdirSync(DATA_DIR, { recursive: true });
  }
}

function readAll() {
  ensureDataDir();
  if (!fs.existsSync(DATA_FILE)) {
    return [];
  }
  const raw = fs.readFileSync(DATA_FILE, 'utf8');
  if (!raw.trim()) return [];
  const data = JSON.parse(raw);
  return Array.isArray(data) ? data : [];
}

function writeAll(reservas) {
  ensureDataDir();
  fs.writeFileSync(DATA_FILE, JSON.stringify(reservas, null, 2), 'utf8');
}

function readProductos() {
  ensureDataDir();
  if (!fs.existsSync(PRODUCTOS_FILE)) {
    return [];
  }
  const raw = fs.readFileSync(PRODUCTOS_FILE, 'utf8');
  if (!raw.trim()) return [];
  const data = JSON.parse(raw);
  return Array.isArray(data) ? data : [];
}

function writeProductos(lista) {
  ensureDataDir();
  fs.writeFileSync(PRODUCTOS_FILE, JSON.stringify(lista, null, 2), 'utf8');
}

function nextId(reservas) {
  let max = 0;
  for (const r of reservas) {
    const id = Number(r.id);
    if (!Number.isNaN(id) && id > max) max = id;
  }
  return max + 1;
}

function purgeSincronizadasAntiguas(reservas) {
  const cutoff = Date.now() - RESERVAS_PURGE_MS;
  const kept = reservas.filter((r) => {
    if (!r.sincronizadaEnCajaAt) return true;
    const t = new Date(r.sincronizadaEnCajaAt).getTime();
    if (Number.isNaN(t)) return true;
    return t > cutoff;
  });
  if (kept.length < reservas.length) {
    writeAll(kept);
    return reservas.length - kept.length;
  }
  return 0;
}

function getPendientes() {
  const reservas = readAll();
  purgeSincronizadasAntiguas(reservas);
  const actuales = readAll();
  return actuales
    .filter((r) => r.estado === 'pendiente' && !r.sincronizadaEnCajaAt)
    .sort(
      (a, b) =>
        new Date(a.fechaHoraLlegada).getTime() -
        new Date(b.fechaHoraLlegada).getTime(),
    );
}

/**
 * La caja confirma que ya guardó en disco estos IDs (candado de seguridad).
 */
function marcarSincronizadas(ids) {
  const lista = Array.isArray(ids) ? ids : [];
  const idSet = new Set(
    lista.map((x) => Number(x)).filter((n) => !Number.isNaN(n) && n > 0),
  );
  const reservas = readAll();
  const now = new Date().toISOString();
  let marcadas = 0;
  for (const r of reservas) {
    if (idSet.has(Number(r.id))) {
      r.sincronizadaEnCajaAt = now;
      marcadas++;
    }
  }
  writeAll(reservas);
  const purgadas = purgeSincronizadasAntiguas(readAll());
  return {
    marcadas,
    ids: [...idSet],
    purgadas,
  };
}

function upsertReserva(body) {
  const reservas = readAll();
  const now = new Date().toISOString();
  let reserva = { ...body };

  if (reserva.id != null) {
    const id = Number(reserva.id);
    const idx = reservas.findIndex((r) => Number(r.id) === id);
    if (idx >= 0) {
      reserva = {
        ...reservas[idx],
        ...reserva,
        id,
        fechaCreacion: reservas[idx].fechaCreacion || now,
        fechaActualizacion: now,
      };
      delete reserva.sincronizadaEnCajaAt;
      reservas[idx] = reserva;
      writeAll(reservas);
      return reserva;
    }
  }

  reserva.id = nextId(reservas);
  reserva.fechaCreacion = reserva.fechaCreacion || now;
  reserva.fechaActualizacion = now;
  reserva.estado = reserva.estado || 'pendiente';
  reserva.itemsReservados = reserva.itemsReservados || [];
  reservas.push(reserva);
  writeAll(reservas);
  return reserva;
}

function updateEstado(id, estado, mesaAsignada) {
  const reservas = readAll();
  const idx = reservas.findIndex((r) => Number(r.id) === Number(id));
  if (idx < 0) return null;
  reservas[idx].estado = estado;
  if (mesaAsignada != null) reservas[idx].mesaAsignada = mesaAsignada;
  reservas[idx].fechaActualizacion = new Date().toISOString();
  writeAll(reservas);
  return reservas[idx];
}

/** Reemplaza el catálogo completo (POST array desde la caja). */
function replaceProductos(body) {
  const lista = Array.isArray(body) ? body : [body];
  writeProductos(lista);
  return lista;
}

module.exports = {
  DATA_FILE,
  PRODUCTOS_FILE,
  readAll,
  getPendientes,
  marcarSincronizadas,
  upsertReserva,
  updateEstado,
  readProductos,
  replaceProductos,
};
