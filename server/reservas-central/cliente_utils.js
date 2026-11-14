/**
 * Normalización de teléfonos para ficha cliente (fase 1).
 * Vacío → null (no se crea cliente).
 *
 * Clave única: E.164 aproximado (+ y dígitos).
 * Sin prefijo: 9 dígitos 6/7 → +34; 10 dígitos empezando por 3 → +39.
 */

function normalizarTelefono(raw) {
  if (raw == null) return null;
  let s = String(raw).trim();
  if (!s) return null;

  s = s.replace(/[\s.\-()]/g, '');
  if (!s) return null;

  if (s.startsWith('00')) {
    s = `+${s.slice(2)}`;
  }

  const hasPlus = s.startsWith('+');
  let digits = s.replace(/\D/g, '');
  if (digits.length < 6) return null;

  if (!hasPlus) {
    // España: móvil 9 dígitos
    if (/^[67]\d{8}$/.test(digits)) {
      digits = `34${digits}`;
    // Italia: móvil 10 dígitos (3…)
    } else if (/^3\d{9}$/.test(digits)) {
      digits = `39${digits}`;
    } else if (/^34\d{9}$/.test(digits) || /^39\d{9,10}$/.test(digits)) {
      // ya trae prefijo país sin +
    }
  }

  return `+${digits}`;
}

/**
 * Busca o crea cliente. Actualiza nombre/alergias si vienen.
 * @returns {Promise<{ id: number, telefono: string }|null>}
 */
async function upsertClientePorTelefono(client, {
  telefonoRaw,
  nombre,
  alergiasNotas,
}) {
  const normalizado = normalizarTelefono(telefonoRaw);
  if (!normalizado) return null;

  const telefonoGuardar = String(telefonoRaw).trim() || normalizado;
  const nombreTrim = nombre != null ? String(nombre).trim() : '';
  const alergias =
    alergiasNotas != null ? String(alergiasNotas).trim() : '';
  const now = new Date().toISOString();

  const existing = await client.query(
    `SELECT id, telefono, nombre, alergias_notas
     FROM cliente
     WHERE telefono_normalizado = $1`,
    [normalizado],
  );

  if (existing.rowCount > 0) {
    const row = existing.rows[0];
    await client.query(
      `UPDATE cliente SET
         telefono = $2,
         nombre = CASE WHEN $3 <> '' THEN $3 ELSE nombre END,
         alergias_notas = CASE WHEN $4 <> '' THEN $4 ELSE alergias_notas END,
         actualizado_en = $5
       WHERE id = $1`,
      [row.id, telefonoGuardar, nombreTrim, alergias, now],
    );
    return { id: Number(row.id), telefono: telefonoGuardar };
  }

  const inserted = await client.query(
    `INSERT INTO cliente (
       telefono, telefono_normalizado, nombre, alergias_notas,
       creado_en, actualizado_en
     ) VALUES ($1, $2, $3, $4, $5, $5)
     RETURNING id`,
    [telefonoGuardar, normalizado, nombreTrim, alergias, now],
  );
  return { id: Number(inserted.rows[0].id), telefono: telefonoGuardar };
}

module.exports = {
  normalizarTelefono,
  upsertClientePorTelefono,
};
