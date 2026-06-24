# Workflow Contracts

Schemas belong in `n8n/schemas/` and must be updated before dependent frontend or workflow
changes.

## Phase 4 RAG API

`POST /webhook/rag` accepts `application/json` or `multipart/form-data`.

Supported actions:

- `ingest`: multipart file field `file` preferred, legacy `data` also accepted; optional `kbId` and `force`.
- `query`: include `query` or `message`; optional `kbId` and `topK` from 1 to 12.
- `reset`: include `confirm=RESET` and either `documentId` or `kbId`.
- `reprocess`: include `confirm=RESET` and `documentId`.

The default knowledge base is `00000000-0000-4000-8000-000000000001`. Uploads are limited
to 25 MiB.

The workflow returns structured JSON for:

- ingestion success, duplicate detection, and validation failures
- grounded retrieval answers with source metadata
- reset and reprocess results

## Lifecycle

```text
pending -> processing -> extracting -> chunking -> embedding -> indexed
                                                           \-> failed
```

## Stored artifacts

All objects remain private in MinIO:

```text
documents/{kbId}/{documentId}/
|-- source/original
|-- extracted/document.json
|-- extracted/document.md
|-- extracted/manifest.json
|-- extracted/images/
`-- chunks/chunks.json
```

The manifest maps Docling artifact names to controlled object keys. Markdown image references
are normalized to paths relative to `extracted/document.md`.

## Deferred boundaries

- BM25 and a separate reranker remain deferred.
- Knowledge-base administration is still handled outside this workflow.
- Private artifact access remains out of scope.
