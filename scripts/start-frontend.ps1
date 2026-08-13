# start-frontend.ps1 — launch the custom Local AI Assistant frontend (frontend/README.md).
# Requires Python and, for live data, the stack running (scripts\start-ai.ps1).
param([int]$Port = 8090)
$ErrorActionPreference = 'SilentlyContinue'

$root = Split-Path $PSScriptRoot -Parent
$server = Join-Path $root 'frontend\server.py'
if(-not (Test-Path $server)){ Write-Error "frontend\server.py not found"; exit 1 }
if(-not (Get-Command python)){ Write-Error "Python required (winget install Python.Python.3.12)"; exit 1 }

# Warn (not block) if the stack is down — the UI shows red status dots either way
try { $null = Invoke-RestMethod 'http://127.0.0.1:11434/api/version' -TimeoutSec 2 }
catch { Write-Warning "Ollama not running — start the stack first: .\scripts\start-ai.ps1" }

$existing = Get-NetTCPConnection -State Listen -LocalPort $Port
if($existing){ Write-Host "Frontend already running on port $Port" }
else {
    Write-Host "Starting frontend server (loopback-only) on port $Port..."
    Start-Process powershell -ArgumentList @(
        '-NoExit','-Command',
        "`$env:FRONTEND_PORT='$Port'; python `"$server`""
    )
    Start-Sleep 2
}
Start-Process "http://127.0.0.1:$Port"
Write-Host "Local AI Assistant UI: http://127.0.0.1:$Port  (API key setup: frontend\README.md)"
