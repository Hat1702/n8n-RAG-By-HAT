# Local n8n RAG Platform

This repository contains the AI and automation layer for a self-hosted RAG platform. n8n owns document ingestion, Docling extraction, embedding, Qdrant retrieval, agent chat, knowledge-base operations, reset/reprocessing, and failure handling.

Vue is a lightweight local landing page only. The production UI is owned separately by the application team.

The target architecture is one canonical n8n canvas and one Docker Compose entry point. The approved implementation plan and current phase status are maintained in [`AGENTS.md`](./AGENTS.md).

## Local Development

1. Copy `.env.example` to `.env`.
2. Replace every `REPLACE_WITH_...` value with a fresh random secret.
3. Start Docker Desktop.
4. Keep `COMPOSE_PROFILES=cpu,local` for CPU Ollama or change it to `gpu,local` for NVIDIA.
5. Start the stack:

```powershell
docker compose --env-file .env up -d --remove-orphans
docker compose --env-file .env --profile bootstrap run --rm ollama-init
```

The PowerShell bootstrap command provides the same local setup:

```powershell
./scripts/bootstrap.ps1
```

Local ports bind to `127.0.0.1`; PostgreSQL and Redis are never published. Open the landing page at `http://localhost:8080` and the n8n editor at `http://localhost:5678`.

## Production Profile

Production uses the same `docker-compose.yml` with Caddy-managed HTTPS. Set production n8n routing variables in `.env`, generate fresh secrets on the target host, and do not copy the development credentials database.

```bash
COMPOSE_PROFILES=cpu,production docker compose --env-file .env up -d --remove-orphans
```

Use `COMPOSE_PROFILES=gpu,production` on an NVIDIA host.

## Workflow

The canonical workflow is `n8n/workflows/local-rag-agent.json`. It preserves the `POST /webhook/rag` contract for `ingest`, `query`, `reset`, and `reprocess` actions.

- The entire orchestration remains on one canvas.
- Docling and advanced Qdrant operations use HTTP Request nodes.
- Ollama chat and embeddings use native n8n AI nodes where supported.
- MinIO stores source documents and generated artifacts.
- PostgreSQL stores document lifecycle and failure state.

## Validation Boundary

Repository refactor phases use static configuration, expression, credential-reference, and connection validation only. Workflow executions, smoke tests, uploads, model calls, database mutations, and end-to-end tests run only when explicitly requested.

See [`AGENTS.md`](./AGENTS.md) for architecture, environment, phase status, and agent guidance.
