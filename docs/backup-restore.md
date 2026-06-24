# Backup and Restore

Backup and restore automation is implemented in Phase 7. It must cover:

- PostgreSQL databases
- MinIO objects
- Qdrant storage or snapshots
- n8n state and workflow exports
- The separately secured `N8N_ENCRYPTION_KEY`

Copying this repository does not copy Docker named volumes.
