#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [[ ! -f .env ]]; then
  echo 'Missing .env. Copy .env.example and replace every placeholder.' >&2
  exit 1
fi

if grep -q 'REPLACE_WITH_' .env; then
  echo 'One or more secret placeholders remain in .env.' >&2
  exit 1
fi

compose=(--env-file .env -f docker-compose.yml -f compose.dev.yml)
if [[ "${CPU_ONLY:-false}" != "true" ]]; then
  compose+=(-f compose.gpu.yml)
fi

docker compose "${compose[@]}" config --quiet
docker compose "${compose[@]}" up -d

if [[ "${SKIP_MODEL_PULL:-false}" != "true" ]]; then
  docker compose "${compose[@]}" --profile bootstrap run --rm ollama-init
fi

./scripts/health-check.sh

