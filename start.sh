#!/usr/bin/env bash
set -e

# Crear tablas si no existen (usa SQLAlchemy)
python - <<'PY'
from app import db, app
with app.app_context():
    db.create_all()
print("DB initialized (db.create_all completed).")
PY

# Iniciar gunicorn (bind a $PORT)
exec gunicorn app:app --bind 0.0.0.0:${PORT:-8000} --workers 2 --threads 2
