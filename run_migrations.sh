#!/usr/bin/env bash
# Helper script to run SQL migrations manually

set -e

if [ -z "$DATABASE_URL" ]; then
  echo "Error: DATABASE_URL is not set."
  echo "Usage: DATABASE_URL='postgres://...' bash run_migrations.sh"
  exit 1
fi

if [ ! -f "MIGRATION_GESTORCYDMONBLEU.sql" ]; then
  echo "Error: MIGRATION_GESTORCYDMONBLEU.sql not found in current directory"
  exit 1
fi

echo "Running SQL migrations from MIGRATION_GESTORCYDMONBLEU.sql..."
psql "$DATABASE_URL" -f MIGRATION_GESTORCYDMONBLEU.sql

echo "✅ Migrations completed successfully!"
