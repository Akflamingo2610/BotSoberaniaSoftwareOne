$ErrorActionPreference = "SilentlyContinue"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$uriFile = Join-Path $repoRoot "soberania_app\.flutter_vm_uri"
$logFile = Join-Path $repoRoot "soberania_app\.flutter_run.log"

function Try-HotRestart([string]$BaseUri) {
  if ([string]::IsNullOrWhiteSpace($BaseUri)) { return $false }
  $uri = $BaseUri.Trim().TrimEnd('/')
  try {
    Invoke-RestMethod -Uri "$uri/hotRestart" -Method Get -TimeoutSec 6 | Out-Null
    Write-Host "Hot restart OK ($uri)"
    return $true
  } catch {
    return $false
  }
}

function Find-UriInText([string]$Text) {
  if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
  $match = [regex]::Match(
    $Text,
    'http://127\.0\.0\.1:\d+/[A-Za-z0-9_\-]+='
  )
  if ($match.Success) { return $match.Value }
  return $null
}

if (Test-Path $uriFile) {
  $saved = Get-Content $uriFile -Raw
  if (Try-HotRestart $saved) { exit 0 }
}

if (Test-Path $logFile) {
  $tail = Get-Content $logFile -Tail 80 -ErrorAction SilentlyContinue | Out-String
  $fromLog = Find-UriInText $tail
  if ($fromLog -and (Try-HotRestart $fromLog)) {
    Set-Content -Path $uriFile -Value $fromLog -NoNewline
    exit 0
  }
}

Write-Host "Hot restart indisponivel (Flutter nao esta rodando ou URI desatualizada)."
exit 0
