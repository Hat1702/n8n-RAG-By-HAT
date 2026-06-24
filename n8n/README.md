# n8n Assets

`workflows/local-rag-agent.json` is the only canonical workflow export. It contains the complete RAG orchestration on one canvas and preserves the `POST /webhook/rag` contract.

The workflow uses:

- Docling HTTP conversion for structured JSON, Markdown, images, OCR, tables, formulas, code, classifications, and provenance.
- Native Ollama Embeddings nodes for indexing and retrieval.
- Native Qdrant Vector Store nodes with nested metadata filters.
- A native Ollama Chat Model connected to an AI Agent.
- A Vector Store Question Answer Tool for agent-controlled retrieval.
- PostgreSQL for lifecycle and failure state.
- MinIO for private sources and generated artifacts.

`schemas/` contains the public request and response contracts. Credentials and execution data must never be committed.

Repository imports are inactive by default. Workflow executions, smoke tests, uploads, model calls, and end-to-end tests require explicit user approval.
