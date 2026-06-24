#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
output="${1:-backups/workflows}"
mkdir -p "$output"

container="$(docker compose --env-file .env -f docker-compose.yml -f compose.dev.yml ps -q n8n)"
[[ -n "$container" ]] || { echo 'The n8n container is not running.' >&2; exit 1; }

docker compose --env-file .env -f docker-compose.yml -f compose.dev.yml exec -T n8n sh -c 'rm -rf /tmp/n8n-workflow-export && mkdir -p /tmp/n8n-workflow-export'
docker compose --env-file .env -f docker-compose.yml -f compose.dev.yml exec -T n8n n8n export:workflow --backup --output=/tmp/n8n-workflow-export
docker cp "${container}:/tmp/n8n-workflow-export/." "$output"
docker compose --env-file .env -f docker-compose.yml -f compose.dev.yml exec -T n8n rm -rf /tmp/n8n-workflow-export

echo "Workflow export completed: $output"

