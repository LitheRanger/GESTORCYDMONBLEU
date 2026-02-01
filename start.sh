#!/usr/bin/env bash
set -e

echo "Starting GESTORCYDMONBLEU backend..."

# Crear tablas si no existen (usa SQLAlchemy)
echo "Initializing database..."
python - <<'PY'
import sys
try:
    from app import db, app
    with app.app_context():
        db.create_all()
    print("✓ DB initialized (db.create_all completed).")
except Exception as e:
    print(f"✗ Database initialization failed: {e}", file=sys.stderr)
    sys.exit(1)
PY

if [ $? -ne 0 ]; then
    echo "Failed to initialize database. Exiting."
    exit 1
fi

# Iniciar gunicorn (bind a $PORT)
echo "Starting gunicorn..."
exec gunicorn app:app --bind 0.0.0.0:${PORT:-8000} --workers 2 --threads 2
