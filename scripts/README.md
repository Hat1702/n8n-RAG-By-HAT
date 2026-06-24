# Operations Scripts

- `bootstrap.ps1`: validate and start the local stack, optionally pull models, then run health checks.
- `health-check.ps1`: verify every container and localhost service endpoint.
- `bootstrap.sh` and `health-check.sh`: Linux equivalents for portability testing.
- `export-workflows.*`: export separate workflow JSON files without credential secrets.
- `import-workflows.*`: import repository workflows as inactive drafts by default.
- `configure-codex-n8n.ps1`: securely forward the n8n API key through the user-level Codex environment.

Backup, restore, and production VPS deployment automation is completed in Phase 7.
