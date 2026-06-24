# Phase 4 Report

## Status

Phase 4 is implemented as the live n8n workflow `Phase 4: Single-Canvas Local RAG`.

The workflow is active in the live n8n instance. Its production webhook path is `/webhook/rag`.

## Implemented

- One canvas contains webhook routing, local folder intake, ingestion, retrieval, reset, and reprocessing.
- Uploaded and watched files use SHA-256 deduplication before MinIO storage.
- Docling extraction, semantic chunking, Ollama embeddings, and Qdrant indexing are inlined from the Phase 3 ingestion workflows.
- Query retrieval embeds with `nomic-embed-text`, filters Qdrant by knowledge base, assembles source-labelled context, and calls `qwen3:4b` for a grounded answer.
- Responses include source identifiers and metadata.
- Reset removes matching Qdrant vectors and returns PostgreSQL lifecycle state to `pending` while preserving MinIO artifacts.
- Reprocess performs reset followed by ingestion from the stored source.
- The host directory `data/inbox` is mounted in both n8n containers as `/files/inbox` and polled every five minutes.
- The repo now includes the exported workflow at `n8n/workflows/phase4-single-canvas-local-rag.json`.

## API Contract

Send JSON or multipart form data to `POST /webhook/rag`.

- `action=ingest`: include a file in binary field `data`; optional `kbId` and `force`.
- `action=query`: include `query`; optional `kbId` and `topK` from 1 to 12.
- `action=reset`: include `confirm=RESET` and either `documentId` or `kbId`.
- `action=reprocess`: include `confirm=RESET` and `documentId`.

The default knowledge base is `00000000-0000-4000-8000-000000000001`. Uploads are limited to 25 MiB.

## Deferred

BM25 and a separate reranker remain deferred. The current stack has no lexical index or reranker service; vector retrieval is deterministic and operational without adding infrastructure.

## Validation

The workflow passed n8n runtime validation with zero errors. Remaining warnings are documented false positives for Code-node helpers and conditional outputs, plus the deliberate single-canvas size warning.
