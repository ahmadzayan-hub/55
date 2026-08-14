# 01-memory-check.ps1 — memory consumers + SAFE optimization recommendations.
# READ-ONLY: recommends; never kills processes, never touches security services.

$ErrorActionPreference = 'SilentlyContinue'
$os = Get-CimInstance Win32_OperatingSystem
$freeGB = [math]::Round($os.FreePhysicalMemory/1MB,1)
Write-Host "Available RAM: $freeGB GB (target >= 8 GB before loading models)`n"

# Group known heavy app families and show their aggregate footprint
$families = @{
    'Chrome'   = 'chrome'
    'Edge'     = 'msedge'
    'Teams'    = 'ms-teams|Teams'
    'Adobe'    = 'Acrobat|Adobe|CCLibrary|CoreSync|CCXProcess|AdobeIPCBroker'
    'Docker'   = 'com.docker|Docker Desktop'
    'WSL'      = 'vmmem|vmmemWSL|wsl'
    'DevTools' = 'Code|devenv|idea64|node'
    'OneDrive' = 'OneDrive'
}
Write-Host ("{0,-10} {1,10}  {2}" -f 'App','RAM (MB)','Safe action if not needed right now')
Write-Host ('-'*78)
$advice = @{
    'Chrome'='close unused tabs/windows; disable background mode in chrome://settings'
    'Edge'='close unused tabs; sleep tabs on; disable startup boost (edge://settings)'
    'Teams'='quit fully from tray when not in meetings'
    'Adobe'='quit apps; disable Adobe startup/updater tasks in Startup Apps'
    'Docker'='quit Docker Desktop; not needed by the native AI stack'
    'WSL'='run: wsl --shutdown (releases vmmem)'
    'DevTools'='close IDEs/servers not in use during AI sessions'
    'OneDrive'='pause sync during heavy AI sessions (do not uninstall)'
}
foreach($f in $families.Keys){
    $procs = Get-Process | Where-Object { $_.ProcessName -match $families[$f] }
    if($procs){
        $mb = [math]::Round(($procs | Measure-Object WorkingSet64 -Sum).Sum/1MB,0)
        Write-Host ("{0,-10} {1,10:N0}  {2}" -f $f, $mb, $advice[$f])
    }
}

Write-Host "`n--- Other top consumers ---"
Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10 |
    ForEach-Object { Write-Host ("  {0,-30} {1,7:N0} MB" -f $_.ProcessName, ($_.WorkingSet64/1MB)) }

Write-Host @'

RULES (do manually, never scripted):
 * Trim startup apps: Settings > Apps > Startup (Teams, Adobe updaters, Spotify...).
 * NEVER disable Windows security services or Microsoft Defender for performance.
 * No registry "RAM optimizers", no page-file removal, no service butchery.
 * If Docker Desktop exists but is unused, set it to not start at login.
Re-run this script until available RAM >= 8 GB, then launch the AI stack.
'@
