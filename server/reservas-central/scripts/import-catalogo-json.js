/**
 * Importa productos, lista de compra, supermercados y precios desde DATA_DIR JSON → PG.
 * Preserva ids y flags hayQueComprar/comprado.
 *
 * Uso: DATABASE_URL=... node scripts/import-catalogo-json.js
 */
require('../load_env').loadEnv();

const fs = require('fs');
const path = require('path');
const db = require('../db');
const { run: runMigrations } = require('../migrate');
const catalogo = require('../catalogo_store');

const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, '..', 'data');

function readJsonArray(fileName) {
  const full = path.join(DATA_DIR, fileName);
  if (!fs.existsSync(full)) {
    console.log(`  (no existe ${fileName})`);
    return [];
  }
  const raw = fs.readFileSync(full, 'utf8');
  if (!raw.trim()) return [];
  const data = JSON.parse(raw);
  return Array.isArray(data) ? data : [];
}

async function importSupermercados(items) {
  console.log(`Supermercados: ${items.length}`);
  await db.withTransaction(async (client) => {
    await client.query('DELETE FROM lista_compra_item');
    await client.query('DELETE FROM supermercado');
  });
  for (const s of items) {
    await catalogo.upsertSupermercado(s);
  }
}

async function importLista(items) {
  console.log(`Lista compra: ${items.length}`);
  // vaciar por si importamos sola
  await db.query('DELETE FROM lista_compra_item');
  let hay = 0;
  for (const item of items) {
    if (item.hayQueComprar) hay += 1;
    await catalogo.upsertItemListaCompra(item);
  }
  console.log(`  hayQueComprar preservados: ${hay}`);
}

async function importProductos(items) {
  console.log(`Productos: ${items.length}`);
  await catalogo.replaceProductos(items);
}

async function importPrecios(items) {
  console.log(`Precios legacy: ${items.length}`);
  await db.withTransaction(async (client) => {
    await client.query('DELETE FROM precio_lista_compra');
    for (const p of items) {
      const id = Number(p.id);
      const productoId = p.productoId != null ? Number(p.productoId) : null;
      const supermercadoId =
        p.supermercadoId != null ? Number(p.supermercadoId) : null;
      const fecha = p.fecha || p.fechaCreacion || null;
      if (Number.isFinite(id) && id > 0) {
        await client.query(
          `INSERT INTO precio_lista_compra
             (id, producto_id, supermercado_id, payload, fecha)
           VALUES ($1,$2,$3,$4::jsonb,$5)`,
          [id, productoId, supermercadoId, JSON.stringify(p), fecha],
        );
      } else {
        await client.query(
          `INSERT INTO precio_lista_compra
             (producto_id, supermercado_id, payload, fecha)
           VALUES ($1,$2,$3::jsonb,$4)`,
          [productoId, supermercadoId, JSON.stringify(p), fecha],
        );
      }
    }
    await client.query(
      `SELECT setval(
         pg_get_serial_sequence('precio_lista_compra', 'id'),
         GREATEST((SELECT COALESCE(MAX(id), 1) FROM precio_lista_compra), 1)
       )`,
    );
  });
}

async function main() {
  console.log('DATA_DIR =', DATA_DIR);
  await runMigrations();

  const supers = readJsonArray('supermercados.json');
  const lista = readJsonArray('lista_compra.json');
  const productos = readJsonArray('productos.json');
  const precios = readJsonArray('precios_lista_compra.json');

  // Orden: supers primero (FK), luego lista (preserva hayQueComprar).
  await importSupermercados(supers);
  await importLista(lista);
  await importProductos(productos);
  await importPrecios(precios);

  const listaPg = await catalogo.getListaCompra();
  const hay = listaPg.filter((i) => i.hayQueComprar).length;
  console.log(
    `OK. lista_compra=${listaPg.length}, hayQueComprar=${hay}, productos=${productos.length}, supers=${supers.length}`,
  );
}

main()
  .then(() => db.closePool())
  .then(() => process.exit(0))
  .catch((e) => {
    console.error(e);
    db.closePool().finally(() => process.exit(1));
  });
