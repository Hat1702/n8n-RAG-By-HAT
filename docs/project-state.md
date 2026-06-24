# Project State

Current focus:
- The local platform is usable end to end.
- Keep the system local, portable, and n8n-first.
- Prepare production rollout and operational hardening only when required.

What is already in place:
- Local Docker stack for n8n, Postgres, Redis, MinIO, Qdrant, Ollama, Docling, and Caddy.
- Working ingestion path in the live n8n instance.
- Single orchestration workflow exists in n8n and is active.
- The exported workflow is now checked in under `n8n/workflows/phase4-single-canvas-local-rag.json`.
- Folder polling was used instead of a local file trigger.
- Ingestion smoke test completed successfully.
- Grounded retrieval returns answers with source metadata.
- Vue knowledge workspace is served at `http://localhost:8080`.
- Query, multipart ingestion, reset, and reprocess are available through the UI.

What is still left:
- Production DNS, TLS, secrets, backups, and restore drills require the target VPS.
- BM25 or reranking remains optional and should be added only when retrieval evidence
  justifies the complexity.

Workflow preference:
- Use one canvas for the main orchestration.
- Reuse existing subflows where practical.
- Keep Ollama swappable behind clear model boundaries.
- Start simple on retrieval; add BM25 or reranking later only if needed.

Note for future chats:
- Read this file first, then inspect live n8n workflows and repo state before making changes.
