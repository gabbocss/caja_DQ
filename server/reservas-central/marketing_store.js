/**
 * Campañas y eventos del restaurante (fase 5).
 */
const db = require('./db');
const { fechaSolo } = require('./contexto_store');

function toIso(value) {
  if (value == null) return null;
  if (value instanceof Date) return value.toISOString();
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return null;
  return d.toISOString();
}

function fechaCampo(value) {
  if (!value) return null;
  if (value instanceof Date) return value.toISOString().slice(0, 10);
  return String(value).slice(0, 10);
}

function mapCampania(row) {
  return {
    id: Number(row.id),
    nombre: row.nombre,
    tipo: row.tipo,
    canal: row.canal || '',
    productoId: row.producto_id == null ? null : Number(row.producto_id),
    fechaInicio: fechaCampo(row.fecha_inicio),
    fechaFin: fechaCampo(row.fecha_fin),
    notas: row.notas || '',
    activa: Boolean(row.activa),
    creadoEn: toIso(row.creado_en),
    actualizadoEn: toIso(row.actualizado_en),
  };
}

function mapEvento(row) {
  return {
    id: Number(row.id),
    nombre: row.nombre,
    tipo: row.tipo,
    fechaInicio: fechaCampo(row.fecha_inicio),
    fechaFin: fechaCampo(row.fecha_fin),
    aforoEsperado:
      row.aforo_esperado == null ? null : Number(row.aforo_esperado),
    notas: row.notas || '',
    activo: Boolean(row.activo),
    creadoEn: toIso(row.creado_en),
    actualizadoEn: toIso(row.actualizado_en),
  };
}

async function listarCampanias({ soloActivas } = {}) {
  const res = await db.query(
    soloActivas
      ? `SELECT * FROM campania WHERE activa = true ORDER BY fecha_inicio DESC, id DESC`
      : `SELECT * FROM campania ORDER BY fecha_inicio DESC, id DESC`,
  );
  return res.rows.map(mapCampania);
}

async function upsertCampania(body) {
  const now = new Date().toISOString();
  const nombre = String(body.nombre || '').trim();
  if (!nombre) throw new Error('El nombre es obligatorio');
  let tipo = String(body.tipo || 'general');
  if (!['plato', 'evento', 'general'].includes(tipo)) tipo = 'general';
  const canal = String(body.canal || '').trim();
  const productoId =
    body.productoId == null || body.productoId === ''
      ? null
      : Number(body.productoId);
  const fechaInicio = fechaSolo(body.fechaInicio);
  const fechaFin = fechaSolo(body.fechaFin || body.fechaInicio);
  const notas = String(body.notas || '');
  const activa = body.activa != null ? Boolean(body.activa) : true;

  if (body.id != null) {
    const id = Number(body.id);
    const res = await db.query(
      `UPDATE campania SET
         nombre=$2, tipo=$3, canal=$4, producto_id=$5,
         fecha_inicio=$6, fecha_fin=$7, notas=$8, activa=$9,
         actualizado_en=$10
       WHERE id=$1
       RETURNING *`,
      [
        id,
        nombre,
        tipo,
        canal,
        productoId,
        fechaInicio,
        fechaFin,
        notas,
        activa,
        now,
      ],
    );
    if (res.rowCount === 0) throw new Error('Campaña no encontrada');
    return mapCampania(res.rows[0]);
  }

  const res = await db.query(
    `INSERT INTO campania (
       nombre, tipo, canal, producto_id, fecha_inicio, fecha_fin,
       notas, activa, creado_en, actualizado_en
     ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$9)
     RETURNING *`,
    [nombre, tipo, canal, productoId, fechaInicio, fechaFin, notas, activa, now],
  );
  return mapCampania(res.rows[0]);
}

async function deleteCampania(id) {
  const res = await db.query(
    `DELETE FROM campania WHERE id = $1 RETURNING id`,
    [Number(id)],
  );
  return (res.rowCount || 0) > 0;
}

async function listarEventos({ soloActivos } = {}) {
  const res = await db.query(
    soloActivos
      ? `SELECT * FROM evento_restaurante WHERE activo = true ORDER BY fecha_inicio DESC, id DESC`
      : `SELECT * FROM evento_restaurante ORDER BY fecha_inicio DESC, id DESC`,
  );
  return res.rows.map(mapEvento);
}

async function upsertEvento(body) {
  const now = new Date().toISOString();
  const nombre = String(body.nombre || '').trim();
  if (!nombre) throw new Error('El nombre es obligatorio');
  const tipo = String(body.tipo || 'otro').trim() || 'otro';
  const fechaInicio = fechaSolo(body.fechaInicio);
  const fechaFin = fechaSolo(body.fechaFin || body.fechaInicio);
  const aforo =
    body.aforoEsperado == null || body.aforoEsperado === ''
      ? null
      : Number(body.aforoEsperado);
  const notas = String(body.notas || '');
  const activo = body.activo != null ? Boolean(body.activo) : true;

  if (body.id != null) {
    const id = Number(body.id);
    const res = await db.query(
      `UPDATE evento_restaurante SET
         nombre=$2, tipo=$3, fecha_inicio=$4, fecha_fin=$5,
         aforo_esperado=$6, notas=$7, activo=$8, actualizado_en=$9
       WHERE id=$1
       RETURNING *`,
      [id, nombre, tipo, fechaInicio, fechaFin, aforo, notas, activo, now],
    );
    if (res.rowCount === 0) throw new Error('Evento no encontrado');
    return mapEvento(res.rows[0]);
  }

  const res = await db.query(
    `INSERT INTO evento_restaurante (
       nombre, tipo, fecha_inicio, fecha_fin, aforo_esperado,
       notas, activo, creado_en, actualizado_en
     ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$8)
     RETURNING *`,
    [nombre, tipo, fechaInicio, fechaFin, aforo, notas, activo, now],
  );
  return mapEvento(res.rows[0]);
}

async function deleteEvento(id) {
  const res = await db.query(
    `DELETE FROM evento_restaurante WHERE id = $1 RETURNING id`,
    [Number(id)],
  );
  return (res.rowCount || 0) > 0;
}

/** Campañas activas que cubren la fecha. */
async function campaniasActivasEn(fechaRaw, client = null) {
  const fecha = fechaSolo(fechaRaw);
  const q = client || db;
  const res = await q.query(
    `SELECT id FROM campania
     WHERE activa = true
       AND fecha_inicio <= $1::date
       AND fecha_fin >= $1::date`,
    [fecha],
  );
  return res.rows.map((r) => Number(r.id));
}

async function eventosActivosEn(fechaRaw, client = null) {
  const fecha = fechaSolo(fechaRaw);
  const q = client || db;
  const res = await q.query(
    `SELECT id FROM evento_restaurante
     WHERE activo = true
       AND fecha_inicio <= $1::date
       AND fecha_fin >= $1::date`,
    [fecha],
  );
  return res.rows.map((r) => Number(r.id));
}

module.exports = {
  listarCampanias,
  upsertCampania,
  deleteCampania,
  listarEventos,
  upsertEvento,
  deleteEvento,
  campaniasActivasEn,
  eventosActivosEn,
};
