/**
 * Ficha de cliente CRM (fase 7): perfil + hábitos desde ventas/reservas.
 */
const db = require('./db');
const { normalizarTelefono } = require('./cliente_utils');

function toIso(value) {
  if (value == null) return null;
  if (value instanceof Date) return value.toISOString();
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return null;
  return d.toISOString();
}

function mapCliente(row) {
  return {
    id: Number(row.id),
    telefono: row.telefono || '',
    telefonoNormalizado: row.telefono_normalizado || '',
    nombre: row.nombre || '',
    alergiasNotas: row.alergias_notas || '',
    creadoEn: toIso(row.creado_en),
    actualizadoEn: toIso(row.actualizado_en),
    ultimaVisitaEn: toIso(row.ultima_visita_en),
  };
}

async function getClientePorId(id) {
  const res = await db.query(`SELECT * FROM cliente WHERE id = $1`, [
    Number(id),
  ]);
  if (res.rowCount === 0) return null;
  return mapCliente(res.rows[0]);
}

async function getClientePorTelefono(telefonoRaw) {
  const normalizado = normalizarTelefono(telefonoRaw);
  if (!normalizado) return null;
  const res = await db.query(
    `SELECT * FROM cliente WHERE telefono_normalizado = $1`,
    [normalizado],
  );
  if (res.rowCount === 0) return null;
  return mapCliente(res.rows[0]);
}

/**
 * Ventas del cliente: por cliente_id directo O por reserva con ese cliente
 * (cubre cobros antiguos sin cliente_id en la venta).
 */
async function idsVentasDelCliente(clienteId) {
  const res = await db.query(
    `SELECT DISTINCT v.id
     FROM venta v
     LEFT JOIN reserva r ON r.id = v.reserva_id
     WHERE v.cliente_id = $1
        OR r.cliente_id = $1`,
    [Number(clienteId)],
  );
  return res.rows.map((r) => Number(r.id));
}

async function resumenVisitas(clienteId) {
  const ventaIds = await idsVentasDelCliente(clienteId);
  if (ventaIds.length === 0) {
    return {
      visitas: 0,
      ticketMedio: null,
      totalGastado: 0,
      ultimaVentaEn: null,
    };
  }
  const res = await db.query(
    `SELECT
       COUNT(*)::int AS visitas,
       COALESCE(AVG(total), 0)::float AS ticket_medio,
       COALESCE(SUM(total), 0)::float AS total_gastado,
       MAX(fecha_cierre) AS ultima_venta
     FROM venta
     WHERE id = ANY($1::bigint[])`,
    [ventaIds],
  );
  const row = res.rows[0];
  return {
    visitas: Number(row.visitas) || 0,
    ticketMedio: Math.round(Number(row.ticket_medio) * 100) / 100,
    totalGastado: Math.round(Number(row.total_gastado) * 100) / 100,
    ultimaVentaEn: toIso(row.ultima_venta),
  };
}

async function platosHabituales(clienteId, { limit = 8 } = {}) {
  const ventaIds = await idsVentasDelCliente(clienteId);
  if (ventaIds.length === 0) return [];

  const visitasRes = await db.query(
    `SELECT COUNT(*)::float AS n FROM venta WHERE id = ANY($1::bigint[])`,
    [ventaIds],
  );
  const nVisitas = Number(visitasRes.rows[0]?.n) || 0;
  if (nVisitas <= 0) return [];

  const lim = Math.min(Math.max(Number(limit) || 8, 1), 30);
  const res = await db.query(
    `SELECT
       vi.producto_id,
       MAX(vi.nombre_producto) AS nombre_producto,
       SUM(vi.cantidad)::float AS unidades,
       COUNT(DISTINCT vi.venta_id)::float AS veces,
       AVG(vi.cantidad)::float AS qty_media
     FROM venta_item vi
     WHERE vi.venta_id = ANY($1::bigint[])
     GROUP BY vi.producto_id
     ORDER BY veces DESC, unidades DESC
     LIMIT $2`,
    [ventaIds, lim],
  );

  return res.rows.map((row) => {
    const veces = Number(row.veces) || 0;
    return {
      productoId: Number(row.producto_id),
      nombreProducto: row.nombre_producto,
      unidades: Math.round(Number(row.unidades) * 10) / 10,
      veces,
      qtyMedia: Math.round(Number(row.qty_media) * 10) / 10,
      frecuencia: Math.round((veces / nVisitas) * 1000) / 1000,
      frecuenciaPct: Math.round((veces / nVisitas) * 100),
    };
  });
}

async function reservasRecientes(clienteId, { limit = 10 } = {}) {
  const lim = Math.min(Math.max(Number(limit) || 10, 1), 50);
  const res = await db.query(
    `SELECT id, nombre_cliente, numero_personas, fecha_hora_llegada,
            estado, mesa_asignada, alergias_notas, telefono
     FROM reserva
     WHERE cliente_id = $1
     ORDER BY fecha_hora_llegada DESC
     LIMIT $2`,
    [Number(clienteId), lim],
  );
  return res.rows.map((row) => ({
    id: Number(row.id),
    nombreCliente: row.nombre_cliente,
    numeroPersonas: Number(row.numero_personas),
    fechaHoraLlegada: toIso(row.fecha_hora_llegada),
    estado: row.estado,
    mesaAsignada:
      row.mesa_asignada == null ? null : Number(row.mesa_asignada),
    alergiasNotas: row.alergias_notas || '',
    telefono: row.telefono || '',
  }));
}

/**
 * Ficha completa. Busca por id o por teléfono.
 */
async function obtenerFicha({ id, telefono } = {}) {
  let cliente = null;
  if (id != null && id !== '') {
    cliente = await getClientePorId(id);
  } else if (telefono) {
    cliente = await getClientePorTelefono(telefono);
  }
  if (!cliente) return null;

  const [visitas, platos, reservas] = await Promise.all([
    resumenVisitas(cliente.id),
    platosHabituales(cliente.id),
    reservasRecientes(cliente.id),
  ]);

  const ultima =
    visitas.ultimaVentaEn ||
    cliente.ultimaVisitaEn ||
    (reservas[0] ? reservas[0].fechaHoraLlegada : null);

  return {
    cliente: {
      ...cliente,
      ultimaVisitaEn: ultima,
    },
    resumen: {
      ...visitas,
      reservasRegistradas: reservas.length,
    },
    platosHabituales: platos,
    reservasRecientes: reservas,
  };
}

async function actualizarNotasCliente(id, { alergiasNotas, nombre } = {}) {
  const fields = [];
  const params = [Number(id)];
  if (alergiasNotas != null) {
    params.push(String(alergiasNotas));
    fields.push(`alergias_notas = $${params.length}`);
  }
  if (nombre != null && String(nombre).trim() !== '') {
    params.push(String(nombre).trim());
    fields.push(`nombre = $${params.length}`);
  }
  if (fields.length === 0) {
    return getClientePorId(id);
  }
  params.push(new Date().toISOString());
  fields.push(`actualizado_en = $${params.length}`);
  const res = await db.query(
    `UPDATE cliente SET ${fields.join(', ')}
     WHERE id = $1
     RETURNING *`,
    params,
  );
  if (res.rowCount === 0) return null;
  return mapCliente(res.rows[0]);
}

module.exports = {
  obtenerFicha,
  getClientePorId,
  getClientePorTelefono,
  actualizarNotasCliente,
  platosHabituales,
};
