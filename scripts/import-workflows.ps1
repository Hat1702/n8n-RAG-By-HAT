[CmdletBinding()]
param(
    [string]$Input = 'n8n/workflows',
    [switch]$RespectActiveState
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Test-Path '.env')) { throw 'Missing .env.' }

$source = [IO.Path]::GetFullPath((Join-Path $root $Input))
if (-not (Test-Path $source)) { throw "Workflow input directory does not exist: $source" }

$files = @(Get-ChildItem -LiteralPath $source -Recurse -File -Filter '*.json')
if ($files.Count -eq 0) { throw "No workflow JSON files found under $source" }

$container = docker compose --env-file .env -f docker-compose.yml ps -q n8n
if (-not $container) { throw 'The n8n container is not running.' }

docker compose --env-file .env -f docker-compose.yml exec -T n8n sh -c 'rm -rf /tmp/n8n-workflow-import && mkdir -p /tmp/n8n-workflow-import'

foreach ($file in $files) {
    $target = "/tmp/n8n-workflow-import/$($file.Name)"
    docker cp $file.FullName "${container}:$target"
    if ($LASTEXITCODE -ne 0) { throw "Could not copy $($file.FullName) into n8n." }

    $activeState = if ($RespectActiveState) { 'fromJson' } else { 'false' }
    docker compose --env-file .env -f docker-compose.yml exec -T n8n n8n import:workflow --input=$target --activeState=$activeState
    if ($LASTEXITCODE -ne 0) { throw "Could not import $($file.FullName)." }
}

docker compose --env-file .env -f docker-compose.yml exec -T n8n rm -rf /tmp/n8n-workflow-import
Write-Host "Imported $($files.Count) workflow file(s). Imported workflows are inactive unless -RespectActiveState was specified."
