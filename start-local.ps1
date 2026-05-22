$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$pythonApiPath = Join-Path $repoRoot "python_api"
$flutterAppPath = Join-Path $repoRoot "soberania_app"

Write-Host "Iniciando backend (FastAPI em :8000)..."
Start-Process powershell -ArgumentList @(
  "-NoExit",
  "-Command",
  "cd `"$pythonApiPath`"; python -m uvicorn app.main:app --host 0.0.0.0 --port 8000"
)

Start-Sleep -Seconds 2

Write-Host "Iniciando frontend (Flutter Web)..."
Start-Process powershell -ArgumentList @(
  "-NoExit",
  "-Command",
  "cd `"$flutterAppPath`"; flutter run -d chrome"
)

Write-Host "Pronto. Dois terminais foram abertos (API + Flutter)."
