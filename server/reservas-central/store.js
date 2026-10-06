const fs = require('fs');
const path = require('path');

const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, 'data');
const DATA_FILE = path.join(DATA_DIR, 'reservas.json');
const PRODUCTOS_FILE = path.join(DATA_DIR, 'productos.json');
const LISTA_COMPRA_FILE = path.join(DATA_DIR, 'lista_compra.json');
const SUPERMERCADOS_FILE = path.join(DATA_DIR, 'supermercados.json');
const PRECIOS_LISTA_COMPRA_FILE = path.join(DATA_DIR, 'precios_lista_compra.json');

/** Purga reservas cuya fechaHoraLlegada es más antigua que este margen (ms). */
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

/** Mantiene reservas con llegada dentro de la ventana de retención. */
function purgeAntiguasPorFechaLlegada(reservas) {
  const cutoff = Date.now() - RESERVAS_PURGE_MS;
  const kept = reservas.filter((r) => {
    const t = new Date(r.fechaHoraLlegada).getTime();
    if (Number.isNaN(t)) return true;
    return t > cutoff;
  });
  if (kept.length < reservas.length) {
    writeAll(kept);
    return reservas.length - kept.length;
  }
  return 0;
}

function sortPorLlegada(lista) {
  return lista.sort(
    (a, b) =>
      new Date(a.fechaHoraLlegada).getTime() -
      new Date(b.fechaHoraLlegada).getTime(),
  );
}

/**
 * Reservas para la caja: pendientes y canceladas (la caja hace upsert por id).
 * Ya no se filtra por sincronizadaEnCajaAt.
 */
function getPendientes() {
  const reservas = readAll();
  purgeAntiguasPorFechaLlegada(reservas);
  let actuales = readAll();
  actuales = stripLegacySyncFlags(actuales);
  return sortPorLlegada(
    actuales.filter(
      (r) => r.estado === 'pendiente' || r.estado === 'cancelada',
    ),
  );
}

/**
 * Pendientes editables (app móvil). Misma fuente de verdad; sin candado de sync.
 * GET /api/reservas?incluye=sincronizadas se mantiene por compatibilidad.
 */
function getPendientesEditables() {
  const reservas = readAll();
  purgeAntiguasPorFechaLlegada(reservas);
  let actuales = readAll();
  actuales = stripLegacySyncFlags(actuales);
  return sortPorLlegada(actuales.filter((r) => r.estado === 'pendiente'));
}

/** Elimina marcas legacy sincronizadaEnCajaAt (ya no se usan). */
function stripLegacySyncFlags(reservas) {
  let changed = false;
  for (const r of reservas) {
    if (r.sincronizadaEnCajaAt != null) {
      delete r.sincronizadaEnCajaAt;
      changed = true;
    }
  }
  if (changed) writeAll(reservas);
  return reservas;
}

/**
 * @deprecated El sync es por id + fechaActualizacion en la caja.
 * Se mantiene el endpoint como no-op para clientes antiguos.
 */
function marcarSincronizadas(ids) {
  const lista = Array.isArray(ids) ? ids : [];
  const idSet = new Set(
    lista.map((x) => Number(x)).filter((n) => !Number.isNaN(n) && n > 0),
  );
  // Limpia marcas legacy si existen (ya no afectan al GET).
  const reservas = readAll();
  let limpiadas = 0;
  for (const r of reservas) {
    if (idSet.has(Number(r.id)) && r.sincronizadaEnCajaAt != null) {
      delete r.sincronizadaEnCajaAt;
      limpiadas++;
    }
  }
  if (limpiadas > 0) writeAll(reservas);
  const purgadas = purgeAntiguasPorFechaLlegada(readAll());
  return {
    marcadas: 0,
    ids: [...idSet],
    purgadas,
    deprecated: true,
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
      // Campo legacy; la caja ya no depende de él.
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
  delete reserva.sincronizadaEnCajaAt;
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
  delete reservas[idx].sincronizadaEnCajaAt;
  writeAll(reservas);
  return reservas[idx];
}

/** Reemplaza el catálogo completo (POST array desde la caja). */
function replaceProductos(body) {
  const lista = Array.isArray(body) ? body : [body];
  writeProductos(lista);
  return lista;
}

function readListaCompra() {
  ensureDataDir();
  if (!fs.existsSync(LISTA_COMPRA_FILE)) {
    return [];
  }
  const raw = fs.readFileSync(LISTA_COMPRA_FILE, 'utf8');
  if (!raw.trim()) return [];
  const data = JSON.parse(raw);
  return Array.isArray(data) ? data : [];
}

function writeListaCompra(items) {
  ensureDataDir();
  fs.writeFileSync(LISTA_COMPRA_FILE, JSON.stringify(items, null, 2), 'utf8');
}

function nextListaCompraId(items) {
  let max = 0;
  for (const item of items) {
    const id = Number(item.id);
    if (!Number.isNaN(id) && id > max) max = id;
  }
  return max + 1;
}

function normalizarZona(v) {
  return String(v || '').toLowerCase() === 'sala' ? 'sala' : 'cocina';
}

/** Súper asignado al producto; null = sin asignar. */
function normalizarSupermercadoId(value) {
  if (value == null || value === '') return null;
  const n = Number(value);
  return Number.isFinite(n) && n > 0 ? Math.floor(n) : null;
}

function normalizarItemListaCompra(item, now) {
  const hayQueComprar = Boolean(item.hayQueComprar);
  const comprado = hayQueComprar ? Boolean(item.comprado) : false;
  const ordenRaw = Number(item.orden);
  const orden = Number.isNaN(ordenRaw) ? 0 : ordenRaw;
  const urlMetroRaw = item.urlMetro != null
    ? String(item.urlMetro).trim()
    : '';
  const urlCc = String(item.urlCc || '').trim();
  // Migración: urlProveedor antiguo → urlMetro.
  const urlMetro =
    urlMetroRaw || String(item.urlProveedor || '').trim();
  return {
    id: Number(item.id),
    nombre: String(item.nombre || '').trim(),
    cantidad: item.cantidad != null ? String(item.cantidad) : '',
    hayQueComprar,
    comprado,
    orden,
    zona: normalizarZona(item.zona),
    supermercadoId: normalizarSupermercadoId(item.supermercadoId),
    urlMetro,
    urlCc,
    fechaCreacion: item.fechaCreacion || now,
    fechaActualizacion: now,
  };
}

function nextOrden(items) {
  let max = -1;
  for (const item of items) {
    const o = Number(item.orden);
    if (!Number.isNaN(o) && o > max) max = o;
  }
  return max + 1;
}

/** Orden fijo del catálogo (no cambia al marcar hayQueComprar/comprado). */
function getListaCompra() {
  const items = readListaCompra();
  let needsWrite = false;
  for (let i = 0; i < items.length; i++) {
    const o = Number(items[i].orden);
    if (items[i].orden == null || Number.isNaN(o)) {
      items[i].orden = i;
      needsWrite = true;
    }
    const zona = normalizarZona(items[i].zona);
    if (items[i].zona !== zona) {
      items[i].zona = zona;
      needsWrite = true;
    }
  }
  if (needsWrite) writeListaCompra(items);
  return [...items].sort((a, b) => Number(a.orden) - Number(b.orden));
}

function upsertItemListaCompra(body) {
  const items = readListaCompra();
  const now = new Date().toISOString();
  let item = { ...body };

  if (item.id != null) {
    const id = Number(item.id);
    const idx = items.findIndex((x) => Number(x.id) === id);
    if (idx >= 0) {
      const merged = {
        ...items[idx],
        ...item,
        id,
        nombre: String(item.nombre ?? items[idx].nombre ?? '').trim(),
        cantidad:
          item.cantidad != null ? String(item.cantidad) : items[idx].cantidad || '',
        hayQueComprar:
          item.hayQueComprar != null
            ? Boolean(item.hayQueComprar)
            : Boolean(items[idx].hayQueComprar),
        comprado:
          item.comprado != null
            ? Boolean(item.comprado)
            : Boolean(items[idx].comprado),
        orden:
          item.orden != null ? Number(item.orden) : Number(items[idx].orden ?? idx),
        zona: item.zona != null ? item.zona : items[idx].zona,
        supermercadoId:
          item.supermercadoId !== undefined
            ? item.supermercadoId
            : items[idx].supermercadoId,
        urlMetro:
          item.urlMetro != null
            ? item.urlMetro
            : item.urlProveedor != null
              ? item.urlProveedor
              : items[idx].urlMetro ?? items[idx].urlProveedor,
        urlCc:
          item.urlCc != null ? item.urlCc : items[idx].urlCc,
        fechaCreacion: items[idx].fechaCreacion || now,
      };
      if (!merged.nombre) {
        throw new Error('El nombre es obligatorio');
      }
      item = normalizarItemListaCompra(merged, now);
      items[idx] = item;
      writeListaCompra(items);
      return item;
    }
  }

  const nombre = String(item.nombre || '').trim();
  if (!nombre) {
    throw new Error('El nombre es obligatorio');
  }
  item = normalizarItemListaCompra(
    {
      id: nextListaCompraId(items),
      nombre,
      cantidad: item.cantidad != null ? String(item.cantidad) : '',
      hayQueComprar: Boolean(item.hayQueComprar),
      comprado: Boolean(item.comprado),
      orden: item.orden != null ? Number(item.orden) : nextOrden(items),
      zona: item.zona,
      supermercadoId: item.supermercadoId,
      urlMetro: item.urlMetro != null ? item.urlMetro : item.urlProveedor,
      urlCc: item.urlCc,
      fechaCreacion: now,
    },
    now,
  );
  items.push(item);
  writeListaCompra(items);
  return item;
}

function updateItemListaCompra(id, body) {
  const items = readListaCompra();
  const idx = items.findIndex((x) => Number(x.id) === Number(id));
  if (idx < 0) return null;
  const now = new Date().toISOString();
  const actual = items[idx];
  const nombre =
    body.nombre != null ? String(body.nombre).trim() : actual.nombre;
  if (!nombre) {
    throw new Error('El nombre es obligatorio');
  }
  const merged = {
    ...actual,
    ...body,
    id: Number(id),
    nombre,
    cantidad:
      body.cantidad != null ? String(body.cantidad) : actual.cantidad || '',
    hayQueComprar:
      body.hayQueComprar != null
        ? Boolean(body.hayQueComprar)
        : Boolean(actual.hayQueComprar),
    comprado:
      body.comprado != null ? Boolean(body.comprado) : Boolean(actual.comprado),
    orden: body.orden != null ? Number(body.orden) : Number(actual.orden ?? idx),
    fechaCreacion: actual.fechaCreacion || now,
  };
  items[idx] = normalizarItemListaCompra(merged, now);
  writeListaCompra(items);
  return items[idx];
}

/**
 * Fija el orden del catálogo según la lista de ids (posición 0..n-1).
 * Los ids desconocidos se ignoran; los no enviados quedan al final.
 */
function reordenarListaCompra(ids) {
  const items = readListaCompra();
  const byId = new Map(items.map((i) => [Number(i.id), i]));
  const now = new Date().toISOString();
  const ordered = [];
  let orden = 0;
  const lista = Array.isArray(ids) ? ids : [];

  for (const rawId of lista) {
    const id = Number(rawId);
    const item = byId.get(id);
    if (!item) continue;
    ordered.push(
      normalizarItemListaCompra({ ...item, orden }, now),
    );
    orden += 1;
    byId.delete(id);
  }

  for (const item of byId.values()) {
    ordered.push(
      normalizarItemListaCompra({ ...item, orden }, now),
    );
    orden += 1;
  }

  writeListaCompra(ordered);
  return getListaCompra();
}

/**
 * Resetea la compra actual sin borrar el catálogo.
 * Todos los productos quedan con hayQueComprar=false y comprado=false.
 */
function vaciarCompraListaCompra() {
  const now = new Date().toISOString();
  const items = readListaCompra().map((item) =>
    normalizarItemListaCompra(
      {
        ...item,
        hayQueComprar: false,
        comprado: false,
      },
      now,
    ),
  );
  writeListaCompra(items);
  return { ok: true, reseteados: items.length, items: getListaCompra() };
}

function deleteItemListaCompra(id) {
  const items = readListaCompra();
  const filtrados = items.filter((x) => Number(x.id) !== Number(id));
  if (filtrados.length === items.length) return false;
  writeListaCompra(filtrados);
  return true;
}

// ==================== PRECIOS POR SUPERMERCADO ====================

function readPreciosListaCompra() {
  ensureDataDir();
  if (!fs.existsSync(PRECIOS_LISTA_COMPRA_FILE)) {
    return [];
  }
  const raw = fs.readFileSync(PRECIOS_LISTA_COMPRA_FILE, 'utf8');
  if (!raw.trim()) return [];
  const data = JSON.parse(raw);
  return Array.isArray(data) ? data : [];
}

function writePreciosListaCompra(items) {
  ensureDataDir();
  fs.writeFileSync(
    PRECIOS_LISTA_COMPRA_FILE,
    JSON.stringify(items, null, 2),
    'utf8',
  );
}

function nextPrecioId(items) {
  let max = 0;
  for (const item of items) {
    const id = Number(item.id);
    if (!Number.isNaN(id) && id > max) max = id;
  }
  return max + 1;
}

function getPreciosListaCompra(filtro = {}) {
  let items = readPreciosListaCompra();
  if (filtro.productoId != null) {
    const pid = Number(filtro.productoId);
    items = items.filter((p) => Number(p.productoId) === pid);
  }
  if (filtro.supermercadoId != null) {
    const sid = Number(filtro.supermercadoId);
    items = items.filter((p) => Number(p.supermercadoId) === sid);
  }
  return items.sort(
    (a, b) => new Date(b.fecha || 0).getTime() - new Date(a.fecha || 0).getTime(),
  );
}

/**
 * Legacy: precios por súper (ya no usados por la app).
 */
function upsertPrecioListaCompra() {
  throw new Error('Los precios de lista de compra ya no están soportados');
}

function deletePrecioListaCompra(id) {
  const items = readPreciosListaCompra();
  const filtrados = items.filter((x) => Number(x.id) !== Number(id));
  if (filtrados.length === items.length) return false;
  writePreciosListaCompra(filtrados);
  return true;
}

// ==================== SUPERMERCADOS ====================

function readSupermercados() {
  ensureDataDir();
  if (!fs.existsSync(SUPERMERCADOS_FILE)) {
    return [];
  }
  const raw = fs.readFileSync(SUPERMERCADOS_FILE, 'utf8');
  if (!raw.trim()) return [];
  const data = JSON.parse(raw);
  return Array.isArray(data) ? data : [];
}

function writeSupermercados(items) {
  ensureDataDir();
  fs.writeFileSync(SUPERMERCADOS_FILE, JSON.stringify(items, null, 2), 'utf8');
}

function nextSupermercadoId(items) {
  let max = 0;
  for (const item of items) {
    const id = Number(item.id);
    if (!Number.isNaN(id) && id > max) max = id;
  }
  return max + 1;
}

function nextSupermercadoOrden(items) {
  let max = -1;
  for (const item of items) {
    const o = Number(item.orden);
    if (!Number.isNaN(o) && o > max) max = o;
  }
  return max + 1;
}

function normalizarSupermercado(item, now) {
  const ordenRaw = Number(item.orden);
  return {
    ...item,
    nombre: String(item.nombre || '').trim(),
    orden: Number.isNaN(ordenRaw) ? 0 : ordenRaw,
    fechaActualizacion: now,
  };
}

function getSupermercados() {
  const items = readSupermercados();
  let needsWrite = false;
  for (let i = 0; i < items.length; i++) {
    const o = Number(items[i].orden);
    if (items[i].orden == null || Number.isNaN(o)) {
      items[i].orden = i;
      needsWrite = true;
    }
  }
  if (needsWrite) writeSupermercados(items);
  return [...items].sort((a, b) => Number(a.orden) - Number(b.orden));
}

function upsertSupermercado(body) {
  const items = readSupermercados();
  const now = new Date().toISOString();
  let item = { ...body };

  if (item.id != null) {
    const id = Number(item.id);
    const idx = items.findIndex((x) => Number(x.id) === id);
    if (idx >= 0) {
      const nombre = String(item.nombre ?? items[idx].nombre ?? '').trim();
      if (!nombre) throw new Error('El nombre es obligatorio');
      item = normalizarSupermercado(
        {
          ...items[idx],
          ...item,
          id,
          nombre,
          orden:
            item.orden != null
              ? Number(item.orden)
              : Number(items[idx].orden ?? idx),
          fechaCreacion: items[idx].fechaCreacion || now,
        },
        now,
      );
      items[idx] = item;
      writeSupermercados(items);
      return item;
    }
  }

  const nombre = String(item.nombre || '').trim();
  if (!nombre) throw new Error('El nombre es obligatorio');
  item = normalizarSupermercado(
    {
      id: nextSupermercadoId(items),
      nombre,
      orden: item.orden != null ? Number(item.orden) : nextSupermercadoOrden(items),
      fechaCreacion: now,
    },
    now,
  );
  items.push(item);
  writeSupermercados(items);
  return item;
}

function updateSupermercado(id, body) {
  const items = readSupermercados();
  const idx = items.findIndex((x) => Number(x.id) === Number(id));
  if (idx < 0) return null;
  const now = new Date().toISOString();
  const actual = items[idx];
  const nombre =
    body.nombre != null ? String(body.nombre).trim() : actual.nombre;
  if (!nombre) throw new Error('El nombre es obligatorio');
  items[idx] = normalizarSupermercado(
    {
      ...actual,
      ...body,
      id: Number(id),
      nombre,
      orden:
        body.orden != null ? Number(body.orden) : Number(actual.orden ?? idx),
      fechaCreacion: actual.fechaCreacion || now,
    },
    now,
  );
  writeSupermercados(items);
  return items[idx];
}

function reordenarSupermercados(ids) {
  const items = readSupermercados();
  const byId = new Map(items.map((i) => [Number(i.id), i]));
  const now = new Date().toISOString();
  const ordered = [];
  let orden = 0;
  const lista = Array.isArray(ids) ? ids : [];

  for (const rawId of lista) {
    const id = Number(rawId);
    const item = byId.get(id);
    if (!item) continue;
    ordered.push(normalizarSupermercado({ ...item, orden }, now));
    orden += 1;
    byId.delete(id);
  }
  for (const item of byId.values()) {
    ordered.push(normalizarSupermercado({ ...item, orden }, now));
    orden += 1;
  }
  writeSupermercados(ordered);
  return getSupermercados();
}

function deleteSupermercado(id) {
  const items = readSupermercados();
  const filtrados = items.filter((x) => Number(x.id) !== Number(id));
  if (filtrados.length === items.length) return false;
  writeSupermercados(filtrados);
  return true;
}

module.exports = {
  DATA_FILE,
  PRODUCTOS_FILE,
  LISTA_COMPRA_FILE,
  SUPERMERCADOS_FILE,
  PRECIOS_LISTA_COMPRA_FILE,
  readAll,
  getPendientes,
  getPendientesEditables,
  marcarSincronizadas,
  upsertReserva,
  updateEstado,
  readProductos,
  replaceProductos,
  getListaCompra,
  upsertItemListaCompra,
  updateItemListaCompra,
  reordenarListaCompra,
  vaciarCompraListaCompra,
  deleteItemListaCompra,
  getPreciosListaCompra,
  upsertPrecioListaCompra,
  deletePrecioListaCompra,
  getSupermercados,
  upsertSupermercado,
  updateSupermercado,
  reordenarSupermercados,
  deleteSupermercado,
};
