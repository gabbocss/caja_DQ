/**
 * Persistencia de reservas en PostgreSQL.
 * La forma de salida coincide con el JSON histórico (camelCase) para ApiClient.
 */
const db = require('./db');
const {
  normalizarTelefono,
  upsertClientePorTelefono,
} = require('./cliente_utils');

/** Purga reservas cuya fechaHoraLlegada es más antigua que este margen (ms). */
const RESERVAS_PURGE_MS = Number(
  process.env.RESERVAS_PURGE_MS || String(30 * 24 * 60 * 60 * 1000),
);

/** Zona del restaurante (Módena). Hora sin offset se interpreta aquí. */
const TZ_RESTAURANTE = process.env.CLIMA_TZ || 'Europe/Rome';

const ESTADOS_VALIDOS = new Set([
  'pendiente',
  'sentada',
  'cancelada',
  'cobrada',
]);

function hasTimezone(s) {
  return /[zZ]$|[+-]\d{2}:?\d{2}$/.test(String(s).trim());
}

/**
 * Convierte una hora de pared en [timeZone] a instante UTC.
 * Evita que el VPS (Etc/UTC) trate "20:30" como 20:30 UTC.
 */
function zonedLocalToUtc(y, mo, d, h, mi, se, timeZone) {
  const utcGuess = Date.UTC(y, mo - 1, d, h, mi, se);
  const dtf = new Intl.DateTimeFormat('en-US', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hourCycle: 'h23',
  });
  const parts = dtf.formatToParts(new Date(utcGuess));
  const get = (type) => Number(parts.find((p) => p.type === type)?.value || 0);
  const asUtcFromParts = Date.UTC(
    get('year'),
    get('month') - 1,
    get('day'),
    get('hour'),
    get('minute'),
    get('second'),
  );
  const offsetMs = asUtcFromParts - utcGuess;
  return new Date(utcGuess - offsetMs);
}

function toIso(value) {
  if (value == null) return null;
  if (value instanceof Date) {
    if (Number.isNaN(value.getTime())) return null;
    return value.toISOString();
  }
  const s = String(value).trim();
  if (!s) return null;

  // App antigua: "2026-11-14T20:30:00.000" sin Z → hora local Módena.
  if (!hasTimezone(s)) {
    const m =
      /^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})(?::(\d{2}))?/.exec(s);
    if (m) {
      const dt = zonedLocalToUtc(
        Number(m[1]),
        Number(m[2]),
        Number(m[3]),
        Number(m[4]),
        Number(m[5]),
        Number(m[6] || 0),
        TZ_RESTAURANTE,
      );
      return dt.toISOString();
    }
  }

  const d = new Date(s);
  if (Number.isNaN(d.getTime())) return null;
  return d.toISOString();
}

function mapItemRow(row) {
  return {
    productoId: Number(row.producto_id),
    nombreProducto: row.nombre_producto,
    cantidad: Number(row.cantidad),
    precioUnitario: Number(row.precio_unitario),
  };
}

function mapReservaRow(row, items) {
  return {
    id: Number(row.id),
    nombreCliente: row.nombre_cliente,
    numeroPersonas: Number(row.numero_personas),
    fechaHoraLlegada: toIso(row.fecha_hora_llegada),
    alergiasNotas: row.alergias_notas || '',
    telefono: row.telefono || '',
    clienteId: row.cliente_id == null ? null : Number(row.cliente_id),
    estado: row.estado,
    itemsReservados: (items || []).map(mapItemRow),
    mesaAsignada:
      row.mesa_asignada == null ? null : Number(row.mesa_asignada),
    fechaCreacion: toIso(row.fecha_creacion),
    fechaActualizacion: toIso(row.fecha_actualizacion),
  };
}

/**
 * Resuelve telefono + cliente_id.
 * - Si el body no trae la clave `telefono`, no cambia lo existente.
 * - Si trae teléfono vacío / inválido → sin ficha (null).
 */
async function resolverClienteTelefono(client, body, prev, nombreCliente, alergiasNotas) {
  if (!Object.prototype.hasOwnProperty.call(body, 'telefono')) {
    return {
      telefono: prev ? prev.telefono : null,
      clienteId: prev ? prev.cliente_id : null,
    };
  }
  const raw = body.telefono;
  const normalizado = normalizarTelefono(raw);
  if (!normalizado) {
    return { telefono: null, clienteId: null };
  }
  const cliente = await upsertClientePorTelefono(client, {
    telefonoRaw: raw,
    nombre: nombreCliente,
    alergiasNotas,
  });
  return {
    telefono: cliente.telefono,
    clienteId: cliente.id,
  };
}

function normalizarItems(raw) {
  if (!Array.isArray(raw)) return [];
  return raw.map((it) => ({
    productoId: Number(it.productoId ?? it.producto_id),
    nombreProducto: String(
      it.nombreProducto ?? it.nombre_producto ?? '',
    ).trim(),
    cantidad: Math.max(1, Number(it.cantidad) || 1),
    precioUnitario: Number(it.precioUnitario ?? it.precio_unitario) || 0,
  }));
}

async function loadItemsByReservaIds(client, ids) {
  if (!ids.length) return new Map();
  const res = await client.query(
    `SELECT reserva_id, producto_id, nombre_producto, cantidad, precio_unitario
     FROM reserva_item
     WHERE reserva_id = ANY($1::bigint[])
     ORDER BY id`,
    [ids],
  );
  const map = new Map();
  for (const row of res.rows) {
    const rid = Number(row.reserva_id);
    if (!map.has(rid)) map.set(rid, []);
    map.get(rid).push(row);
  }
  return map;
}

async function fetchReservasAsApi(client, whereSql, params) {
  const res = await client.query(
    `SELECT id, nombre_cliente, numero_personas, fecha_hora_llegada,
            alergias_notas, telefono, cliente_id, estado, mesa_asignada,
            fecha_creacion, fecha_actualizacion
     FROM reserva
     ${whereSql}
     ORDER BY fecha_hora_llegada ASC`,
    params,
  );
  const ids = res.rows.map((r) => Number(r.id));
  const itemsMap = await loadItemsByReservaIds(client, ids);
  return res.rows.map((row) =>
    mapReservaRow(row, itemsMap.get(Number(row.id)) || []),
  );
}

async function replaceItems(client, reservaId, items) {
  await client.query('DELETE FROM reserva_item WHERE reserva_id = $1', [
    reservaId,
  ]);
  for (const it of items) {
    await client.query(
      `INSERT INTO reserva_item
        (reserva_id, producto_id, nombre_producto, cantidad, precio_unitario)
       VALUES ($1, $2, $3, $4, $5)`,
      [
        reservaId,
        it.productoId,
        it.nombreProducto || 'Producto',
        it.cantidad,
        it.precioUnitario,
      ],
    );
  }
}

/**
 * Borra reservas fuera de la ventana de retención (por fecha de llegada).
 * @returns {Promise<number>} filas eliminadas
 */
async function purgeAntiguasPorFechaLlegada() {
  const cutoff = new Date(Date.now() - RESERVAS_PURGE_MS);
  const res = await db.query(
    `DELETE FROM reserva
     WHERE fecha_hora_llegada < $1
     RETURNING id`,
    [cutoff.toISOString()],
  );
  return res.rowCount || 0;
}

/** Pendientes y canceladas (caja). */
async function getPendientes() {
  await purgeAntiguasPorFechaLlegada();
  return db.withClient((client) =>
    fetchReservasAsApi(
      client,
      `WHERE estado IN ('pendiente', 'cancelada')`,
      [],
    ),
  );
}

/** Solo pendientes (móvil). */
async function getPendientesEditables() {
  await purgeAntiguasPorFechaLlegada();
  return db.withClient((client) =>
    fetchReservasAsApi(client, `WHERE estado = 'pendiente'`, []),
  );
}

/**
 * @deprecated Endpoint no-op para clientes antiguos.
 */
async function marcarSincronizadas(ids) {
  const lista = Array.isArray(ids) ? ids : [];
  const idSet = new Set(
    lista.map((x) => Number(x)).filter((n) => !Number.isNaN(n) && n > 0),
  );
  const purgadas = await purgeAntiguasPorFechaLlegada();
  return {
    marcadas: 0,
    ids: [...idSet],
    purgadas,
    deprecated: true,
  };
}

async function upsertReserva(body) {
  const now = new Date().toISOString();
  const items =
    body.itemsReservados != null
      ? normalizarItems(body.itemsReservados)
      : null;

  return db.withTransaction(async (client) => {
    if (body.id != null) {
      const id = Number(body.id);
      const existing = await client.query(
        'SELECT * FROM reserva WHERE id = $1',
        [id],
      );
      if (existing.rowCount > 0) {
        const prev = existing.rows[0];
        const nombreCliente =
          body.nombreCliente != null
            ? String(body.nombreCliente)
            : prev.nombre_cliente;
        const numeroPersonas =
          body.numeroPersonas != null
            ? Number(body.numeroPersonas)
            : Number(prev.numero_personas);
        const fechaHoraLlegada =
          body.fechaHoraLlegada != null
            ? toIso(body.fechaHoraLlegada)
            : toIso(prev.fecha_hora_llegada);
        const alergiasNotas =
          body.alergiasNotas != null
            ? String(body.alergiasNotas)
            : prev.alergias_notas || '';
        let estado = body.estado != null ? String(body.estado) : prev.estado;
        if (!ESTADOS_VALIDOS.has(estado)) estado = prev.estado;
        const mesaAsignada =
          body.mesaAsignada !== undefined
            ? body.mesaAsignada == null
              ? null
              : Number(body.mesaAsignada)
            : prev.mesa_asignada;

        const { telefono, clienteId } = await resolverClienteTelefono(
          client,
          body,
          prev,
          nombreCliente,
          alergiasNotas,
        );

        await client.query(
          `UPDATE reserva SET
             nombre_cliente = $2,
             numero_personas = $3,
             fecha_hora_llegada = $4,
             alergias_notas = $5,
             estado = $6,
             mesa_asignada = $7,
             telefono = $8,
             cliente_id = $9,
             fecha_actualizacion = $10
           WHERE id = $1`,
          [
            id,
            nombreCliente,
            numeroPersonas,
            fechaHoraLlegada,
            alergiasNotas,
            estado,
            mesaAsignada,
            telefono,
            clienteId,
            now,
          ],
        );

        if (items != null) {
          await replaceItems(client, id, items);
        }

        const rows = await fetchReservasAsApi(client, 'WHERE id = $1', [id]);
        return rows[0];
      }
    }

    const nombreCliente = String(body.nombreCliente || '').trim();
    if (!nombreCliente) {
      throw new Error('nombreCliente es obligatorio');
    }
    const numeroPersonas = Number(body.numeroPersonas);
    const fechaHoraLlegada = toIso(body.fechaHoraLlegada);
    if (!fechaHoraLlegada) {
      throw new Error('fechaHoraLlegada es obligatoria');
    }
    let estado = body.estado != null ? String(body.estado) : 'pendiente';
    if (!ESTADOS_VALIDOS.has(estado)) estado = 'pendiente';
    const alergiasNotas =
      body.alergiasNotas != null ? String(body.alergiasNotas) : '';
    const mesaAsignada =
      body.mesaAsignada == null ? null : Number(body.mesaAsignada);
    const fechaCreacion = toIso(body.fechaCreacion) || now;
    const itemsInsert = items != null ? items : [];

    // En alta: sin clave telefono → sin cliente (apps antiguas).
    const bodyAlta = Object.prototype.hasOwnProperty.call(body, 'telefono')
      ? body
      : { ...body, telefono: '' };
    const { telefono, clienteId } = await resolverClienteTelefono(
      client,
      bodyAlta,
      null,
      nombreCliente,
      alergiasNotas,
    );

    let insertRes;
    if (body.id != null && Number(body.id) > 0) {
      insertRes = await client.query(
        `INSERT INTO reserva (
           id, nombre_cliente, numero_personas, fecha_hora_llegada,
           alergias_notas, estado, mesa_asignada, telefono, cliente_id,
           fecha_creacion, fecha_actualizacion
         ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
         RETURNING id`,
        [
          Number(body.id),
          nombreCliente,
          Number.isFinite(numeroPersonas) ? numeroPersonas : 1,
          fechaHoraLlegada,
          alergiasNotas,
          estado,
          mesaAsignada,
          telefono,
          clienteId,
          fechaCreacion,
          now,
        ],
      );
      await client.query(
        `SELECT setval(
           pg_get_serial_sequence('reserva', 'id'),
           GREATEST(
             (SELECT COALESCE(MAX(id), 1) FROM reserva),
             1
           )
         )`,
      );
    } else {
      insertRes = await client.query(
        `INSERT INTO reserva (
           nombre_cliente, numero_personas, fecha_hora_llegada,
           alergias_notas, estado, mesa_asignada, telefono, cliente_id,
           fecha_creacion, fecha_actualizacion
         ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
         RETURNING id`,
        [
          nombreCliente,
          Number.isFinite(numeroPersonas) ? numeroPersonas : 1,
          fechaHoraLlegada,
          alergiasNotas,
          estado,
          mesaAsignada,
          telefono,
          clienteId,
          fechaCreacion,
          now,
        ],
      );
    }

    const newId = Number(insertRes.rows[0].id);
    await replaceItems(client, newId, itemsInsert);
    const rows = await fetchReservasAsApi(client, 'WHERE id = $1', [newId]);
    return rows[0];
  });
}

async function updateEstado(id, estado, mesaAsignada) {
  const estadoFinal = String(estado || 'pendiente');
  if (!ESTADOS_VALIDOS.has(estadoFinal)) {
    throw new Error(`Estado no válido: ${estadoFinal}`);
  }
  const now = new Date().toISOString();

  return db.withTransaction(async (client) => {
    const existing = await client.query(
      'SELECT id FROM reserva WHERE id = $1',
      [Number(id)],
    );
    if (existing.rowCount === 0) return null;

    if (mesaAsignada != null) {
      await client.query(
        `UPDATE reserva SET
           estado = $2,
           mesa_asignada = $3,
           fecha_actualizacion = $4
         WHERE id = $1`,
        [Number(id), estadoFinal, Number(mesaAsignada), now],
      );
    } else {
      await client.query(
        `UPDATE reserva SET
           estado = $2,
           fecha_actualizacion = $3
         WHERE id = $1`,
        [Number(id), estadoFinal, now],
      );
    }

    const rows = await fetchReservasAsApi(client, 'WHERE id = $1', [
      Number(id),
    ]);
    return rows[0];
  });
}

/** Lectura cruda (p. ej. scripts). */
async function readAll() {
  return db.withClient((client) => fetchReservasAsApi(client, '', []));
}

module.exports = {
  getPendientes,
  getPendientesEditables,
  marcarSincronizadas,
  upsertReserva,
  updateEstado,
  purgeAntiguasPorFechaLlegada,
  readAll,
};
