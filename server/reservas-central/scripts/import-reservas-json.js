/**
 * Importa data/reservas.json (o ruta pasada) a PostgreSQL.
 * Idempotente por id: si el id existe, actualiza; si no, inserta.
 *
 * Uso:
 *   DATABASE_URL=... node scripts/import-reservas-json.js
 *   DATABASE_URL=... node scripts/import-reservas-json.js ./data/reservas.json
 */
require('../load_env').loadEnv();

const fs = require('fs');
const path = require('path');
const db = require('../db');
const { run: runMigrations } = require('../migrate');
const reservasStore = require('../reservas_store');

async function main() {
  const fileArg = process.argv[2];
  const filePath = path.resolve(
    fileArg ||
      process.env.RESERVAS_JSON ||
      path.join(__dirname, '..', 'data', 'reservas.json'),
  );

  if (!fs.existsSync(filePath)) {
    console.error('No se encontró el archivo:', filePath);
    process.exit(1);
  }

  console.log('Aplicando migraciones…');
  await runMigrations();

  const raw = fs.readFileSync(filePath, 'utf8');
  const data = raw.trim() ? JSON.parse(raw) : [];
  if (!Array.isArray(data)) {
    throw new Error('El JSON debe ser un array de reservas');
  }

  console.log(`Importando ${data.length} reservas desde ${filePath}…`);
  let ok = 0;
  for (const reserva of data) {
    // Preserva id si viene; upsertReserva actualiza o inserta.
    await reservasStore.upsertReserva(reserva);
    ok += 1;
  }

  await db.query(
    `SELECT setval(
       pg_get_serial_sequence('reserva', 'id'),
       GREATEST((SELECT COALESCE(MAX(id), 1) FROM reserva), 1)
     )`,
  );

  console.log(`Importadas/actualizadas: ${ok}`);
}

main()
  .then(() => db.closePool())
  .then(() => process.exit(0))
  .catch((e) => {
    console.error('Error en importación:', e);
    db.closePool().finally(() => process.exit(1));
  });
