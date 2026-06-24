# Local Development

## Endpoints

| Service | Host endpoint | Container endpoint |
|---|---|---|
| Caddy | `http://127.0.0.1:8080` | `http://caddy:80` |
| n8n | `http://127.0.0.1:5678` | `http://n8n:5678` |
| MinIO API | `http://127.0.0.1:9000` | `http://minio:9000` |
| MinIO console | `http://127.0.0.1:9001` | `http://minio:9001` |
| Qdrant | `http://127.0.0.1:6333` | `http://qdrant:6333` |
| Ollama | `http://127.0.0.1:11434` | `http://ollama:11434` |
| Docling | `http://127.0.0.1:5001` | `http://docling:5001` |

Containers must not use `localhost` to reach another container.

## Secret generation

Generate unique values before first start. On PowerShell, a suitable base64 value can be
generated without writing it to repository files:

```powershell
$bytes = New-Object byte[] 32
[Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
[Convert]::ToBase64String($bytes)
```

Back up `N8N_ENCRYPTION_KEY` outside the repository. Losing it makes stored n8n credentials
undecryptable.
