#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
[[ -f .env ]] || { echo 'Missing .env.' >&2; exit 1; }

set -a
# shellcheck disable=SC1091
source .env
set +a

docker compose --env-file .env -f docker-compose.yml -f compose.dev.yml exec -T postgres \
  sh -c 'PGPASSWORD="$RAG_DB_PASSWORD" psql --set=ON_ERROR_STOP=1 --username "$RAG_DB_USER" --dbname "$RAG_DB_NAME"' \
  < infra/postgres/migrations/001-rag-ingestion.sql

collection="${QDRANT_COLLECTION:-rag_chunks}"
base="http://127.0.0.1:${QDRANT_HTTP_PORT:-6333}/collections/${collection}"

if ! curl -fsS -H "api-key: ${QDRANT_API_KEY}" "$base" >/dev/null; then
  curl -fsS -X PUT -H "api-key: ${QDRANT_API_KEY}" -H 'Content-Type: application/json' \
    --data '{"vectors":{"size":768,"distance":"Cosine"}}' "$base" >/dev/null
fi

for field in kb_id document_id source_sha256 content_type; do
  status="$(curl -sS -o /dev/null -w '%{http_code}' -X PUT \
    -H "api-key: ${QDRANT_API_KEY}" -H 'Content-Type: application/json' \
    --data "{\"field_name\":\"${field}\",\"field_schema\":\"keyword\"}" \
    "$base/index?wait=true")"
  [[ "$status" == 2* || "$status" == 400 || "$status" == 409 ]] || {
    echo "Could not create Qdrant payload index for ${field} (HTTP ${status})." >&2
    exit 1
  }
done

echo "RAG schema and Qdrant collection '${collection}' are ready."
