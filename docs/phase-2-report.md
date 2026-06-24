# Phase 2 Gate Report

## Completed

- Generated a local, Git-ignored `.env` with fresh cryptographic secrets.
- Pulled all pinned container images.
- Started PostgreSQL, Redis, MinIO, Qdrant, Ollama, Docling, n8n main, one n8n worker, and Caddy.
- Created separate `n8n` and `rag` PostgreSQL databases and login roles.
- Created the private `rag-documents` MinIO bucket.
- Pulled `qwen3:4b` and `nomic-embed-text` into the Ollama volume.
- Disabled Ollama cloud features after model bootstrap.
- Removed the obsolete `N8N_RUNNERS_ENABLED` setting reported by n8n 2.28.

## Validation evidence

- Every long-running container reached Docker health status `healthy`.
- Ollama detected the RTX 3050 through CUDA and generated locally.
- `nomic-embed-text` returned 768-dimensional embeddings.
- Docling converted `n8n/fixtures/phase2-smoke.md` into Markdown and Docling JSON, preserving headings and a table.
- Qdrant passed an authenticated 768-dimensional collection, upsert, query, payload, and cleanup round-trip.
- MinIO denied anonymous access and passed authenticated put, get, and delete operations.
- Caddy and n8n localhost health endpoints returned success.
- The validated `Phase 2 Worker Smoke Test` webhook returned the expected JSON.
- The queue worker logged execution 1 starting and finishing.
- PostgreSQL recorded execution 1 as `success`, mode `webhook`, workflow `phase2-worker-smoke`.
- The smoke workflow was unpublished after validation.

## Accepted limitations

- The internal n8n image has no Python task runner. The JavaScript runner is registered and ready;
  Python Code nodes are not part of the planned native-node-first implementation.
- `qwen3:4b` uses reasoning tokens by default, so exact short-response assertions are unsuitable;
  successful local generation and embedding endpoints were verified instead.
- Runtime named volumes remain local and are not part of Git. Backup and restore automation is Phase 7.

## Phase gate

Phase 2 passed. Development must pause for user approval before Phase 3 begins.
