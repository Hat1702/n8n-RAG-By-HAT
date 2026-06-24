# Workflow Contracts

# Workflow Contracts

Schemas belong in `n8n/schemas/` and must be updated before dependent frontend or workflow
changes.

## Document ingestion

`POST /webhook/v1/documents/ingest` accepts `multipart/form-data`:

- `file`: required file in the webhook binary field named `file`.
- `kbId`: required knowledge-base UUID.
- `force`: optional boolean. When true, reprocesses an existing document with the same SHA-256.

Accepted extensions are PDF, DOCX, PPTX, XLSX, HTML, Markdown, PNG, JPEG, TIFF, BMP, and
WebP. The default maximum upload size is 25 MiB.

A new or requeued document returns HTTP 202. An already indexed duplicate returns HTTP 200
without creating another document or another set of vectors. Validation failures return HTTP
400 with a stable error code.

## Processing status

`GET /webhook/v1/documents/:documentId/status` returns the current lifecycle state, artifact
manifest, chunk count, timestamps, and sanitized failure details.

Lifecycle:

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

- Knowledge-base administration: Phase 5/6 contract work.
- RAG chat: Phase 5.
- Private artifact access: Phase 6.
