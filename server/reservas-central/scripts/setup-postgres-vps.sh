#!/usr/bin/env bash
# Instala PostgreSQL en Ubuntu y crea usuario/BD para reservas-central.
# Ejecutar en el VPS con sudo: bash scripts/setup-postgres-vps.sh
set -euo pipefail

DB_NAME="${DB_NAME:-programa_caja}"
DB_USER="${DB_USER:-caja}"
DB_PASS="${DB_PASS:-caja}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Ejecuta con sudo: sudo bash $0"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y postgresql postgresql-contrib

systemctl enable --now postgresql

# Crear rol y base si no existen
sudo -u postgres psql -v ON_ERROR_STOP=1 <<SQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${DB_USER}') THEN
    CREATE ROLE ${DB_USER} LOGIN PASSWORD '${DB_PASS}';
  END IF;
END
\$\$;

SELECT 'CREATE DATABASE ${DB_NAME} OWNER ${DB_USER}'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${DB_NAME}')\gexec

GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
SQL

# Permisos en schema public (PG15+)
sudo -u postgres psql -d "${DB_NAME}" -v ON_ERROR_STOP=1 <<SQL
GRANT ALL ON SCHEMA public TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${DB_USER};
SQL

echo
echo "PostgreSQL listo."
echo "DATABASE_URL=postgresql://${DB_USER}:${DB_PASS}@127.0.0.1:5432/${DB_NAME}"
echo
echo "Siguiente:"
echo "  cd ~/reservas-central"
echo "  npm install"
echo "  export DATABASE_URL=postgresql://${DB_USER}:${DB_PASS}@127.0.0.1:5432/${DB_NAME}"
echo "  npm run migrate"
echo "  npm run import:reservas   # si tienes data/reservas.json"
echo "  pm2 restart reservas-central"
