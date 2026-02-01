#!/usr/bin/env bash
set -e
if [ -z "$DATABASE_URL" ]; then
  echo "DATABASE_URL no está definido."
  exit 1
fi
psql "$DATABASE_URL" -f MIGRATION_GESTORCYDMONBLEU.sql
