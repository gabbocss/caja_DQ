const fs = require('fs');
const path = require('path');

const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, 'data');
const DATA_FILE = path.join(DATA_DIR, 'reservas.json');

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

function nextId(reservas) {
  let max = 0;
  for (const r of reservas) {
    const id = Number(r.id);
    if (!Number.isNaN(id) && id > max) max = id;
  }
  return max + 1;
}

function getPendientes() {
  return readAll()
    .filter((r) => r.estado === 'pendiente')
    .sort(
      (a, b) =>
        new Date(a.fechaHoraLlegada).getTime() -
        new Date(b.fechaHoraLlegada).getTime(),
    );
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

module.exports = {
  DATA_FILE,
  readAll,
  getPendientes,
  upsertReserva,
  updateEstado,
};
