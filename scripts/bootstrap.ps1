[CmdletBinding()]
param(
    [switch]$CpuOnly,
    [switch]$SkipModelPull
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Test-Path '.env')) {
    throw 'Missing .env. Copy .env.example, replace every placeholder, and keep the file private.'
}

if (Select-String -LiteralPath '.env' -Pattern 'REPLACE_WITH_' -Quiet) {
    throw 'One or more secret placeholders remain in .env.'
}

$compose = @('--env-file', '.env', '-f', 'docker-compose.yml', '-f', 'compose.dev.yml')
if (-not $CpuOnly) {
    $compose += @('-f', 'compose.gpu.yml')
}

docker compose @compose config --quiet
if ($LASTEXITCODE -ne 0) { throw 'Compose validation failed.' }

docker compose @compose up -d
if ($LASTEXITCODE -ne 0) { throw 'Service startup failed.' }

if (-not $SkipModelPull) {
    docker compose @compose --profile bootstrap run --rm ollama-init
    if ($LASTEXITCODE -ne 0) { throw 'Ollama model bootstrap failed.' }
}

& "$PSScriptRoot/health-check.ps1"

