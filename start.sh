#!/usr/bin/env bash
set -e

# If RUN_SQL_MIGRATIONS=true, run SQL migration file using psql
if [ "${RUN_SQL_MIGRATIONS:-}" = "true" ]; then
  if [ -z "$DATABASE_URL" ]; then
    echo "DATABASE_URL is not set. Cannot run SQL migrations."
    exit 1
  fi
  if [ ! -f "MIGRATION_GESTORCYDMONBLEU.sql" ]; then
    echo "Error: MIGRATION_GESTORCYDMONBLEU.sql file not found."
    exit 1
  fi
  echo "Running SQL migrations from MIGRATION_GESTORCYDMONBLEU.sql"
  psql "$DATABASE_URL" -f MIGRATION_GESTORCYDMONBLEU.sql
else
  echo "Running SQLAlchemy db.create_all() to ensure tables exist"
  python - <<'PY'
import sys
try:
    from app import db, app
    with app.app_context():
        db.create_all()
    print("DB initialized (db.create_all completed).")
except Exception as e:
    print(f"Error initializing database: {e}", file=sys.stderr)
    sys.exit(1)
PY
fi

# Start gunicorn bound to $PORT
# Using 2 workers and 2 threads per worker for small-scale deployments
# For higher traffic, increase workers (2-4 x CPU cores) via GUNICORN_WORKERS env var
exec gunicorn app:app --bind 0.0.0.0:${PORT:-8000} --workers ${GUNICORN_WORKERS:-2} --threads ${GUNICORN_THREADS:-2}
