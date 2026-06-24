#!/usr/bin/env bash
set -euo pipefail

create_role_and_database() {
  local database_name="$1"
  local role_name="$2"
  local role_password="$3"

  psql --username "$POSTGRES_USER" --dbname postgres \
    --set=database_name="$database_name" \
    --set=role_name="$role_name" \
    --set=role_password="$role_password" <<'SQL'
SELECT format('CREATE ROLE %I LOGIN PASSWORD %L', :'role_name', :'role_password')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = :'role_name') \gexec

SELECT format('CREATE DATABASE %I OWNER %I', :'database_name', :'role_name')
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = :'database_name') \gexec
SQL
}

create_role_and_database "$N8N_DB_NAME" "$N8N_DB_USER" "$N8N_DB_PASSWORD"
create_role_and_database "$RAG_DB_NAME" "$RAG_DB_USER" "$RAG_DB_PASSWORD"
