[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Test-Path '.env')) { throw 'Missing .env.' }

$values = @{}
Get-Content '.env' | ForEach-Object {
    $line = $_.Trim()
    if (-not $line -or $line.StartsWith('#')) { return }
    $separator = $line.IndexOf('=')
    if ($separator -lt 1) { return }
    $values[$line.Substring(0, $separator)] = $line.Substring($separator + 1)
}

$migration = Get-Content -Raw 'infra/postgres/migrations/001-rag-ingestion.sql'
$migration | docker compose --env-file .env -f docker-compose.yml exec -T postgres sh -c 'PGPASSWORD="$RAG_DB_PASSWORD" psql --set=ON_ERROR_STOP=1 --username "$RAG_DB_USER" --dbname "$RAG_DB_NAME"'
if ($LASTEXITCODE -ne 0) { throw 'PostgreSQL RAG migration failed.' }

$collection = if ($values.QDRANT_COLLECTION) { $values.QDRANT_COLLECTION } else { 'rag_chunks' }
$headers = @{ 'api-key' = $values.QDRANT_API_KEY }
$collectionUri = "http://127.0.0.1:$($values.QDRANT_HTTP_PORT)/collections/$collection"

try {
    Invoke-RestMethod -Method Get -Uri $collectionUri -Headers $headers | Out-Null
} catch {
    $body = @{ vectors = @{ size = 768; distance = 'Cosine' } } | ConvertTo-Json -Depth 4
    Invoke-RestMethod -Method Put -Uri $collectionUri -Headers $headers -ContentType 'application/json' -Body $body | Out-Null
}

foreach ($field in @('metadata.kb_id', 'metadata.document_id', 'metadata.source_sha256', 'metadata.content_type', 'metadata.language')) {
    $indexBody = @{ field_name = $field; field_schema = 'keyword' } | ConvertTo-Json
    try {
        Invoke-RestMethod -Method Put -Uri "$collectionUri/index?wait=true" -Headers $headers -ContentType 'application/json' -Body $indexBody | Out-Null
    } catch {
        if ($_.Exception.Response.StatusCode.value__ -notin @(400, 409)) { throw }
    }
}

$textIndexBody = @{
    field_name = 'text'
    field_schema = @{ type = 'text'; tokenizer = 'word'; lowercase = $true }
} | ConvertTo-Json -Depth 4
try {
    Invoke-RestMethod -Method Put -Uri "$collectionUri/index?wait=true" -Headers $headers -ContentType 'application/json' -Body $textIndexBody | Out-Null
} catch {
    if ($_.Exception.Response.StatusCode.value__ -notin @(400, 409)) { throw }
}

Write-Host "RAG schema and Qdrant collection '$collection' are ready."
