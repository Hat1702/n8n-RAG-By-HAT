#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
set -a
. ./.env
set +a

compose=(--env-file .env -f docker-compose.yml -f compose.dev.yml)
services=(postgres redis minio qdrant ollama docling n8n n8n-worker frontend caddy)

for service in "${services[@]}"; do
  container_id="$(docker compose "${compose[@]}" ps -q "$service")"
  [[ -n "$container_id" ]] || { echo "$service is not running" >&2; exit 1; }
  status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container_id")"
  [[ "$status" == healthy ]] || { echo "$service health status is $status" >&2; exit 1; }
  echo "[healthy] $service"
done

curl -fsS "http://127.0.0.1:${CADDY_HTTP_PORT}/health" >/dev/null
curl -fsS "http://127.0.0.1:${N8N_PORT}/healthz" >/dev/null
curl -fsS "http://127.0.0.1:${MINIO_API_PORT}/minio/health/live" >/dev/null
curl -fsS "http://127.0.0.1:${DOCLING_PORT}/health" >/dev/null
curl -fsS "http://127.0.0.1:${OLLAMA_PORT}/api/tags" >/dev/null
curl -fsS -H "api-key: ${QDRANT_API_KEY}" "http://127.0.0.1:${QDRANT_HTTP_PORT}/collections" >/dev/null

echo 'All Phase 2 service health checks passed.'
