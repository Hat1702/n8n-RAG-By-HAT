# Local n8n RAG Platform

This repository is the portable source for a self-hosted RAG platform. n8n owns ingestion,
retrieval, chat, and knowledge-base automation. Vue is a presentation client only.

## Phase status

- Phase 1: repository and Compose foundation — complete
- Phase 2: runtime infrastructure and health validation — complete
- Phase 3: Codex and n8n integration — complete
- Phase 4: single-canvas ingestion, retrieval, reset, and reprocess workflow — complete
- Phase 6: Vue knowledge workspace — complete
- Phases 5 and 7: extended observability and production operations — baseline implemented

Phase 1 Compose validation passed on all local/production and CPU/GPU combinations.
Phase 3 live MCP validation passed against the local n8n API.

## Local development

1. Copy `.env.example` to `.env`.
2. Replace every `REPLACE_WITH_...` value with a fresh random secret.
3. Start Docker Desktop.
4. Validate before starting:

```powershell
docker compose --env-file .env -f docker-compose.yml -f compose.dev.yml -f compose.gpu.yml config --quiet
```

The Phase 2 start command will be:

```powershell
docker compose --env-file .env -f docker-compose.yml -f compose.dev.yml -f compose.gpu.yml up -d
docker compose --env-file .env -f docker-compose.yml -f compose.dev.yml --profile bootstrap run --rm ollama-init
```

The repeatable local command is now:

```powershell
./scripts/bootstrap.ps1
```

Local ports bind to `127.0.0.1`; PostgreSQL and Redis are never published.

Open the application at `http://localhost:8080`. The n8n editor remains available at
`http://localhost:5678` for workflow maintenance.

## Production

Production uses `compose.prod.yml`, public DNS, and Caddy-managed HTTPS. Generate fresh
production secrets on the VPS. Do not copy the development `.env` or credentials database.

```bash
docker compose --env-file .env -f docker-compose.yml -f compose.prod.yml -f compose.gpu.yml config --quiet
```

See `docs/` for architecture and environment guidance.

Codex-to-n8n API setup is documented in `docs/codex-n8n-integration.md`.
