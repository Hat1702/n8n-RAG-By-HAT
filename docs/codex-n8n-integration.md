# Codex and n8n Integration

## Local endpoint

Codex connects to the host-published n8n API at `http://127.0.0.1:5678`. Docker workflows
continue using Docker service names for internal services.

The project `.codex/config.toml` forwards `N8N_API_KEY` from Codex's local environment. The
key itself must never be placed in project configuration or committed files.

The MCP server uses `WEBHOOK_SECURITY_MODE=moderate` for this local-only integration. This
mode allows `localhost` and `127.0.0.1`, while continuing to reject private-network targets
and cloud metadata endpoints. Keep the default `strict` mode for remote or production MCP
deployments.

## Create and store the API key

1. Sign in to `http://127.0.0.1:5678` as the n8n owner.
2. Open **Settings > n8n API**.
3. Create an API key labelled `codex-local-development` with the access required for workflow
   inspection, validation, testing, and credential metadata management.
4. Run:

```powershell
./scripts/configure-codex-n8n.ps1
```

Paste the key only into the secure prompt. The helper stores it in
`C:\Users\<user>\.codex\.env`, restricts the file ACL to the current Windows user, and does
not print the key.

Restart Codex after changing the user-level `.env`; desktop applications do not reliably
inherit environment changes without a restart.

## Workflow source control

Export a backup snapshot without credentials:

```powershell
./scripts/export-workflows.ps1
```

Import version-controlled workflow JSON as inactive drafts:

```powershell
./scripts/import-workflows.ps1
```

Use `-RespectActiveState` only during controlled restoration. Normal development imports stay
inactive until node validation, connection inspection, execution testing, and explicit publish.

Never use `n8n export:credentials --decrypted` into this repository. Credentials are created in
n8n or through credential-aware MCP operations and remain encrypted with `N8N_ENCRYPTION_KEY`.
