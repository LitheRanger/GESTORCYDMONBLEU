#!/usr/bin/env bash
set -e

# Si RUN_SQL_MIGRATIONS=true, ejecutar SQL con psql
if [ "${RUN_SQL_MIGRATIONS:-}" = "true" ]; then
  if [ -z "$DATABASE_URL" ]; then
    echo "DATABASE_URL no está definido. Imposible ejecutar migraciones SQL."
    exit 1
  fi
  echo "Ejecutando migraciones SQL desde MIGRATION_GESTORCYDMONBLEU.sql..."
  psql "$DATABASE_URL" -f MIGRATION_GESTORCYDMONBLEU.sql
else
  echo "Ejecutando db.create_all() (SQLAlchemy) para asegurar tablas..."
  python - <<'PY'
from app import db, app
with app.app_context():
    db.create_all()
print("DB inicializada (db.create_all completado).")
PY
fi

# Iniciar gunicorn ligado al puerto $PORT que Render provee
exec gunicorn app:app --bind 0.0.0.0:${PORT:-8000} --workers 2 --threads 2
