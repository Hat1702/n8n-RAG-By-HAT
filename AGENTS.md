# Agent Instructions

This repository is for production-quality n8n workflow design, implementation, validation, troubleshooting, and maintenance.

## Operating rules

- Use n8n MCP first, then installed n8n skill packs, then repository files.
- Treat MCP results as authoritative.
- Verify before assuming node parameters, workflow structure, credentials, or runtime topology.
- Prefer native n8n nodes over code. Code nodes are a last resort.
- Search templates before building from scratch.
- Validate nodes, expressions, workflow wiring, and execution behavior before completion.
- Keep changes small, maintainable, and production-ready.
- Preserve existing behavior when modifying live workflows.

## What this repo is doing

- n8n is the application and orchestration layer.
- Vue is UI only.
- The stack is local-first, portable, and n8n-first.
- The main orchestration workflow is a single-canvas RAG workflow in n8n.
- Retrieval, ingestion, chunking, embeddings, and generation are owned by n8n.

## Current architecture

- Local Docker stack includes n8n, PostgreSQL, Redis, MinIO, Qdrant, Ollama, Docling, and Caddy.
- Local development exposes Caddy and maintenance ports only on `127.0.0.1`.
- Production uses the optional Caddy HTTPS profile as the public entry point.
- n8n main handles webhooks and scheduling.
- n8n workers consume queued jobs from Redis.
- PostgreSQL stores n8n state and RAG metadata in separate databases and roles.
- MinIO stores source documents and generated artifacts privately.
- Docling converts documents to structured JSON and Markdown.
- Ollama provides local chat and embedding models.
- Qdrant stores vectors and source metadata.
- Runtime services communicate over the private Docker network using service names.

## Local endpoints

| Service | Host endpoint | Container endpoint |
|---|---|---|
| Caddy | `http://127.0.0.1:8080` | `http://caddy:80` |
| n8n | `http://127.0.0.1:5678` | `http://n8n:5678` |
| MinIO API | `http://127.0.0.1:9000` | `http://minio:9000` |
| MinIO console | `http://127.0.0.1:9001` | `http://minio:9001` |
| Qdrant | `http://127.0.0.1:6333` | `http://qdrant:6333` |
| Ollama | `http://127.0.0.1:11434` | `http://ollama:11434` |
| Docling | `http://127.0.0.1:5001` | `http://docling:5001` |

Containers must not use `localhost` to reach each other.

## Contract

`POST /webhook/rag` accepts JSON or `multipart/form-data`.

- `ingest`: file field `file` preferred, legacy `data` accepted, optional `kbId` and `force`
- `query`: `query` or `message`, optional `kbId` and `topK` from 1 to 12
- `reset`: `confirm=RESET` and either `documentId` or `kbId`
- `reprocess`: `confirm=RESET` and `documentId`

Default knowledge base: `00000000-0000-4000-8000-000000000001`

Uploads are limited to 25 MiB.

## Stored artifacts

All MinIO objects remain private.

```text
documents/{kbId}/{documentId}/
|-- source/original
|-- extracted/document.json
|-- extracted/document.md
|-- extracted/manifest.json
|-- extracted/images/
`-- chunks/chunks.json
```

## Deployment and recovery

- Production target: Linux GPU VPS with Docker Engine and Compose plugin.
- Only Caddy publishes public production ports.
- n8n, PostgreSQL, Redis, MinIO, Qdrant, Ollama, and Docling stay private.
- Backup and restore must cover PostgreSQL, MinIO, Qdrant, n8n state, exports, and the `N8N_ENCRYPTION_KEY`.
- Copying the repo does not copy Docker named volumes.

## Repo conventions

- Read this file first for repo context.
- Prefer implementing the full workflow in n8n before adding supporting UI or docs.
- Use the smallest effective change.
- Revalidate after every meaningful change.

## Refactor Status

Status: Complete. Phases 0 through 6 were implemented on 2026-06-25.

- `docker-compose.yml` is the only Compose definition. Local profiles are `cpu,local` or `gpu,local`; production profiles are `cpu,production` or `gpu,production`; `bootstrap` pulls Ollama models.
- `n8n/workflows/local-rag-agent.json` is the only canonical workflow export.
- The live n8n instance contains one active workflow: `Local RAG Agent - Single Canvas` (`xvQcaX6q48pm5JzJ`).
- All ingestion, scheduled intake, Docling processing, indexing, agent retrieval, reset/reprocessing, and failure handling remain on one organized canvas.
- Docling uses its HTTP API with OCR, accurate tables, referenced images, code/formula enrichment, picture classification, and structured provenance.
- Native Ollama Embeddings feed native Qdrant Vector Store nodes for indexing and retrieval.
- The native Ollama Chat Model feeds the AI Agent, structured output parser, and Vector Store Question Answer Tool.
- Qdrant payload text is stored under `text`; filterable source fields are nested under `metadata` and indexed by `scripts/initialize-rag.ps1`.
- A `Future MCP Tools` canvas area is reserved without an unconfigured MCP node.
- Obsolete phase, ingestion-subworkflow, and worker-smoke workflows were removed from the live instance.

## Validation Policy

- The canonical workflow passed n8n MCP runtime-profile validation with 65 functional nodes, 84 valid connections, 52 validated expressions, zero invalid connections, and zero errors.
- Remaining MCP warnings are reviewed false positives for AI subnode reachability, Switch/IF branch outputs, Code-node helper detection, and the intentionally long single canvas.
- Workflow execution, smoke tests, uploads, model inference, database mutations, and end-to-end tests require explicit user approval.
