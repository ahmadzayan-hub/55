# 04-install-openwebui.ps1 — Phase 3: native Open WebUI install (Gate 4).
# Native uv/pip deployment (no Docker overhead), bound to 127.0.0.1 only.

$ErrorActionPreference = 'Stop'

# Python check (3.11/3.12 supported)
$pyv = (python --version) 2>&1
if($pyv -notmatch 'Python 3\.(11|12)'){
    Write-Warning "Found: $pyv — Open WebUI needs Python 3.11 or 3.12."
    Write-Host    "Install with:  winget install Python.Python.3.12   then re-run this script."
    exit 1
}
Write-Host "Python OK: $pyv"

# uv (fast, isolated runner — keeps WebUI out of the global site-packages)
if(-not (Get-Command uv -ErrorAction SilentlyContinue)){
    Write-Host "Installing uv..."
    python -m pip install --user uv
    $env:Path += ";$env:APPDATA\Python\Scripts;$((python -m site --user-base) 2>$null)\Scripts"
}

# Data directory (documents, vector DB, chat history live here — see docs/08 + backup.ps1)
$dataDir = Join-Path $env:USERPROFILE 'open-webui\data'
New-Item -ItemType Directory -Force -Path $dataDir | Out-Null
Write-Host "DATA_DIR: $dataDir"

# Ollama must be reachable first
try { $null = Invoke-RestMethod 'http://127.0.0.1:11434/api/version' -TimeoutSec 3 }
catch { Write-Warning "Ollama is not responding on 127.0.0.1:11434 — start it first (Gate 2)."; exit 1 }

Write-Host @'

Starting Open WebUI (first run downloads packages — allow several minutes).
LOCALHOST-ONLY binding is enforced with --host 127.0.0.1.

'@
$env:DATA_DIR = $dataDir
$env:OLLAMA_BASE_URL = 'http://127.0.0.1:11434'
Start-Process powershell -ArgumentList @(
    '-NoExit','-Command',
    "`$env:DATA_DIR='$dataDir'; `$env:OLLAMA_BASE_URL='http://127.0.0.1:11434'; uvx --python 3.12 open-webui@latest serve --host 127.0.0.1 --port 8080"
)

Write-Host @'
Open WebUI is starting in its own window (leave it open while using the UI).

GATE 4 CHECKLIST — verify each item (docs/03-openwebui-deployment.md):
 1. http://localhost:8080 loads (wait for "Uvicorn running" in the WebUI window)
 2. Create the ADMIN account immediately, strong password
 3. Admin Panel > Settings: disable new sign-ups
 4. Connections: Ollama = http://127.0.0.1:11434, models visible
 5. New chat streams a reply; history persists after restart
 6. Arabic prompt renders RTL correctly
 7. Run .\scripts\05-privacy-check.ps1 -> 8080 & 11434 on 127.0.0.1 only

Then set embeddings (Phase 4):  ollama pull bge-m3
 Admin Panel > Settings > Documents: Engine=Ollama, Model=bge-m3 (BEFORE ingesting).
'@
