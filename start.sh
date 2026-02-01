#!/usr/bin/env bash
set -e

# If RUN_SQL_MIGRATIONS=true, run SQL migration file using psql
if [ "${RUN_SQL_MIGRATIONS:-}" = "true" ]; then
  if [ -z "$DATABASE_URL" ]; then
    echo "DATABASE_URL is not set. Cannot run SQL migrations."
    exit 1
  fi
  echo "Running SQL migrations from MIGRATION_GESTORCYDMONBLEU.sql"
  psql "$DATABASE_URL" -f MIGRATION_GESTORCYDMONBLEU.sql
else
  echo "Running SQLAlchemy db.create_all() to ensure tables exist"
  python - <<'PY'
from app import db, app
with app.app_context():
    db.create_all()
print("DB initialized (db.create_all completed).")
PY
fi

# Start gunicorn bound to $PORT
exec gunicorn app:app --bind 0.0.0.0:${PORT:-8000} --workers 2 --threads 2
