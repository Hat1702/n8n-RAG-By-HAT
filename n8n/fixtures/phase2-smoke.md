# Phase 2 Runtime Validation

This fixture verifies that Docling preserves structured Markdown for later RAG ingestion.

## Document lifecycle

Documents move through pending, processing, extracting, chunking, embedding, and indexed states.

## Service ownership

| Service | Responsibility |
|---|---|
| MinIO | Original files and extracted artifacts |
| Docling | Structured conversion |
| Qdrant | Vector retrieval |
| Ollama | Local embeddings and generation |
