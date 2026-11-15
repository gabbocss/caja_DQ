/**
 * Histórico de ventas (fase 3) para analítica / predicción.
 */
const db = require('./db');
const { asegurarContextoDia, fechaSolo } = require('./contexto_store');
const {
  campaniasActivasEn,
  eventosActivosEn,
} = require('./marketing_store');

const SERVICIOS = new Set(['comida', 'cena', 'otro']);
const ORIGENES = new Set([
  'reserva',
  'walkin',
  'qr',
  'asporto',
  'web',
  'otro',
]);

function toIso(value) {
  if (value == null) return null;
  if (value instanceof Date) return value.toISOString();
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return null;
  return d.toISOString();
}

function mapVenta(row, items) {
  return {
    id: Number(row.id),
    idempotencyKey: row.idempotency_key,
    fechaCierre: toIso(row.fecha_cierre),
    servicio: row.servicio,
    origen: row.origen,
    clienteId: row.cliente_id == null ? null : Number(row.cliente_id),
    reservaId: row.reserva_id == null ? null : Number(row.reserva_id),
    mesaNumero: row.mesa_numero == null ? null : Number(row.mesa_numero),
    comensales: row.comensales == null ? null : Number(row.comensales),
    duracionMinutos:
      row.duracion_minutos == null ? null : Number(row.duracion_minutos),
    total: Number(row.total),
    esBuffet: Boolean(row.es_buffet),
    creadoEn: toIso(row.creado_en),
    items: (items || []).map((it) => ({
      productoId: Number(it.producto_id),
      nombreProducto: it.nombre_producto,
      cantidad: Number(it.cantidad),
      precioUnitario: Number(it.precio_unitario),
    })),
  };
}

async function loadItems(client, ventaIds) {
  if (!ventaIds.length) return new Map();
  const res = await client.query(
    `SELECT venta_id, producto_id, nombre_producto, cantidad, precio_unitario
     FROM venta_item
     WHERE venta_id = ANY($1::bigint[])
     ORDER BY id`,
    [ventaIds],
  );
  const map = new Map();
  for (const row of res.rows) {
    const id = Number(row.venta_id);
    if (!map.has(id)) map.set(id, []);
    map.get(id).push(row);
  }
  return map;
}

/**
 * Upsert por idempotency_key: si ya existe, devuelve la venta existente.
 */
async function registrarVenta(body) {
  const key = String(body.idempotencyKey || '').trim();
  if (!key) throw new Error('idempotencyKey es obligatorio');

  const fechaCierre = toIso(body.fechaCierre) || new Date().toISOString();
  let servicio = String(body.servicio || 'otro');
  if (!SERVICIOS.has(servicio)) servicio = 'otro';
  let origen = String(body.origen || 'walkin');
  if (!ORIGENES.has(origen)) origen = 'otro';

  const clienteId =
    body.clienteId == null || body.clienteId === ''
      ? null
      : Number(body.clienteId);
  const reservaId =
    body.reservaId == null || body.reservaId === ''
      ? null
      : Number(body.reservaId);
  const mesaNumero =
    body.mesaNumero == null || body.mesaNumero === ''
      ? null
      : Number(body.mesaNumero);
  const comensales =
    body.comensales == null || body.comensales === ''
      ? null
      : Number(body.comensales);
  const duracionMinutos =
    body.duracionMinutos == null || body.duracionMinutos === ''
      ? null
      : Number(body.duracionMinutos);
  const total = Number(body.total) || 0;
  const esBuffet = Boolean(body.esBuffet);
  const items = Array.isArray(body.items) ? body.items : [];

  return db.withTransaction(async (client) => {
    const existing = await client.query(
      `SELECT id FROM venta WHERE idempotency_key = $1`,
      [key],
    );
    if (existing.rowCount > 0) {
      const id = Number(existing.rows[0].id);
      const row = await client.query(`SELECT * FROM venta WHERE id = $1`, [id]);
      const itemsMap = await loadItems(client, [id]);
      return {
        ...mapVenta(row.rows[0], itemsMap.get(id) || []),
        duplicated: true,
      };
    }

    // Validar FKs opcionales (no fallar si el id no existe en este VPS).
    let clienteOk = null;
    if (clienteId != null && Number.isFinite(clienteId) && clienteId > 0) {
      const c = await client.query(`SELECT id FROM cliente WHERE id = $1`, [
        clienteId,
      ]);
      if (c.rowCount > 0) clienteOk = clienteId;
    }
    let reservaOk = null;
    if (reservaId != null && Number.isFinite(reservaId) && reservaId > 0) {
      const r = await client.query(`SELECT id FROM reserva WHERE id = $1`, [
        reservaId,
      ]);
      if (r.rowCount > 0) reservaOk = reservaId;
    }

    const inserted = await client.query(
      `INSERT INTO venta (
         idempotency_key, fecha_cierre, servicio, origen,
         cliente_id, reserva_id, mesa_numero, comensales,
         duracion_minutos, total, es_buffet
       ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
       RETURNING *`,
      [
        key,
        fechaCierre,
        servicio,
        origen,
        clienteOk,
        reservaOk,
        mesaNumero,
        comensales,
        duracionMinutos,
        total,
        esBuffet,
      ],
    );
    const ventaRow = inserted.rows[0];
    const ventaId = Number(ventaRow.id);

    for (const it of items) {
      const productoId = Number(it.productoId ?? it.producto_id) || 0;
      const nombre = String(
        it.nombreProducto ?? it.nombre_producto ?? 'Producto',
      ).trim();
      const cantidad = Math.max(1, Number(it.cantidad) || 1);
      const precio = Number(it.precioUnitario ?? it.precio_unitario) || 0;
      await client.query(
        `INSERT INTO venta_item
           (venta_id, producto_id, nombre_producto, cantidad, precio_unitario)
         VALUES ($1,$2,$3,$4,$5)`,
        [ventaId, productoId, nombre || 'Producto', cantidad, precio],
      );
    }

    if (clienteOk != null) {
      await client.query(
        `UPDATE cliente SET
           ultima_visita_en = GREATEST(
             COALESCE(ultima_visita_en, $2::timestamptz),
             $2::timestamptz
           ),
           actualizado_en = now()
         WHERE id = $1`,
        [clienteOk, fechaCierre],
      );
    }

    // Fase 5: asociar campañas/eventos activos del día.
    const fechaDia = fechaSolo(fechaCierre);
    let campaniaIds = Array.isArray(body.campaniaIds)
      ? body.campaniaIds.map(Number).filter((n) => n > 0)
      : await campaniasActivasEn(fechaDia, client);
    let eventoIds = Array.isArray(body.eventoIds)
      ? body.eventoIds.map(Number).filter((n) => n > 0)
      : await eventosActivosEn(fechaDia, client);

    for (const cid of campaniaIds) {
      await client.query(
        `INSERT INTO venta_campania (venta_id, campania_id)
         VALUES ($1,$2) ON CONFLICT DO NOTHING`,
        [ventaId, cid],
      );
    }
    for (const eid of eventoIds) {
      await client.query(
        `INSERT INTO venta_evento (venta_id, evento_id)
         VALUES ($1,$2) ON CONFLICT DO NOTHING`,
        [ventaId, eid],
      );
    }

    const itemsMap = await loadItems(client, [ventaId]);
    const result = {
      ...mapVenta(ventaRow, itemsMap.get(ventaId) || []),
      campaniaIds,
      eventoIds,
      duplicated: false,
    };

    // Contexto del día fuera de la tx (clima HTTP).
    setImmediate(() => {
      asegurarContextoDia(fechaDia).catch((e) =>
        console.error('contexto_dia:', e.message || e),
      );
    });

    return result;
  });
}

async function listarVentas({ desde, hasta, limit } = {}) {
  const lim = Math.min(Math.max(Number(limit) || 100, 1), 1000);
  const params = [];
  const where = [];
  if (desde) {
    params.push(toIso(desde));
    where.push(`fecha_cierre >= $${params.length}`);
  }
  if (hasta) {
    params.push(toIso(hasta));
    where.push(`fecha_cierre <= $${params.length}`);
  }
  params.push(lim);
  const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';

  return db.withClient(async (client) => {
    const res = await client.query(
      `SELECT * FROM venta
       ${whereSql}
       ORDER BY fecha_cierre DESC
       LIMIT $${params.length}`,
      params,
    );
    const ids = res.rows.map((r) => Number(r.id));
    const itemsMap = await loadItems(client, ids);
    return res.rows.map((row) =>
      mapVenta(row, itemsMap.get(Number(row.id)) || []),
    );
  });
}

module.exports = {
  registrarVenta,
  listarVentas,
};
