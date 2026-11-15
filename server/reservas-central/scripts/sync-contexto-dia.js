/**
 * Rellena contexto_dia (festivo IT/Módena + clima) para una fecha o rango.
 * Uso:
 *   node scripts/sync-contexto-dia.js
 *   node scripts/sync-contexto-dia.js 2026-11-14
 *   node scripts/sync-contexto-dia.js 2026-11-01 2026-11-14
 */
require('../load_env').loadEnv();
const db = require('../db');
const { run: runMigrations } = require('../migrate');
const { asegurarContextoDia } = require('../contexto_store');

function addDay(iso, n) {
  const [y, m, d] = iso.split('-').map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d + n));
  return dt.toISOString().slice(0, 10);
}

async function main() {
  await runMigrations();
  const a = process.argv[2] || new Date().toISOString().slice(0, 10);
  const b = process.argv[3] || a;
  let cur = a;
  const out = [];
  while (cur <= b) {
    const ctx = await asegurarContextoDia(cur);
    out.push(ctx);
    console.log(
      cur,
      ctx.esFestivo ? ctx.nombreFestivo : ctx.esFinde ? 'finde' : 'laborable',
      ctx.climaResumen || 'sin clima',
      ctx.tempMedia != null ? `${ctx.tempMedia}°C` : '',
      ctx.horaOscurece != null ? `ocaso ${ctx.horaOscurece}` : '',
    );
    cur = addDay(cur, 1);
  }
  console.log(`OK ${out.length} día(s)`);
}

main()
  .then(() => db.closePool())
  .then(() => process.exit(0))
  .catch((e) => {
    console.error(e);
    db.closePool().finally(() => process.exit(1));
  });
