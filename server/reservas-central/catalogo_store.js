/**
 * Productos, lista de compra, supermercados y precios en PostgreSQL (fase 4).
 * Misma forma JSON/API que el store JSON anterior.
 */
const db = require('./db');

function toIso(value) {
  if (value == null) return null;
  if (value instanceof Date) return value.toISOString();
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return null;
  return d.toISOString();
}

function normalizarZona(v) {
  return String(v || '').toLowerCase() === 'sala' ? 'sala' : 'cocina';
}

function normalizarSupermercadoId(value) {
  if (value == null || value === '') return null;
  const n = Number(value);
  return Number.isFinite(n) && n > 0 ? Math.floor(n) : null;
}

function mapListaRow(row) {
  return {
    id: Number(row.id),
    nombre: row.nombre,
    cantidad: row.cantidad != null ? String(row.cantidad) : '',
    hayQueComprar: Boolean(row.hay_que_comprar),
    comprado: Boolean(row.comprado),
    orden: Number(row.orden) || 0,
    zona: normalizarZona(row.zona),
    supermercadoId:
      row.supermercado_id == null ? null : Number(row.supermercado_id),
    urlMetro: row.url_metro || '',
    urlCc: row.url_cc || '',
    fechaCreacion: toIso(row.fecha_creacion),
    fechaActualizacion: toIso(row.fecha_actualizacion),
  };
}

function mapSupermercadoRow(row) {
  return {
    id: Number(row.id),
    nombre: row.nombre,
    orden: Number(row.orden) || 0,
    fechaCreacion: toIso(row.fecha_creacion),
    fechaActualizacion: toIso(row.fecha_actualizacion),
  };
}

async function syncSequence(client, table) {
  await client.query(
    `SELECT setval(
       pg_get_serial_sequence($1, 'id'),
       GREATEST((SELECT COALESCE(MAX(id), 1) FROM ${table}), 1)
     )`,
    [table],
  );
}

// ==================== PRODUCTOS ====================

async function readProductos() {
  const res = await db.query(
    `SELECT payload FROM producto_copia ORDER BY id`,
  );
  return res.rows.map((r) => r.payload);
}

async function replaceProductos(body) {
  const lista = Array.isArray(body) ? body : [body];
  return db.withTransaction(async (client) => {
    await client.query('DELETE FROM producto_copia');
    for (const p of lista) {
      const id = Number(p.id);
      if (!Number.isFinite(id)) continue;
      await client.query(
        `INSERT INTO producto_copia (id, payload, actualizado_en)
         VALUES ($1, $2::jsonb, now())
         ON CONFLICT (id) DO UPDATE SET
           payload = EXCLUDED.payload,
           actualizado_en = now()`,
        [id, JSON.stringify(p)],
      );
    }
    return lista;
  });
}

// ==================== LISTA COMPRA ====================

function normalizarCamposLista(item, nowIso) {
  const hayQueComprar = Boolean(item.hayQueComprar);
  const comprado = hayQueComprar ? Boolean(item.comprado) : false;
  return {
    nombre: String(item.nombre || '').trim(),
    cantidad: item.cantidad != null ? String(item.cantidad) : '',
    hayQueComprar,
    comprado,
    orden: Number(item.orden) || 0,
    zona: normalizarZona(item.zona),
    supermercadoId: normalizarSupermercadoId(item.supermercadoId),
    urlMetro: String(
      item.urlMetro != null
        ? item.urlMetro
        : item.urlProveedor != null
          ? item.urlProveedor
          : '',
    ).trim(),
    urlCc: String(item.urlCc || '').trim(),
    fechaCreacion: toIso(item.fechaCreacion) || nowIso,
    fechaActualizacion: nowIso,
  };
}

async function getListaCompra() {
  const res = await db.query(
    `SELECT * FROM lista_compra_item ORDER BY orden ASC, id ASC`,
  );
  return res.rows.map(mapListaRow);
}

async function nextListaCompraId(client) {
  const res = await client.query(
    `SELECT COALESCE(MAX(id), 0) + 1 AS n FROM lista_compra_item`,
  );
  return Number(res.rows[0].n);
}

async function nextListaOrden(client) {
  const res = await client.query(
    `SELECT COALESCE(MAX(orden), -1) + 1 AS n FROM lista_compra_item`,
  );
  return Number(res.rows[0].n);
}

async function upsertItemListaCompra(body) {
  const now = new Date().toISOString();
  return db.withTransaction(async (client) => {
    if (body.id != null) {
      const id = Number(body.id);
      const existing = await client.query(
        `SELECT * FROM lista_compra_item WHERE id = $1`,
        [id],
      );
      if (existing.rowCount > 0) {
        const prev = mapListaRow(existing.rows[0]);
        const merged = normalizarCamposLista(
          {
            ...prev,
            ...body,
            id,
            nombre: body.nombre != null ? body.nombre : prev.nombre,
            cantidad: body.cantidad != null ? body.cantidad : prev.cantidad,
            hayQueComprar:
              body.hayQueComprar != null
                ? body.hayQueComprar
                : prev.hayQueComprar,
            comprado:
              body.comprado != null ? body.comprado : prev.comprado,
            orden: body.orden != null ? body.orden : prev.orden,
            zona: body.zona != null ? body.zona : prev.zona,
            supermercadoId:
              body.supermercadoId !== undefined
                ? body.supermercadoId
                : prev.supermercadoId,
            urlMetro:
              body.urlMetro != null
                ? body.urlMetro
                : body.urlProveedor != null
                  ? body.urlProveedor
                  : prev.urlMetro,
            urlCc: body.urlCc != null ? body.urlCc : prev.urlCc,
            fechaCreacion: prev.fechaCreacion,
          },
          now,
        );
        if (!merged.nombre) throw new Error('El nombre es obligatorio');
        await client.query(
          `UPDATE lista_compra_item SET
             nombre=$2, cantidad=$3, hay_que_comprar=$4, comprado=$5,
             orden=$6, zona=$7, supermercado_id=$8, url_metro=$9, url_cc=$10,
             fecha_actualizacion=$11
           WHERE id=$1`,
          [
            id,
            merged.nombre,
            merged.cantidad,
            merged.hayQueComprar,
            merged.comprado,
            merged.orden,
            merged.zona,
            merged.supermercadoId,
            merged.urlMetro,
            merged.urlCc,
            now,
          ],
        );
        const row = await client.query(
          `SELECT * FROM lista_compra_item WHERE id = $1`,
          [id],
        );
        return mapListaRow(row.rows[0]);
      }
    }

    const nombre = String(body.nombre || '').trim();
    if (!nombre) throw new Error('El nombre es obligatorio');
    const id =
      body.id != null && Number(body.id) > 0
        ? Number(body.id)
        : await nextListaCompraId(client);
    const orden =
      body.orden != null ? Number(body.orden) : await nextListaOrden(client);
    const merged = normalizarCamposLista(
      { ...body, id, nombre, orden, fechaCreacion: now },
      now,
    );
    await client.query(
      `INSERT INTO lista_compra_item (
         id, nombre, cantidad, hay_que_comprar, comprado, orden, zona,
         supermercado_id, url_metro, url_cc, fecha_creacion, fecha_actualizacion
       ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)`,
      [
        id,
        merged.nombre,
        merged.cantidad,
        merged.hayQueComprar,
        merged.comprado,
        merged.orden,
        merged.zona,
        merged.supermercadoId,
        merged.urlMetro,
        merged.urlCc,
        merged.fechaCreacion,
        now,
      ],
    );
    await syncSequence(client, 'lista_compra_item');
    const row = await client.query(
      `SELECT * FROM lista_compra_item WHERE id = $1`,
      [id],
    );
    return mapListaRow(row.rows[0]);
  });
}

async function updateItemListaCompra(id, body) {
  return upsertItemListaCompra({ ...body, id: Number(id) });
}

async function reordenarListaCompra(ids) {
  const now = new Date().toISOString();
  return db.withTransaction(async (client) => {
    const res = await client.query(`SELECT * FROM lista_compra_item`);
    const byId = new Map(res.rows.map((r) => [Number(r.id), r]));
    let orden = 0;
    const lista = Array.isArray(ids) ? ids : [];
    for (const rawId of lista) {
      const id = Number(rawId);
      if (!byId.has(id)) continue;
      await client.query(
        `UPDATE lista_compra_item SET orden=$2, fecha_actualizacion=$3 WHERE id=$1`,
        [id, orden, now],
      );
      orden += 1;
      byId.delete(id);
    }
    for (const row of byId.values()) {
      await client.query(
        `UPDATE lista_compra_item SET orden=$2, fecha_actualizacion=$3 WHERE id=$1`,
        [Number(row.id), orden, now],
      );
      orden += 1;
    }
  }).then(() => getListaCompra());
}

async function vaciarCompraListaCompra() {
  const now = new Date().toISOString();
  const res = await db.query(
    `UPDATE lista_compra_item
     SET hay_que_comprar = false, comprado = false, fecha_actualizacion = $1
     RETURNING id`,
    [now],
  );
  const items = await getListaCompra();
  return { ok: true, reseteados: res.rowCount || 0, items };
}

async function deleteItemListaCompra(id) {
  const res = await db.query(
    `DELETE FROM lista_compra_item WHERE id = $1 RETURNING id`,
    [Number(id)],
  );
  return (res.rowCount || 0) > 0;
}

// ==================== PRECIOS ====================

async function getPreciosListaCompra(filtro = {}) {
  const params = [];
  const where = [];
  if (filtro.productoId != null && filtro.productoId !== '') {
    params.push(Number(filtro.productoId));
    where.push(`producto_id = $${params.length}`);
  }
  if (filtro.supermercadoId != null && filtro.supermercadoId !== '') {
    params.push(Number(filtro.supermercadoId));
    where.push(`supermercado_id = $${params.length}`);
  }
  const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const res = await db.query(
    `SELECT id, payload, fecha FROM precio_lista_compra
     ${whereSql}
     ORDER BY fecha DESC NULLS LAST, id DESC`,
    params,
  );
  return res.rows.map((r) => {
    const p = r.payload && typeof r.payload === 'object' ? r.payload : {};
    return { ...p, id: Number(r.id) };
  });
}

async function upsertPrecioListaCompra() {
  throw new Error('Los precios de lista de compra ya no están soportados');
}

async function deletePrecioListaCompra(id) {
  const res = await db.query(
    `DELETE FROM precio_lista_compra WHERE id = $1 RETURNING id`,
    [Number(id)],
  );
  return (res.rowCount || 0) > 0;
}

// ==================== SUPERMERCADOS ====================

async function getSupermercados() {
  const res = await db.query(
    `SELECT * FROM supermercado ORDER BY orden ASC, id ASC`,
  );
  return res.rows.map(mapSupermercadoRow);
}

async function nextSupermercadoId(client) {
  const res = await client.query(
    `SELECT COALESCE(MAX(id), 0) + 1 AS n FROM supermercado`,
  );
  return Number(res.rows[0].n);
}

async function nextSupermercadoOrden(client) {
  const res = await client.query(
    `SELECT COALESCE(MAX(orden), -1) + 1 AS n FROM supermercado`,
  );
  return Number(res.rows[0].n);
}

async function upsertSupermercado(body) {
  const now = new Date().toISOString();
  return db.withTransaction(async (client) => {
    if (body.id != null) {
      const id = Number(body.id);
      const existing = await client.query(
        `SELECT * FROM supermercado WHERE id = $1`,
        [id],
      );
      if (existing.rowCount > 0) {
        const prev = mapSupermercadoRow(existing.rows[0]);
        const nombre = String(body.nombre ?? prev.nombre ?? '').trim();
        if (!nombre) throw new Error('El nombre es obligatorio');
        const orden =
          body.orden != null ? Number(body.orden) : prev.orden;
        await client.query(
          `UPDATE supermercado SET
             nombre=$2, orden=$3, fecha_actualizacion=$4
           WHERE id=$1`,
          [id, nombre, orden, now],
        );
        const row = await client.query(
          `SELECT * FROM supermercado WHERE id = $1`,
          [id],
        );
        return mapSupermercadoRow(row.rows[0]);
      }
    }
    const nombre = String(body.nombre || '').trim();
    if (!nombre) throw new Error('El nombre es obligatorio');
    const id =
      body.id != null && Number(body.id) > 0
        ? Number(body.id)
        : await nextSupermercadoId(client);
    const orden =
      body.orden != null
        ? Number(body.orden)
        : await nextSupermercadoOrden(client);
    const fechaCreacion = toIso(body.fechaCreacion) || now;
    await client.query(
      `INSERT INTO supermercado
         (id, nombre, orden, fecha_creacion, fecha_actualizacion)
       VALUES ($1,$2,$3,$4,$5)`,
      [id, nombre, orden, fechaCreacion, now],
    );
    await syncSequence(client, 'supermercado');
    const row = await client.query(
      `SELECT * FROM supermercado WHERE id = $1`,
      [id],
    );
    return mapSupermercadoRow(row.rows[0]);
  });
}

async function updateSupermercado(id, body) {
  return upsertSupermercado({ ...body, id: Number(id) });
}

async function reordenarSupermercados(ids) {
  const now = new Date().toISOString();
  await db.withTransaction(async (client) => {
    const res = await client.query(`SELECT * FROM supermercado`);
    const byId = new Map(res.rows.map((r) => [Number(r.id), r]));
    let orden = 0;
    const lista = Array.isArray(ids) ? ids : [];
    for (const rawId of lista) {
      const id = Number(rawId);
      if (!byId.has(id)) continue;
      await client.query(
        `UPDATE supermercado SET orden=$2, fecha_actualizacion=$3 WHERE id=$1`,
        [id, orden, now],
      );
      orden += 1;
      byId.delete(id);
    }
    for (const row of byId.values()) {
      await client.query(
        `UPDATE supermercado SET orden=$2, fecha_actualizacion=$3 WHERE id=$1`,
        [Number(row.id), orden, now],
      );
      orden += 1;
    }
  });
  return getSupermercados();
}

async function deleteSupermercado(id) {
  const res = await db.query(
    `DELETE FROM supermercado WHERE id = $1 RETURNING id`,
    [Number(id)],
  );
  return (res.rowCount || 0) > 0;
}

module.exports = {
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
