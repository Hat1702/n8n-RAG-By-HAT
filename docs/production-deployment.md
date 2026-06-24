# Production Deployment

The production target is a Linux GPU VPS with Docker Engine and the Compose plugin.

Before launch:

1. Point `APP_DOMAIN` and `N8N_DOMAIN` DNS records at the VPS.
2. Confirm ports 80 and 443 are reachable.
3. Generate fresh secrets on the VPS and set `.env` permissions to `600`.
4. Confirm NVIDIA Container Toolkit when `compose.gpu.yml` is used.
5. Run the production Compose validation command from the repository root.

Only Caddy publishes production ports. n8n, PostgreSQL, Redis, MinIO, Qdrant, Ollama, and
Docling remain private Docker services.
