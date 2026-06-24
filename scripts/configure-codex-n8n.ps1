[CmdletBinding()]
param(
    [Security.SecureString]$ApiKey
)

$ErrorActionPreference = 'Stop'

if (-not $ApiKey) {
    $ApiKey = Read-Host 'Paste the n8n API key' -AsSecureString
}

$credential = [Management.Automation.PSCredential]::new('n8n', $ApiKey)
$plainKey = $credential.GetNetworkCredential().Password
if ([string]::IsNullOrWhiteSpace($plainKey)) { throw 'The API key is empty.' }

$codexDirectory = Join-Path $env:USERPROFILE '.codex'
$codexEnvironment = Join-Path $codexDirectory '.env'
New-Item -ItemType Directory -Path $codexDirectory -Force | Out-Null

$lines = if (Test-Path $codexEnvironment) { @(Get-Content $codexEnvironment) } else { @() }
$replacement = "N8N_API_KEY=$plainKey"
$index = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^N8N_API_KEY=') { $index = $i; break }
}
if ($index -ge 0) { $lines[$index] = $replacement } else { $lines += $replacement }

[IO.File]::WriteAllLines($codexEnvironment, $lines, [Text.UTF8Encoding]::new($false))
icacls $codexEnvironment /inheritance:r /grant:r "${env:USERNAME}:(R,W)" | Out-Null
$plainKey = $null

Write-Host "Stored N8N_API_KEY in $codexEnvironment. Restart Codex before testing MCP operations."
