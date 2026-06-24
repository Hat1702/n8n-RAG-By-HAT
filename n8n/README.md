# n8n Application Assets

- `workflows/ingestion`: document intake and indexing
- `workflows/rag-chat`: retrieval and response generation
- `workflows/kb-admin`: knowledge-base administration
- `workflows/shared`: reusable subworkflows
- `workflows/system`: error handling and maintenance
- `schemas`: versioned webhook and metadata contracts
- `fixtures`: safe validation inputs

Credentials and execution data must never be committed.

Use `scripts/export-workflows.*` for backup snapshots and `scripts/import-workflows.*` for
version-controlled imports. Imports are inactive by default and must pass validation before
publishing.

Phase 4 ingestion workflows use the stable HTTP contracts in `schemas/`, PostgreSQL lifecycle
tables from `infra/postgres/migrations/`, private MinIO object keys, Docling ZIP artifacts,
batched Ollama embeddings, and explicit Qdrant payloads.
