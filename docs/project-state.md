# Project State

Current focus:
- Finish the Phase 4 single-canvas local RAG workflow.
- Keep the system local, portable, and n8n-first.
- Prefer batching workflow edits first, then validate only when needed.
- Defer non-essential improvements until the user-facing system works end to end.

What is already in place:
- Local Docker stack for n8n, Postgres, Redis, MinIO, Qdrant, Ollama, Docling, and Caddy.
- Working ingestion path in the live n8n instance.
- Single orchestration workflow exists in n8n and is active.
- The exported workflow is now checked in under `n8n/workflows/phase4-single-canvas-local-rag.json`.
- Folder polling was used instead of a local file trigger.
- Ingestion smoke test completed successfully.

What is still left:
- Fix and verify the grounded retrieval/chat path.
- Confirm the reset/admin branch works end to end.
- Clean up temporary smoke-test artifacts if needed.
- Run a final end-to-end validation pass.

Workflow preference:
- Use one canvas for the main orchestration.
- Reuse existing subflows where practical.
- Keep Ollama swappable behind clear model boundaries.
- Start simple on retrieval; add BM25 or reranking later only if needed.

Note for future chats:
- Read this file first, then inspect live n8n workflows and repo state before making changes.
