const fs = require('fs');
const path = require('path');

const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, 'data');
const DATA_FILE = path.join(DATA_DIR, 'reservas.json');
const PRODUCTOS_FILE = path.join(DATA_DIR, 'productos.json');
const LISTA_COMPRA_FILE = path.join(DATA_DIR, 'lista_compra.json');
const SUPERMERCADOS_FILE = path.join(DATA_DIR, 'supermercados.json');
const PRECIOS_LISTA_COMPRA_FILE = path.join(DATA_DIR, 'precios_lista_compra.json');

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

/**
 * Reservas que la caja debe descargar o actualizar (nuevas, reeditadas o canceladas).
 */
function getPendientes() {
  const reservas = readAll();
  purgeSincronizadasAntiguas(reservas);
  const actuales = readAll();
  return actuales
    .filter(
      (r) =>
        !r.sincronizadaEnCajaAt &&
        (r.estado === 'pendiente' || r.estado === 'cancelada'),
    )
    .sort(
      (a, b) =>
        new Date(a.fechaHoraLlegada).getTime() -
        new Date(b.fechaHoraLlegada).getTime(),
    );
}

/**
 * Todas las reservas pendientes editables (incluye las ya confirmadas en caja).
 * Usado por la app móvil con GET /api/reservas?incluye=sincronizadas
 */
function getPendientesEditables() {
  const reservas = readAll();
  purgeSincronizadasAntiguas(reservas);
  const actuales = readAll();
  return actuales
    .filter((r) => r.estado === 'pendiente')
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
  // Reencolar para que la caja reciba cancelaciones u otros cambios de estado.
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

function normalizarUnidadBase(v) {
  const s = String(v || 'unidad').toLowerCase();
  if (s === 'kilo' || s === 'litro' || s === 'unidad') return s;
  return 'unidad';
}

function normalizarContenidoUnidad(v, unidadBase) {
  const s = String(v || '').toLowerCase();
  const permitidas =
    unidadBase === 'litro'
      ? ['ml', 'l']
      : unidadBase === 'kilo'
        ? ['g', 'kg']
        : ['ud'];
  if (permitidas.includes(s)) return s;
  return unidadBase === 'litro' ? 'ml' : unidadBase === 'kilo' ? 'g' : 'ud';
}

function aCantidadBase(cantidad, contenidoUnidad, unidadBase) {
  const c = Number(cantidad);
  if (!(c > 0)) return null;
  if (unidadBase === 'litro') {
    if (contenidoUnidad === 'ml') return c / 1000;
    if (contenidoUnidad === 'l') return c;
  } else if (unidadBase === 'kilo') {
    if (contenidoUnidad === 'g') return c / 1000;
    if (contenidoUnidad === 'kg') return c;
  } else if (unidadBase === 'unidad') {
    if (contenidoUnidad === 'ud') return c;
  }
  return null;
}

function calcularPrecioPorBase(
  precioEnvase,
  contenidoCantidad,
  contenidoUnidad,
  unidadBase,
) {
  const base = aCantidadBase(contenidoCantidad, contenidoUnidad, unidadBase);
  if (base == null) {
    throw new Error(
      'Contenido incompatible con la unidad (kilo/litro/unidad)',
    );
  }
  const p = Number(precioEnvase);
  if (Number.isNaN(p) || p < 0) {
    throw new Error('Precio inválido');
  }
  return p / base;
}

function normalizarItemListaCompra(item, now) {
  const hayQueComprar = Boolean(item.hayQueComprar);
  const comprado = hayQueComprar ? Boolean(item.comprado) : false;
  const ordenRaw = Number(item.orden);
  const orden = Number.isNaN(ordenRaw) ? 0 : ordenRaw;
  const unidadBase = normalizarUnidadBase(item.unidadBase);
  const contenidoCantidadRaw = Number(item.contenidoCantidad);
  const contenidoCantidad =
    !Number.isNaN(contenidoCantidadRaw) && contenidoCantidadRaw > 0
      ? contenidoCantidadRaw
      : null;
  const minRaw = Number(item.cantidadMinima);
  const cantidadMinima =
    Number.isFinite(minRaw) && minRaw >= 1 ? Math.floor(minRaw) : 1;
  return {
    ...item,
    hayQueComprar,
    comprado,
    orden,
    unidadBase,
    contenidoCantidad,
    contenidoUnidad: normalizarContenidoUnidad(
      item.contenidoUnidad,
      unidadBase,
    ),
    cantidadMinima,
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
        unidadBase:
          item.unidadBase != null ? item.unidadBase : items[idx].unidadBase,
        contenidoCantidad:
          item.contenidoCantidad !== undefined
            ? item.contenidoCantidad
            : items[idx].contenidoCantidad,
        contenidoUnidad:
          item.contenidoUnidad != null
            ? item.contenidoUnidad
            : items[idx].contenidoUnidad,
        cantidadMinima:
          item.cantidadMinima != null
            ? item.cantidadMinima
            : items[idx].cantidadMinima,
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
      unidadBase: item.unidadBase || 'unidad',
      contenidoCantidad: item.contenidoCantidad,
      contenidoUnidad: item.contenidoUnidad,
      cantidadMinima: item.cantidadMinima != null ? item.cantidadMinima : 1,
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
 * Guarda/actualiza el último precio de un producto en un supermercado.
 * Calcula precioPorBase (€/litro, €/kg o €/ud).
 */
function upsertPrecioListaCompra(body) {
  const productoId = Number(body.productoId);
  const supermercadoId = Number(body.supermercadoId);
  if (!(productoId > 0) || !(supermercadoId > 0)) {
    throw new Error('productoId y supermercadoId son obligatorios');
  }

  const productos = readListaCompra();
  const producto = productos.find((p) => Number(p.id) === productoId);
  if (!producto) throw new Error('Producto no encontrado');

  const supers = readSupermercados();
  if (!supers.some((s) => Number(s.id) === supermercadoId)) {
    throw new Error('Supermercado no encontrado');
  }

  const unidadBase = normalizarUnidadBase(
    body.unidadBase != null ? body.unidadBase : producto.unidadBase,
  );
  const contenidoCantidad =
    body.contenidoCantidad != null
      ? Number(body.contenidoCantidad)
      : Number(producto.contenidoCantidad);
  const contenidoUnidad = normalizarContenidoUnidad(
    body.contenidoUnidad != null
      ? body.contenidoUnidad
      : producto.contenidoUnidad,
    unidadBase,
  );
  const precioEnvase = Number(body.precioEnvase);
  const precioPorBase = calcularPrecioPorBase(
    precioEnvase,
    contenidoCantidad,
    contenidoUnidad,
    unidadBase,
  );

  const now = new Date().toISOString();
  const items = readPreciosListaCompra();
  const idx = items.findIndex(
    (p) =>
      Number(p.productoId) === productoId &&
      Number(p.supermercadoId) === supermercadoId,
  );

  const registro = {
    id: idx >= 0 ? items[idx].id : nextPrecioId(items),
    productoId,
    supermercadoId,
    precioEnvase,
    contenidoCantidad,
    contenidoUnidad,
    unidadBase,
    precioPorBase,
    fecha: now,
    fechaCreacion: idx >= 0 ? items[idx].fechaCreacion || now : now,
  };

  if (idx >= 0) items[idx] = registro;
  else items.push(registro);

  writePreciosListaCompra(items);
  return registro;
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
  calcularPrecioPorBase,
  getSupermercados,
  upsertSupermercado,
  updateSupermercado,
  reordenarSupermercados,
  deleteSupermercado,
};
