# 00-audit.ps1 — Phase 1 system audit (Gate 1). READ-ONLY: installs nothing, changes nothing.
# Produces a readiness report on screen and in reports\readiness-<date>.txt
# Run:  powershell -ExecutionPolicy Bypass -File .\scripts\00-audit.ps1

$ErrorActionPreference = 'SilentlyContinue'
$lines = New-Object System.Collections.Generic.List[string]
function Out-Line($t){ $lines.Add($t); Write-Host $t }
function Classify($name, $value, $status, $note){
    $tag = switch ($status) { 'PASS' {'[PASS]           '} 'WARN' {'[WARNING]        '} 'ACTION' {'[ACTION REQUIRED]'} default {'[INFO]           '} }
    Out-Line ("{0} {1}: {2}{3}" -f $tag, $name, $value, $(if($note){" — $note"}))
}

Out-Line "=============================================================="
Out-Line " SYSTEM READINESS AUDIT — $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
Out-Line "=============================================================="

# 1. Windows version/build
$os = Get-CimInstance Win32_OperatingSystem
$build = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion')
Classify 'Windows' ("{0} build {1}.{2}" -f $os.Caption, $build.CurrentBuildNumber, $build.UBR) $(if([int]$build.CurrentBuildNumber -ge 22000){'PASS'}else{'ACTION'}) $(if([int]$build.CurrentBuildNumber -lt 22000){'Windows 11 expected'})

# 2. CPU
$cpu = Get-CimInstance Win32_Processor
Classify 'CPU' ("{0} — {1} cores / {2} threads" -f $cpu.Name.Trim(), $cpu.NumberOfCores, $cpu.NumberOfLogicalProcessors) 'PASS'

# 3-4. RAM total + available
$totalGB = [math]::Round($os.TotalVisibleMemorySize/1MB,1)
$freeGB  = [math]::Round($os.FreePhysicalMemory/1MB,1)
Classify 'RAM total' "$totalGB GB" $(if($totalGB -ge 15){'WARN'}else{'ACTION'}) '16 GB machine: 4B default / 8B ceiling policy applies'
Classify 'RAM available now' "$freeGB GB" $(if($freeGB -ge 8){'PASS'}elseif($freeGB -ge 5){'WARN'}else{'ACTION'}) 'target >= 8 GB free before loading models'

# 5. Committed memory
$cm = Get-Counter '\Memory\Committed Bytes','\Memory\Commit Limit'
$commitGB = [math]::Round($cm.CounterSamples[0].CookedValue/1GB,1)
$limitGB  = [math]::Round($cm.CounterSamples[1].CookedValue/1GB,1)
$ratio = if($limitGB){[math]::Round($commitGB/$limitGB*100,0)}else{0}
Classify 'Committed memory' "$commitGB / $limitGB GB ($ratio%)" $(if($ratio -lt 70){'PASS'}elseif($ratio -lt 85){'WARN'}else{'ACTION'})

# 6. Page file
Get-CimInstance Win32_PageFileUsage | ForEach-Object {
    Classify 'Page file' ("{0} — allocated {1} MB, in use {2} MB" -f $_.Name, $_.AllocatedBaseSize, $_.CurrentUsage) $(if($_.CurrentUsage -lt 2048){'PASS'}else{'WARN'}) 'high page file use = memory pressure'
}
if(-not (Get-CimInstance Win32_PageFileUsage)){ Classify 'Page file' 'none configured' 'WARN' 'system-managed page file recommended on 16 GB' }

# 7. Intel Arc GPU driver
Get-CimInstance Win32_VideoController | ForEach-Object {
    Classify 'GPU' ("{0} — driver {1} ({2})" -f $_.Name, $_.DriverVersion, $_.DriverDate) 'INFO' 'iGPU shares system RAM; treat stack as CPU-only until proven otherwise'
}

# 8. NPU
$npu = Get-PnpDevice | Where-Object { $_.FriendlyName -match 'AI Boost|NPU' }
if($npu){ Classify 'NPU' ("{0} — {1}" -f $npu[0].FriendlyName, $npu[0].Status) 'INFO' 'not used by Ollama; no acceleration assumed' }
else    { Classify 'NPU' 'not detected' 'INFO' }

# 9. SSD free space
Get-Volume -DriveLetter C | ForEach-Object {
    $free=[math]::Round($_.SizeRemaining/1GB,0); $size=[math]::Round($_.Size/1GB,0)
    Classify 'SSD C:' "$free GB free of $size GB" $(if($free -ge 40){'PASS'}elseif($free -ge 20){'WARN'}else{'ACTION'}) 'need >= 40 GB free (models ~12 GB + data + headroom)'
}

# 10. Docker
$docker = Get-Command docker -ErrorAction SilentlyContinue
if($docker){
    $dv = (docker --version) 2>$null
    Classify 'Docker' "$dv" 'WARN' 'native WebUI deployment chosen — keep Docker stopped when stack runs'
    $running = (docker ps --format '{{.Names}}') 2>$null
    if($running){ Classify 'Docker containers running' ($running -join ', ') 'WARN' 'consumes RAM now' }
} else { Classify 'Docker' 'not installed' 'PASS' 'not required for the chosen native deployment' }

# 11-12. WSL2 + virtualization
$wsl = (wsl.exe --status) 2>$null
if($LASTEXITCODE -eq 0 -and $wsl){ Classify 'WSL2' 'present' 'INFO' 'run wsl --shutdown when not needed' } else { Classify 'WSL2' 'not installed/available' 'PASS' 'not required for native deployment' }
$cs = Get-CimInstance Win32_ComputerSystem
Classify 'Virtualization (hypervisor present)' $cs.HypervisorPresent 'INFO' 'only matters if Docker path is ever chosen'

# 13. PowerShell
Classify 'PowerShell' $PSVersionTable.PSVersion.ToString() $(if($PSVersionTable.PSVersion.Major -ge 5){'PASS'}else{'ACTION'})

# 14. Python
$py = (python --version) 2>&1
if($py -match 'Python (3\.\d+)'){
    $minor = [int]($Matches[1].Split('.')[1])
    Classify 'Python' "$py" $(if($minor -in 11..12){'PASS'}elseif($minor -ge 10){'WARN'}else{'ACTION'}) 'native Open WebUI needs Python 3.11/3.12'
} else { Classify 'Python' 'not found' 'ACTION' 'install Python 3.12 (winget install Python.Python.3.12) for native Open WebUI' }

# 15. Git
$gitv = (git --version) 2>$null
Classify 'Git' $(if($gitv){$gitv}else{'not found'}) $(if($gitv){'PASS'}else{'WARN'}) $(if(-not $gitv){'needed to pull this kit; winget install Git.Git'})

# 16. Existing Ollama
$ollamaV = (ollama --version) 2>$null
if($ollamaV){
    Classify 'Ollama' "$ollamaV" 'PASS'
    $models = (ollama list) 2>$null
    Classify 'Ollama models' $(if($models){"`n$($models -join "`n")"}else{'none'}) 'INFO'
    $modDir = if($env:OLLAMA_MODELS){$env:OLLAMA_MODELS}else{Join-Path $env:USERPROFILE '.ollama\models'}
    if(Test-Path $modDir){
        $sz=[math]::Round((Get-ChildItem $modDir -Recurse -File | Measure-Object Length -Sum).Sum/1GB,1)
        Classify 'Model storage' "$modDir — $sz GB" 'INFO'
    }
} else { Classify 'Ollama' 'not installed' 'INFO' 'installed in Phase 2' }

# 18. Ports in use
foreach($p in 11434,8080,3000){
    $c = Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction SilentlyContinue
    if($c){
        $proc = (Get-Process -Id $c[0].OwningProcess -ErrorAction SilentlyContinue).ProcessName
        $lan  = $c | Where-Object { $_.LocalAddress -notin '127.0.0.1','::1' }
        Classify "Port $p" ("in use by '$proc' on " + (($c.LocalAddress | Select-Object -Unique) -join ',')) $(if($p -eq 11434 -and $proc -eq 'ollama' -and -not $lan){'PASS'}elseif($lan){'ACTION'}else{'WARN'}) $(if($lan){'listening beyond localhost — must be 127.0.0.1 only'})
    } else { Classify "Port $p" 'free' 'PASS' }
}

# 19. Security software
$av = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct
foreach($a in $av){ Classify 'Antivirus' $a.displayName 'INFO' 'never disable; note if it slows model loads (docs/08 exclusion rule)' }

# 20. Top RAM consumers + startup apps
Out-Line "`n--- Top 12 memory consumers now ---"
Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 12 |
    ForEach-Object { Out-Line ("  {0,-28} {1,7:N0} MB" -f $_.ProcessName, ($_.WorkingSet64/1MB)) }
Out-Line "`n--- Startup applications (review in Settings > Apps > Startup) ---"
Get-CimInstance Win32_StartupCommand | ForEach-Object { Out-Line ("  {0}  [{1}]" -f $_.Name, $_.Location) }

Out-Line "`n=============================================================="
Out-Line " GATE 1 RULE: proceed only with zero ACTION REQUIRED items,"
Out-Line " >= 40 GB SSD free, and a practical path to >= 8 GB free RAM."
Out-Line "=============================================================="

$repDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'reports'
New-Item -ItemType Directory -Force -Path $repDir | Out-Null
$repFile = Join-Path $repDir ("readiness-{0}.txt" -f (Get-Date -Format 'yyyyMMdd-HHmm'))
$lines | Set-Content -Path $repFile -Encoding UTF8
Write-Host "`nReport saved: $repFile"
