# 02-install-ollama.ps1 — Phase 2: install + verify Ollama (Gate 2).
# Uses winget (official OllamaSetup). Verifies service, API, and documents model storage.

$ErrorActionPreference = 'Stop'

$existing = Get-Command ollama -ErrorAction SilentlyContinue
if($existing){
    Write-Host "Ollama already installed: $((ollama --version) 2>$null)"
} else {
    Write-Host "Installing Ollama via winget (official package)..."
    winget install --id Ollama.Ollama -e --accept-source-agreements --accept-package-agreements
    # refresh PATH for this session
    $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
    if(-not (Get-Command ollama -ErrorAction SilentlyContinue)){
        throw "ollama not on PATH after install — open a new terminal or install manually from https://ollama.com/download/windows"
    }
}

Write-Host "`n--- Verification ---"
Write-Host "Version : $((ollama --version) 2>&1)"

# Ensure the server is up (installer normally starts the tray app; start on demand otherwise)
try {
    $v = Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/version' -TimeoutSec 3
    Write-Host "API     : responding on 127.0.0.1:11434 (server v$($v.version))"
} catch {
    Write-Host "API not responding — starting 'ollama serve' in background..."
    Start-Process -WindowStyle Hidden ollama -ArgumentList 'serve'
    Start-Sleep -Seconds 4
    $v = Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/version' -TimeoutSec 5
    Write-Host "API     : responding on 127.0.0.1:11434 (server v$($v.version))"
}

Write-Host "Models  :"
ollama list

# Binding check — must be localhost only
$lan = Get-NetTCPConnection -State Listen -LocalPort 11434 -ErrorAction SilentlyContinue |
       Where-Object { $_.LocalAddress -notin '127.0.0.1','::1' }
if($lan){ Write-Warning "Ollama is listening beyond localhost ($($lan.LocalAddress -join ',')). Remove any OLLAMA_HOST=0.0.0.0 setting." }
else    { Write-Host "Binding : 127.0.0.1 only — PASS" }

$modDir = if($env:OLLAMA_MODELS){$env:OLLAMA_MODELS}else{Join-Path $env:USERPROFILE '.ollama\models'}
$sz = if(Test-Path $modDir){ [math]::Round((Get-ChildItem $modDir -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum/1GB,1) } else { 0 }
Write-Host "Storage : $modDir ($sz GB used)"

Write-Host @'

GATE 2 PASSES when the API responds and binding is localhost-only.
Next (Gate 3) — ONE model first, then benchmark:
    ollama pull qwen3:4b
    .\scripts\03-benchmark.ps1 -Model qwen3:4b
Do not pull gemma3:4b until the qwen3 baseline is recorded.
'@
