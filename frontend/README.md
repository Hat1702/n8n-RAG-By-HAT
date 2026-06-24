# Local RAG Frontend

Vue is the presentation layer for the n8n-owned RAG workflow. It calls the same-origin
`/webhook/rag` endpoint for upload, query, reset, and reprocess operations.

```powershell
npm install
npm run dev
```

For the complete local platform, run `./scripts/bootstrap.ps1`; Caddy serves the built app
at `http://localhost:8080`.
