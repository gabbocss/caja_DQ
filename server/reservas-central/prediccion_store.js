/**
 * Predicción de demanda por día/servicio (fase 6).
 * base (histórico + época + contexto) + uplift (clientes con reserva) + firmado.
 */
const db = require('./db');
const { asegurarContextoDia, fechaSolo } = require('./contexto_store');

const TZ = process.env.CLIMA_TZ || 'Europe/Rome';
/** Hora local (0–23) a partir de la cual se considera cena. */
const HORA_CENA = Number(process.env.PRED_HORA_CENA || 17);
/** Ventana amplia (~1 año) para poder comparar con la misma estación del año anterior. */
const VENTANA_DIAS = Number(process.env.PRED_VENTANA_DIAS || 400);
const MIN_VISITAS_HABITO = Number(process.env.PRED_MIN_VISITAS || 2);
const FREQ_HABITO = Number(process.env.PRED_FREQ_HABITO || 0.5);

/** Estaciones meteorológicas (hemisferio norte / Italia). */
const NOMBRE_ESTACION = {
  0: 'invierno',
  1: 'primavera',
  2: 'verano',
  3: 'otono',
};

function round1(n) {
  return Math.round(Number(n) * 10) / 10;
}

/**
 * Estación meteorológica: 0 invierno, 1 primavera, 2 verano, 3 otoño.
 * @param {string|Date} fecha YYYY-MM-DD o Date
 */
function estacionDesdeFecha(fecha) {
  const s = typeof fecha === 'string' ? fecha : fechaSolo(fecha);
  const mes = Number(String(s).slice(5, 7));
  if (mes === 12 || mes === 1 || mes === 2) return 0;
  if (mes >= 3 && mes <= 5) return 1;
  if (mes >= 6 && mes <= 8) return 2;
  return 3;
}

/**
 * Clasifica comida/cena según hora local Europe/Rome.
 */
function servicioDesdeTs(ts) {
  const d = ts instanceof Date ? ts : new Date(ts);
  const parts = new Intl.DateTimeFormat('en-GB', {
    timeZone: TZ,
    hour: 'numeric',
    hour12: false,
  }).formatToParts(d);
  const hour = Number(parts.find((p) => p.type === 'hour')?.value || 0);
  if (hour >= HORA_CENA || hour < 5) return 'cena';
  if (hour >= 10) return 'comida';
  return 'otro';
}

/**
 * Demanda base: media de unidades/día en días similares
 * (misma época del año + mismo DOW / festivo / finde).
 */
async function demandaBase(fecha, servicio) {
  const ctx = await asegurarContextoDia(fecha);
  const estacion = estacionDesdeFecha(fecha);
  const res = await db.query(
    `WITH diarios AS (
       SELECT
         (v.fecha_cierre AT TIME ZONE $3)::date AS fecha,
         vi.producto_id,
         MAX(vi.nombre_producto) AS nombre_producto,
         SUM(vi.cantidad)::float AS unidades
       FROM venta v
       JOIN venta_item vi ON vi.venta_id = v.id
       WHERE v.servicio = $1
         AND (v.fecha_cierre AT TIME ZONE $3)::date < $2::date
         AND v.fecha_cierre >= ($2::date - ($4 || ' days')::interval)
       GROUP BY 1, 2
     ),
     enriquecido AS (
       SELECT
         d.*,
         COALESCE(c.dia_semana, EXTRACT(DOW FROM d.fecha)::int) AS dia_semana,
         COALESCE(c.es_festivo, false) AS es_festivo,
         COALESCE(c.es_finde, false) AS es_finde,
         CASE
           WHEN EXTRACT(MONTH FROM d.fecha)::int IN (12, 1, 2) THEN 0
           WHEN EXTRACT(MONTH FROM d.fecha)::int BETWEEN 3 AND 5 THEN 1
           WHEN EXTRACT(MONTH FROM d.fecha)::int BETWEEN 6 AND 8 THEN 2
           ELSE 3
         END AS estacion
       FROM diarios d
       LEFT JOIN contexto_dia c ON c.fecha = d.fecha
     )
     SELECT
       producto_id,
       MAX(nombre_producto) AS nombre_producto,
       AVG(unidades) FILTER (
         WHERE estacion = $8 AND dia_semana = $5 AND es_festivo = $6
       ) AS avg_festivo_epoca_dow,
       COUNT(*) FILTER (
         WHERE estacion = $8 AND dia_semana = $5 AND es_festivo = $6
       ) AS n_festivo_epoca_dow,
       AVG(unidades) FILTER (
         WHERE estacion = $8 AND dia_semana = $5
       ) AS avg_epoca_dow,
       COUNT(*) FILTER (
         WHERE estacion = $8 AND dia_semana = $5
       ) AS n_epoca_dow,
       AVG(unidades) FILTER (WHERE estacion = $8) AS avg_epoca,
       COUNT(*) FILTER (WHERE estacion = $8) AS n_epoca,
       AVG(unidades) FILTER (WHERE dia_semana = $5) AS avg_dow,
       COUNT(*) FILTER (WHERE dia_semana = $5) AS n_dow,
       AVG(unidades) FILTER (
         WHERE es_festivo = $6 AND dia_semana = $5
       ) AS avg_festivo_dow,
       COUNT(*) FILTER (
         WHERE es_festivo = $6 AND dia_semana = $5
       ) AS n_festivo_dow,
       AVG(unidades) FILTER (WHERE es_finde = $7) AS avg_finde,
       COUNT(*) FILTER (WHERE es_finde = $7) AS n_finde,
       AVG(unidades) AS avg_global,
       COUNT(*) AS n_global
     FROM enriquecido
     GROUP BY producto_id`,
    [
      servicio,
      fecha,
      TZ,
      String(VENTANA_DIAS),
      ctx.diaSemana,
      ctx.esFestivo,
      ctx.esFinde,
      estacion,
    ],
  );

  const map = new Map();
  for (const row of res.rows) {
    let base = 0;
    let fuente = 'global';
    const nFestEpoca = Number(row.n_festivo_epoca_dow) || 0;
    const nEpocaDow = Number(row.n_epoca_dow) || 0;
    const nEpoca = Number(row.n_epoca) || 0;
    const nFest = Number(row.n_festivo_dow) || 0;
    const nDow = Number(row.n_dow) || 0;
    const nFinde = Number(row.n_finde) || 0;
    const nGlobal = Number(row.n_global) || 0;

    // Prioriza misma época del año para no mezclar verano con invierno.
    if (
      ctx.esFestivo &&
      nFestEpoca >= 1 &&
      row.avg_festivo_epoca_dow != null
    ) {
      base = Number(row.avg_festivo_epoca_dow);
      fuente = 'festivo+epoca+dow';
    } else if (nEpocaDow >= 2 && row.avg_epoca_dow != null) {
      base = Number(row.avg_epoca_dow);
      fuente = 'epoca+dow';
    } else if (nEpocaDow >= 1 && row.avg_epoca_dow != null) {
      base = Number(row.avg_epoca_dow);
      fuente = 'epoca+dow-escaso';
    } else if (nEpoca >= 2 && row.avg_epoca != null) {
      base = Number(row.avg_epoca);
      fuente = 'epoca';
    } else if (ctx.esFestivo && nFest >= 1 && row.avg_festivo_dow != null) {
      base = Number(row.avg_festivo_dow);
      fuente = 'festivo+dow';
    } else if (nDow >= 2 && row.avg_dow != null) {
      base = Number(row.avg_dow);
      fuente = 'mismo-dow';
    } else if (nDow >= 1 && row.avg_dow != null) {
      base = Number(row.avg_dow);
      fuente = 'mismo-dow-escaso';
    } else if (nFinde >= 2 && row.avg_finde != null) {
      base = Number(row.avg_finde);
      fuente = 'finde';
    } else if (nGlobal >= 1 && row.avg_global != null) {
      base = Number(row.avg_global);
      fuente = 'global';
    }

    map.set(Number(row.producto_id), {
      productoId: Number(row.producto_id),
      nombreProducto: row.nombre_producto,
      base: round1(base),
      fuenteBase: fuente,
      muestras: {
        epocaDow: nEpocaDow,
        epoca: nEpoca,
        festivoEpocaDow: nFestEpoca,
        dow: nDow,
        festivoDow: nFest,
        finde: nFinde,
        global: nGlobal,
      },
    });
  }
  return {
    ctx: {
      ...ctx,
      estacion,
      nombreEstacion: NOMBRE_ESTACION[estacion] || null,
    },
    map,
  };
}

/**
 * Ítems ya reservados (demanda firme) del día/servicio.
 */
async function demandaFirmada(fecha, servicio) {
  const detalle = await db.query(
    `SELECT
       r.id AS reserva_id,
       r.fecha_hora_llegada,
       ri.producto_id,
       ri.nombre_producto,
       ri.cantidad
     FROM reserva r
     JOIN reserva_item ri ON ri.reserva_id = r.id
     WHERE (r.fecha_hora_llegada AT TIME ZONE $2)::date = $1::date
       AND r.estado <> 'cancelada'`,
    [fecha, TZ],
  );

  const out = new Map();
  for (const row of detalle.rows) {
    if (servicioDesdeTs(row.fecha_hora_llegada) !== servicio) continue;
    const pid = Number(row.producto_id);
    const cur = out.get(pid) || {
      productoId: pid,
      nombreProducto: row.nombre_producto,
      firmado: 0,
      reservaIds: new Set(),
    };
    cur.firmado += Number(row.cantidad) || 0;
    cur.reservaIds.add(Number(row.reserva_id));
    cur.nombreProducto = row.nombre_producto || cur.nombreProducto;
    out.set(pid, cur);
  }

  for (const [pid, v] of out) {
    out.set(pid, {
      ...v,
      firmado: round1(v.firmado),
      reservaIds: [...v.reservaIds],
    });
  }
  return out;
}

/**
 * Uplift por hábitos de clientes con reserva ese día (excluye platos ya en su reserva).
 */
async function demandaUplift(fecha, servicio) {
  const reservas = await db.query(
    `SELECT
       r.id,
       r.cliente_id,
       r.nombre_cliente,
       r.fecha_hora_llegada,
       r.numero_personas
     FROM reserva r
     WHERE (r.fecha_hora_llegada AT TIME ZONE $2)::date = $1::date
       AND r.estado <> 'cancelada'
       AND r.cliente_id IS NOT NULL`,
    [fecha, TZ],
  );

  const delServicio = reservas.rows.filter(
    (r) => servicioDesdeTs(r.fecha_hora_llegada) === servicio,
  );
  if (delServicio.length === 0) {
    return { map: new Map(), clientesConsiderados: 0, detalle: [] };
  }

  const clienteIds = [...new Set(delServicio.map((r) => Number(r.cliente_id)))];
  const reservaIds = delServicio.map((r) => Number(r.id));

  const itemsYa = await db.query(
    `SELECT reserva_id, producto_id
     FROM reserva_item
     WHERE reserva_id = ANY($1::bigint[])`,
    [reservaIds],
  );
  const yaPorReserva = new Map();
  for (const row of itemsYa.rows) {
    const rid = Number(row.reserva_id);
    if (!yaPorReserva.has(rid)) yaPorReserva.set(rid, new Set());
    yaPorReserva.get(rid).add(Number(row.producto_id));
  }

  const habitos = await db.query(
    `WITH visitas AS (
       SELECT cliente_id, COUNT(*)::float AS n_visitas
       FROM venta
       WHERE cliente_id = ANY($1::bigint[])
       GROUP BY cliente_id
     ),
     por_plato AS (
       SELECT
         v.cliente_id,
         vi.producto_id,
         MAX(vi.nombre_producto) AS nombre_producto,
         COUNT(DISTINCT v.id)::float AS n_con_plato,
         AVG(vi.cantidad)::float AS qty_media
       FROM venta v
       JOIN venta_item vi ON vi.venta_id = v.id
       WHERE v.cliente_id = ANY($1::bigint[])
       GROUP BY v.cliente_id, vi.producto_id
     )
     SELECT
       p.cliente_id,
       p.producto_id,
       p.nombre_producto,
       p.qty_media,
       (p.n_con_plato / NULLIF(vis.n_visitas, 0)) AS frecuencia,
       vis.n_visitas
     FROM por_plato p
     JOIN visitas vis ON vis.cliente_id = p.cliente_id
     WHERE vis.n_visitas >= $2
       AND (p.n_con_plato / NULLIF(vis.n_visitas, 0)) >= $3`,
    [clienteIds, MIN_VISITAS_HABITO, FREQ_HABITO],
  );

  const habitosPorCliente = new Map();
  for (const row of habitos.rows) {
    const cid = Number(row.cliente_id);
    if (!habitosPorCliente.has(cid)) habitosPorCliente.set(cid, []);
    habitosPorCliente.get(cid).push({
      productoId: Number(row.producto_id),
      nombreProducto: row.nombre_producto,
      qtyMedia: Number(row.qty_media) || 1,
      frecuencia: Number(row.frecuencia) || 0,
      nVisitas: Number(row.n_visitas) || 0,
    });
  }

  const map = new Map();
  const detalle = [];

  for (const r of delServicio) {
    const cid = Number(r.cliente_id);
    const rid = Number(r.id);
    const ya = yaPorReserva.get(rid) || new Set();
    const lista = habitosPorCliente.get(cid) || [];
    for (const h of lista) {
      if (ya.has(h.productoId)) continue;
      const add = round1(h.qtyMedia);
      const cur = map.get(h.productoId) || {
        productoId: h.productoId,
        nombreProducto: h.nombreProducto,
        uplift: 0,
        clientes: [],
      };
      cur.uplift = round1(cur.uplift + add);
      cur.nombreProducto = h.nombreProducto || cur.nombreProducto;
      cur.clientes.push({
        clienteId: cid,
        nombre: r.nombre_cliente,
        reservaId: rid,
        cantidad: add,
        frecuencia: round1(h.frecuencia),
      });
      map.set(h.productoId, cur);
      detalle.push({
        clienteId: cid,
        nombreCliente: r.nombre_cliente,
        reservaId: rid,
        productoId: h.productoId,
        nombreProducto: h.nombreProducto,
        cantidad: add,
        frecuencia: round1(h.frecuencia),
      });
    }
  }

  return {
    map,
    clientesConsiderados: clienteIds.length,
    reservasConCliente: delServicio.length,
    detalle,
  };
}

/**
 * Predicción completa para una fecha y servicio.
 */
async function predecir({ fecha: fechaRaw, servicio: servicioRaw } = {}) {
  const fecha = fechaSolo(fechaRaw);
  let servicio = String(servicioRaw || 'comida');
  if (!['comida', 'cena'].includes(servicio)) {
    servicio = 'comida';
  }

  const { ctx, map: baseMap } = await demandaBase(fecha, servicio);
  const firmadoMap = await demandaFirmada(fecha, servicio);
  const uplift = await demandaUplift(fecha, servicio);

  const ids = new Set([
    ...baseMap.keys(),
    ...firmadoMap.keys(),
    ...uplift.map.keys(),
  ]);

  const platos = [];
  for (const pid of ids) {
    const b = baseMap.get(pid);
    const f = firmadoMap.get(pid);
    const u = uplift.map.get(pid);
    const base = b?.base || 0;
    const firmado = f?.firmado || 0;
    const upliftVal = u?.uplift || 0;
    // Evita infraestimar lo ya reservado; el uplift solo suma hábitos no firmados.
    const prediccion = round1(Math.max(base, firmado) + upliftVal);
    if (prediccion <= 0 && base <= 0 && firmado <= 0 && upliftVal <= 0) {
      continue;
    }
    platos.push({
      productoId: pid,
      nombreProducto:
        b?.nombreProducto || f?.nombreProducto || u?.nombreProducto || 'Producto',
      base: round1(base),
      firmado: round1(firmado),
      uplift: round1(upliftVal),
      prediccion,
      fuenteBase: b?.fuenteBase || null,
      muestras: b?.muestras || null,
      upliftClientes: u?.clientes || [],
    });
  }

  platos.sort((a, b) => b.prediccion - a.prediccion);

  const nVentas = await db.query(
    `SELECT COUNT(*)::int AS n
     FROM venta
     WHERE servicio = $1
       AND fecha_cierre >= ($2::date - ($3 || ' days')::interval)
       AND (fecha_cierre AT TIME ZONE $4)::date < $2::date`,
    [servicio, fecha, String(VENTANA_DIAS), TZ],
  );

  return {
    fecha,
    servicio,
    contexto: ctx,
    resumen: {
      platos: platos.length,
      prediccionTotal: round1(
        platos.reduce((s, p) => s + p.prediccion, 0),
      ),
      baseTotal: round1(platos.reduce((s, p) => s + p.base, 0)),
      firmadoTotal: round1(platos.reduce((s, p) => s + p.firmado, 0)),
      upliftTotal: round1(platos.reduce((s, p) => s + p.uplift, 0)),
      ventasHistoricasVentana: nVentas.rows[0]?.n || 0,
      reservasConCliente: uplift.reservasConCliente || 0,
      clientesConHabito: uplift.clientesConsiderados || 0,
      ventanaDias: VENTANA_DIAS,
      aviso:
        (nVentas.rows[0]?.n || 0) < 10
          ? 'Poco histórico aún: la previsión es orientativa.'
          : null,
    },
    platos,
    upliftDetalle: uplift.detalle,
  };
}

module.exports = {
  predecir,
  servicioDesdeTs,
  estacionDesdeFecha,
  demandaBase,
  demandaFirmada,
  demandaUplift,
};
