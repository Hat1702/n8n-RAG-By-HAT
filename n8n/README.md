# n8n Application Assets

This folder mirrors the current Phase 4 operating model:

- `workflows/` contains the active single-canvas RAG workflow export.
- `schemas/` contains versioned request and response contracts.
- `fixtures/` contains safe validation inputs.

The current production workflow is `workflows/phase4-single-canvas-local-rag.json`.
It implements one `/webhook/rag` entrypoint for ingest, query, reset, and reprocess.

Credentials and execution data must never be committed.

Use `scripts/export-workflows.*` for backup snapshots and `scripts/import-workflows.*` for
version-controlled imports. Imports are inactive by default and must pass validation before
publishing.

Phase 4 uses the stable `/webhook/rag` contract, PostgreSQL lifecycle tables from
`infra/postgres/migrations/`, private MinIO object keys, Docling ZIP artifacts, batched
Ollama embeddings, and explicit Qdrant payloads.
