# backup.ps1 — back up valuable user data (docs/11-backup-updates.md).
# Zips Open WebUI DATA_DIR (config, accounts, chats, uploads, vector DB) + version register.
# Model blobs are NOT backed up (replaceable via 'ollama pull'); the register records them.
# Best run after .\scripts\stop-ai.ps1 for a consistent SQLite copy.
param(
    [string]$Destination = (Join-Path $env:USERPROFILE 'Backups')
)
$ErrorActionPreference = 'Stop'
$dataDir = Join-Path $env:USERPROFILE 'open-webui\data'
if(-not (Test-Path $dataDir)){ throw "DATA_DIR not found at $dataDir — nothing to back up yet." }

New-Item -ItemType Directory -Force -Path $Destination | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmm'
$staging = Join-Path $env:TEMP "localai-backup-$stamp"
New-Item -ItemType Directory -Force -Path $staging | Out-Null

# Version register snapshot (models are recorded, not copied)
$reg = @()
$reg += "Backup taken   : $(Get-Date)"
$reg += "Windows build  : $((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuildNumber)"
$reg += "Ollama         : $((ollama --version) 2>$null)"
$reg += "Models (ollama list):"
$reg += (ollama list) 2>$null
$reg += "Python         : $((python --version) 2>&1)"
$reg | Set-Content (Join-Path $staging 'version-register.txt') -Encoding UTF8

Write-Host "Copying DATA_DIR ($dataDir)..."
Copy-Item $dataDir -Destination (Join-Path $staging 'data') -Recurse

$zip = Join-Path $Destination "localai-backup-$stamp.zip"
Compress-Archive -Path "$staging\*" -DestinationPath $zip -CompressionLevel Optimal
Remove-Item $staging -Recurse -Force

$sz = [math]::Round((Get-Item $zip).Length/1MB,1)
Write-Host @"
Backup complete: $zip ($sz MB)

REMINDERS
 * This archive contains CONFIDENTIAL documents and chat history —
   store only on encrypted / access-controlled media (docs/08).
 * Restore: install versions from version-register.txt, stop the stack,
   replace $dataDir with the archive's 'data' folder, start, verify.
 * Run before every update (docs/11 update policy).
"@
