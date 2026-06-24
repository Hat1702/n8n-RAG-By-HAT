[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Test-Path '.env')) { throw 'Missing .env.' }

$environment = @{}
Get-Content '.env' | Where-Object { $_ -match '^[A-Z0-9_]+=' } | ForEach-Object {
    $key, $value = $_.Split('=', 2)
    $environment[$key] = $value
}

$compose = @('--env-file', '.env', '-f', 'docker-compose.yml')
$env:COMPOSE_PROFILES = if ($env:COMPOSE_PROFILES) { $env:COMPOSE_PROFILES } else { 'cpu,local' }
$ollamaService = if (($env:COMPOSE_PROFILES -split ',') -contains 'gpu') { 'ollama-gpu' } else { 'ollama-cpu' }
$gatewayService = if (($env:COMPOSE_PROFILES -split ',') -contains 'production') { 'caddy-production' } else { 'caddy' }
$services = @('postgres', 'redis', 'minio', 'qdrant', $ollamaService, 'docling', 'n8n', 'n8n-worker', 'frontend', $gatewayService)

foreach ($service in $services) {
    $containerId = docker compose @compose ps -q $service
    if (-not $containerId) { throw "$service is not running." }
    $status = docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' $containerId
    if ($status -ne 'healthy') { throw "$service health status is $status." }
    Write-Host "[healthy] $service"
}

$null = Invoke-RestMethod -Uri "http://127.0.0.1:$($environment.CADDY_HTTP_PORT)/health" -TimeoutSec 10
$null = Invoke-RestMethod -Uri "http://127.0.0.1:$($environment.N8N_PORT)/healthz" -TimeoutSec 10
$null = Invoke-RestMethod -Uri "http://127.0.0.1:$($environment.MINIO_API_PORT)/minio/health/live" -TimeoutSec 10
$null = Invoke-RestMethod -Uri "http://127.0.0.1:$($environment.DOCLING_PORT)/health" -TimeoutSec 10
$null = Invoke-RestMethod -Uri "http://127.0.0.1:$($environment.OLLAMA_PORT)/api/tags" -TimeoutSec 10
$null = Invoke-RestMethod -Uri "http://127.0.0.1:$($environment.QDRANT_HTTP_PORT)/collections" -Headers @{ 'api-key' = $environment.QDRANT_API_KEY } -TimeoutSec 10

Write-Host 'All Phase 2 service health checks passed.'
