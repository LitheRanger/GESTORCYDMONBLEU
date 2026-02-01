#!/usr/bin/env bash
set -e

# Si RUN_SQL_MIGRATIONS=true, ejecutar SQL con psql
if [ "${RUN_SQL_MIGRATIONS:-}" = "true" ]; then
  if [ -z "$DATABASE_URL" ]; then
    echo "DATABASE_URL no está definido. Imposible ejecutar migraciones SQL."
    exit 1
  fi
  echo "Ejecutando migraciones SQL desde MIGRATION_GESTORCYDMONBLEU.sql..."
  # Nota: El archivo de migración está hardcodeado según requerimientos del proyecto
  psql "$DATABASE_URL" -f MIGRATION_GESTORCYDMONBLEU.sql
else
  echo "Ejecutando db.create_all() (SQLAlchemy) para asegurar tablas..."
  # Ejecutar Python inline con mejor manejo de errores
  if ! python - <<'PY'
from app import db, app
with app.app_context():
    db.create_all()
print("DB inicializada (db.create_all completado).")
PY
  then
    echo "Error: Falló la inicialización de la base de datos con db.create_all()."
    echo "Verifica que app.py esté correcto y que las dependencias estén instaladas."
    exit 1
  fi
fi

# Iniciar gunicorn ligado al puerto $PORT que Render provee
exec gunicorn app:app --bind 0.0.0.0:${PORT:-8000} --workers 2 --threads 2
