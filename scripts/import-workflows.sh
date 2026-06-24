#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
input="${1:-n8n/workflows}"
active_state="${ACTIVE_STATE:-false}"

[[ -d "$input" ]] || { echo "Workflow input directory does not exist: $input" >&2; exit 1; }
mapfile -d '' files < <(find "$input" -type f -name '*.json' -print0)
(( ${#files[@]} > 0 )) || { echo "No workflow JSON files found under $input" >&2; exit 1; }

container="$(docker compose --env-file .env -f docker-compose.yml -f compose.dev.yml ps -q n8n)"
[[ -n "$container" ]] || { echo 'The n8n container is not running.' >&2; exit 1; }

docker compose --env-file .env -f docker-compose.yml -f compose.dev.yml exec -T n8n sh -c 'rm -rf /tmp/n8n-workflow-import && mkdir -p /tmp/n8n-workflow-import'

for file in "${files[@]}"; do
  name="$(basename "$file")"
  target="/tmp/n8n-workflow-import/$name"
  docker cp "$file" "${container}:$target"
  docker compose --env-file .env -f docker-compose.yml -f compose.dev.yml exec -T n8n n8n import:workflow --input="$target" --activeState="$active_state"
done

docker compose --env-file .env -f docker-compose.yml -f compose.dev.yml exec -T n8n rm -rf /tmp/n8n-workflow-import
echo "Imported ${#files[@]} workflow file(s)."

