# start-ai.ps1 — daily startup procedure (docs/09-operations.md).
# 1) RAM check  2) start Ollama  3) start Open WebUI  4) model ping  5) open browser
param(
    [string]$Model = 'qwen3:4b',
    [switch]$NoWebUI
)
$ErrorActionPreference = 'SilentlyContinue'

# 1. RAM check
$freeGB = [math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)
Write-Host "Available RAM: $freeGB GB"
if($freeGB -lt 8){
    Write-Warning "Below the 8 GB target. Run .\scripts\01-memory-check.ps1 and close heavy apps (or continue in LIGHT mode with a 4B model / 4K context)."
}

# 2. Ollama
$env:OLLAMA_KEEP_ALIVE = '10m'
try { $null = Invoke-RestMethod 'http://127.0.0.1:11434/api/version' -TimeoutSec 2; Write-Host "Ollama: already running" }
catch {
    Write-Host "Ollama: starting..."
    Start-Process -WindowStyle Hidden ollama -ArgumentList 'serve'
    Start-Sleep 4
    try { $null = Invoke-RestMethod 'http://127.0.0.1:11434/api/version' -TimeoutSec 5; Write-Host "Ollama: started" }
    catch { Write-Error "Ollama failed to start — see docs/10-troubleshooting.md"; exit 1 }
}

# 3. Open WebUI
if(-not $NoWebUI){
    $webui = $false
    try { $null = Invoke-WebRequest 'http://127.0.0.1:8080' -TimeoutSec 2 -UseBasicParsing; $webui = $true } catch {}
    if($webui){ Write-Host "Open WebUI: already running" }
    else {
        Write-Host "Open WebUI: starting (window opens; first tokens may take ~30-60s)..."
        $dataDir = Join-Path $env:USERPROFILE 'open-webui\data'
        Start-Process powershell -ArgumentList @(
            '-NoExit','-Command',
            "`$env:DATA_DIR='$dataDir'; `$env:OLLAMA_BASE_URL='http://127.0.0.1:11434'; uvx --python 3.12 open-webui@latest serve --host 127.0.0.1 --port 8080"
        )
    }
}

# 4. Confirm selected model responds (loads it into RAM)
Write-Host "Pinging model '$Model' (first load takes 10-60s)..."
$body = @{ model=$Model; prompt='Reply with the single word: ready'; stream=$false; options=@{num_predict=5} } | ConvertTo-Json
try {
    $r = Invoke-RestMethod 'http://127.0.0.1:11434/api/generate' -Method Post -Body $body -ContentType 'application/json' -TimeoutSec 180
    Write-Host "Model '$Model': loaded and responding."
} catch { Write-Warning "Model ping failed — is '$Model' pulled? (ollama list)" }

# 5. Browser
if(-not $NoWebUI){ Start-Process 'http://localhost:8080' }
Write-Host "`nSession ready. Pick your assistant / knowledge library in the UI. Run .\scripts\status.ps1 anytime."
