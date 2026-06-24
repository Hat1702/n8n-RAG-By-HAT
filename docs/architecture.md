# Architecture

## Boundary

n8n is the application and orchestration layer. It owns document ingestion, Docling
conversion, chunking, Ollama embedding and generation, Qdrant retrieval, knowledge-base
operations, status tracking, and error recovery. Vue must not duplicate this logic.

## Runtime topology

- Caddy is the only public production entry point.
- n8n main receives webhooks and schedules work.
- n8n workers execute jobs from Redis.
- PostgreSQL stores n8n state and RAG metadata in separate databases and roles.
- MinIO stores original documents and generated artifacts.
- Docling converts supported documents into structured JSON and Markdown.
- Ollama provides local chat and embedding models.
- Qdrant stores searchable vectors and source metadata.

Containers communicate through the `backend` Docker network using service names. `localhost`
is used only by host applications such as Codex, the browser, and diagnostic commands.

## Data ownership

Runtime data lives in named volumes and is not transferred by copying this repository. The
repository contains deployable configuration, workflow sources, schemas, tests, and operation
documentation. Backup and restore implementation is scheduled for Phase 7.

## Decision log

- Queue mode is the baseline; local worker concurrency defaults to one.
- Docling uses its CPU image locally so the 4 GB NVIDIA GPU remains available to Ollama.
- MinIO objects remain private.
- Qdrant requires an API key even on the private network.
- Images are version-pinned through `.env`; unpinned `latest` tags are prohibited.
- Ollama cloud features are disabled; generation and embeddings are local.
- Codex reaches n8n only through the host-published loopback endpoint. The local MCP server
  uses its `moderate` webhook security mode so localhost is allowed while private-network and
  cloud metadata targets remain blocked.
- Workflow JSON is imported as inactive by default. Activation requires node validation,
  workflow validation, live connection inspection, and an execution test.
- n8n 2.28 enables its internal JavaScript task runner by default, so the obsolete
  `N8N_RUNNERS_ENABLED` variable is intentionally omitted.
