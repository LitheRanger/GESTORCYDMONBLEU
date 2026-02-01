#!/usr/bin/env bash
set -e
if [ -z "$DATABASE_URL" ]; then
  echo "DATABASE_URL is not set."
  exit 1
fi
psql "$DATABASE_URL" -f MIGRATION_GESTORCYDMONBLEU.sql
