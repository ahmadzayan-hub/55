# stop-ai.ps1 — clean shutdown (docs/09-operations.md).
# Unloads models, stops Open WebUI, optionally stops Ollama and WSL/Docker.
param(
    [switch]$KeepOllama   # leave the Ollama server itself running (models still unloaded)
)
$ErrorActionPreference = 'SilentlyContinue'

# 1. Unload any resident models (releases multi-GB of RAM immediately)
$ps = (ollama ps) 2>$null
if($ps){
    ($ps | Select-Object -Skip 1) | ForEach-Object {
        $name = ($_ -split '\s+')[0]
        if($name){ Write-Host "Unloading model: $name"; ollama stop $name }
    }
}

# 2. Stop Open WebUI (uvicorn/python process serving port 8080)
$conn = Get-NetTCPConnection -State Listen -LocalPort 8080 | Select-Object -First 1
if($conn){
    $p = Get-Process -Id $conn.OwningProcess
    Write-Host "Stopping Open WebUI (PID $($p.Id), $($p.ProcessName))"
    Stop-Process -Id $p.Id -Force
} else { Write-Host "Open WebUI: not running" }

# 3. Ollama server
if(-not $KeepOllama){
    Get-Process ollama | ForEach-Object { Write-Host "Stopping Ollama (PID $($_.Id))"; Stop-Process -Id $_.Id -Force }
} else { Write-Host "Ollama server left running (models unloaded)" }

# 4. Docker / WSL hygiene (only if present)
if(Get-Process 'Docker Desktop'){ Write-Host "Note: Docker Desktop is running — quit it from the tray if not needed." }
if((wsl.exe -l -q) 2>$null){ Write-Host "Shutting down WSL..."; wsl.exe --shutdown }

$freeGB = [math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)
Write-Host "`nShutdown complete. Available RAM now: $freeGB GB"
