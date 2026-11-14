/**
 * Pool de PostgreSQL. Requiere DATABASE_URL.
 * Ejemplo: postgresql://caja:caja@127.0.0.1:5432/programa_caja
 */
const { Pool } = require('pg');

let pool = null;

function getDatabaseUrl() {
  const url = process.env.DATABASE_URL;
  if (!url || !String(url).trim()) {
    throw new Error(
      'DATABASE_URL no está definida. Ejemplo: postgresql://caja:caja@127.0.0.1:5432/programa_caja',
    );
  }
  return String(url).trim();
}

function getPool() {
  if (pool) return pool;
  pool = new Pool({
    connectionString: getDatabaseUrl(),
    max: Number(process.env.PG_POOL_MAX || 10),
    idleTimeoutMillis: Number(process.env.PG_IDLE_TIMEOUT_MS || 30000),
  });
  pool.on('error', (err) => {
    console.error('Error inesperado en el pool de PostgreSQL:', err);
  });
  return pool;
}

async function query(text, params) {
  return getPool().query(text, params);
}

async function withClient(fn) {
  const client = await getPool().connect();
  try {
    return await fn(client);
  } finally {
    client.release();
  }
}

async function withTransaction(fn) {
  return withClient(async (client) => {
    await client.query('BEGIN');
    try {
      const result = await fn(client);
      await client.query('COMMIT');
      return result;
    } catch (e) {
      try {
        await client.query('ROLLBACK');
      } catch (_) {
        /* ignore */
      }
      throw e;
    }
  });
}

async function closePool() {
  if (!pool) return;
  await pool.end();
  pool = null;
}

module.exports = {
  getPool,
  getDatabaseUrl,
  query,
  withClient,
  withTransaction,
  closePool,
};
