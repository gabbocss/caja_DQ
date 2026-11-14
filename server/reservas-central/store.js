/**
 * Fachada del API central.
 * Reservas + catálogo/lista/compra → PostgreSQL.
 * Rutas DATA_* se mantienen para scripts de import legacy.
 */
const path = require('path');
const reservasStore = require('./reservas_store');
const catalogoStore = require('./catalogo_store');

const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, 'data');
/** @deprecated Legacy JSON (solo import). */
const DATA_FILE = path.join(DATA_DIR, 'reservas.json');
const PRODUCTOS_FILE = path.join(DATA_DIR, 'productos.json');
const LISTA_COMPRA_FILE = path.join(DATA_DIR, 'lista_compra.json');
const SUPERMERCADOS_FILE = path.join(DATA_DIR, 'supermercados.json');
const PRECIOS_LISTA_COMPRA_FILE = path.join(DATA_DIR, 'precios_lista_compra.json');

module.exports = {
  DATA_FILE,
  PRODUCTOS_FILE,
  LISTA_COMPRA_FILE,
  SUPERMERCADOS_FILE,
  PRECIOS_LISTA_COMPRA_FILE,
  // Reservas
  readAll: reservasStore.readAll,
  getPendientes: reservasStore.getPendientes,
  getPendientesEditables: reservasStore.getPendientesEditables,
  marcarSincronizadas: reservasStore.marcarSincronizadas,
  upsertReserva: reservasStore.upsertReserva,
  updateEstado: reservasStore.updateEstado,
  purgeAntiguasPorFechaLlegada: reservasStore.purgeAntiguasPorFechaLlegada,
  // Catálogo / lista compra / supers (fase 4)
  readProductos: catalogoStore.readProductos,
  replaceProductos: catalogoStore.replaceProductos,
  getListaCompra: catalogoStore.getListaCompra,
  upsertItemListaCompra: catalogoStore.upsertItemListaCompra,
  updateItemListaCompra: catalogoStore.updateItemListaCompra,
  reordenarListaCompra: catalogoStore.reordenarListaCompra,
  vaciarCompraListaCompra: catalogoStore.vaciarCompraListaCompra,
  deleteItemListaCompra: catalogoStore.deleteItemListaCompra,
  getPreciosListaCompra: catalogoStore.getPreciosListaCompra,
  upsertPrecioListaCompra: catalogoStore.upsertPrecioListaCompra,
  deletePrecioListaCompra: catalogoStore.deletePrecioListaCompra,
  getSupermercados: catalogoStore.getSupermercados,
  upsertSupermercado: catalogoStore.upsertSupermercado,
  updateSupermercado: catalogoStore.updateSupermercado,
  reordenarSupermercados: catalogoStore.reordenarSupermercados,
  deleteSupermercado: catalogoStore.deleteSupermercado,
};
