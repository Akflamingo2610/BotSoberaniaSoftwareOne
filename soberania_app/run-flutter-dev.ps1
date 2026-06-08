$ErrorActionPreference = "Continue"

$appRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$uriFile = Join-Path $appRoot ".flutter_vm_uri"
$logFile = Join-Path $appRoot ".flutter_run.log"

Set-Location $appRoot

Write-Host "Iniciando Flutter Web (Chrome)..."
Write-Host "A URI de debug sera salva em .flutter_vm_uri para hot restart automatico."

flutter run -d chrome --no-dds 2>&1 | ForEach-Object {
  $line = $_
  Write-Host $line
  Add-Content -Path $logFile -Value $line
  if ($line -match '(http://127\.0\.0\.1:\d+/[A-Za-z0-9_\-]+=)') {
    Set-Content -Path $uriFile -Value $Matches[1] -NoNewline
  }
}
