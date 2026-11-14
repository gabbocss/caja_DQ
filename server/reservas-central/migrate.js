/**
 * Aplica migraciones SQL de ./migrations en orden (001_*.sql, 002_*.sql, …).
 * Uso: node migrate.js
 * Requiere DATABASE_URL.
 */
require('./load_env').loadEnv();

const fs = require('fs');
const path = require('path');
const db = require('./db');

const MIGRATIONS_DIR = path.join(__dirname, 'migrations');

async function ensureMigrationsTable(client) {
  await client.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      id TEXT PRIMARY KEY,
      applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )
  `);
}

async function appliedIds(client) {
  const res = await client.query('SELECT id FROM schema_migrations ORDER BY id');
  return new Set(res.rows.map((r) => r.id));
}

function listMigrationFiles() {
  if (!fs.existsSync(MIGRATIONS_DIR)) {
    return [];
  }
  return fs
    .readdirSync(MIGRATIONS_DIR)
    .filter((f) => /^\d+_.*\.sql$/i.test(f))
    .sort();
}

async function run() {
  const files = listMigrationFiles();
  if (files.length === 0) {
    console.log('No hay archivos de migración en', MIGRATIONS_DIR);
    return;
  }

  await db.withClient(async (client) => {
    await ensureMigrationsTable(client);
    const done = await appliedIds(client);

    for (const file of files) {
      if (done.has(file)) {
        console.log(`  omitida (ya aplicada): ${file}`);
        continue;
      }
      const full = path.join(MIGRATIONS_DIR, file);
      const sql = fs.readFileSync(full, 'utf8');
      console.log(`  aplicando: ${file}`);
      await client.query('BEGIN');
      try {
        await client.query(sql);
        await client.query(
          'INSERT INTO schema_migrations (id) VALUES ($1)',
          [file],
        );
        await client.query('COMMIT');
        console.log(`  ok: ${file}`);
      } catch (e) {
        await client.query('ROLLBACK');
        throw e;
      }
    }
  });

  console.log('Migraciones completadas.');
}

if (require.main === module) {
  run()
    .then(() => db.closePool())
    .then(() => process.exit(0))
    .catch((e) => {
      console.error('Error en migraciones:', e);
      db.closePool().finally(() => process.exit(1));
    });
}

module.exports = { run };
