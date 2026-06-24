[CmdletBinding()]
param(
    [string]$Output = 'backups/workflows'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Test-Path '.env')) { throw 'Missing .env.' }

$container = docker compose --env-file .env -f docker-compose.yml -f compose.dev.yml ps -q n8n
if (-not $container) { throw 'The n8n container is not running.' }

$destination = [IO.Path]::GetFullPath((Join-Path $root $Output))
New-Item -ItemType Directory -Path $destination -Force | Out-Null

docker compose --env-file .env -f docker-compose.yml -f compose.dev.yml exec -T n8n sh -c 'rm -rf /tmp/n8n-workflow-export && mkdir -p /tmp/n8n-workflow-export'
docker compose --env-file .env -f docker-compose.yml -f compose.dev.yml exec -T n8n n8n export:workflow --backup --output=/tmp/n8n-workflow-export
if ($LASTEXITCODE -ne 0) { throw 'n8n workflow export failed.' }

docker cp "${container}:/tmp/n8n-workflow-export/." $destination
if ($LASTEXITCODE -ne 0) { throw 'Could not copy workflow exports from the n8n container.' }

docker compose --env-file .env -f docker-compose.yml -f compose.dev.yml exec -T n8n rm -rf /tmp/n8n-workflow-export
Write-Host "Workflow export completed: $destination"

