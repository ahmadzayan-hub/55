# status.ps1 — one-screen operating dashboard (docs/09-operations.md).
# Console output by default; -Html also generates reports\dashboard.html
# (dark/purple snapshot styled after the project's UI mockup) and opens it.
param([switch]$Html)
$ErrorActionPreference = 'SilentlyContinue'

$os      = Get-CimInstance Win32_OperatingSystem
$totalGB = [math]::Round($os.TotalVisibleMemorySize/1MB,1)
$freeGB  = [math]::Round($os.FreePhysicalMemory/1MB,1)
$usedGB  = [math]::Round($totalGB-$freeGB,1)
$cm      = Get-Counter '\Memory\Committed Bytes','\Memory\Commit Limit'
$commit  = [math]::Round($cm.CounterSamples[0].CookedValue/1GB,1)
$climit  = [math]::Round($cm.CounterSamples[1].CookedValue/1GB,1)
$cpuLoad = [math]::Round((Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples[0].CookedValue,0)

$ollamaUp = $false; $ollamaVer=''; $loaded=@(); $models=@()
try {
    $v = Invoke-RestMethod 'http://127.0.0.1:11434/api/version' -TimeoutSec 2
    $ollamaUp = $true; $ollamaVer = $v.version
    $loaded = (Invoke-RestMethod 'http://127.0.0.1:11434/api/ps' -TimeoutSec 3).models
    $models = (Invoke-RestMethod 'http://127.0.0.1:11434/api/tags' -TimeoutSec 3).models
} catch {}
$webuiUp = $false
try { $null = Invoke-WebRequest 'http://127.0.0.1:8080' -TimeoutSec 2 -UseBasicParsing; $webuiUp = $true } catch {}

$modDir = if($env:OLLAMA_MODELS){$env:OLLAMA_MODELS}else{Join-Path $env:USERPROFILE '.ollama\models'}
$storGB = if(Test-Path $modDir){ [math]::Round((Get-ChildItem $modDir -Recurse -File | Measure-Object Length -Sum).Sum/1GB,1) } else { 0 }
$dataDir = Join-Path $env:USERPROFILE 'open-webui\data'
$docsGB = if(Test-Path $dataDir){ [math]::Round((Get-ChildItem $dataDir -Recurse -File | Measure-Object Length -Sum).Sum/1GB,1) } else { 0 }

Write-Host "================= LOCAL AI STATUS ================="
Write-Host ("Ollama      : {0}" -f $(if($ollamaUp){"RUNNING (v$ollamaVer)"}else{"STOPPED"}))
Write-Host ("Open WebUI  : {0}" -f $(if($webuiUp){"RUNNING (http://localhost:8080)"}else{"STOPPED"}))
if($loaded){ $loaded | ForEach-Object { Write-Host ("Loaded model: {0}  ({1:N1} GB resident)" -f $_.name, ($_.size/1GB)) } }
else       { Write-Host "Loaded model: none" }
Write-Host ("RAM         : {0} / {1} GB used  ({2} GB free)" -f $usedGB, $totalGB, $freeGB)
Write-Host ("Committed   : {0} / {1} GB" -f $commit, $climit)
Write-Host ("CPU         : {0}%" -f $cpuLoad)
Write-Host ("Model store : {0} GB   WebUI data: {1} GB" -f $storGB, $docsGB)
if($models){ Write-Host ("Installed   : " + (($models | ForEach-Object { $_.name }) -join ', ')) }
Write-Host "==================================================="

if($Html){
    $repDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'reports'
    New-Item -ItemType Directory -Force -Path $repDir | Out-Null
    $ramPct = [math]::Round($usedGB/$totalGB*100,0)
    $dot = { param($up) if($up){'#34d399'}else{'#f87171'} }
    $loadedTxt = if($loaded){ ($loaded | ForEach-Object { "$($_.name) — $([math]::Round($_.size/1GB,1)) GB" }) -join '<br>' } else { 'none' }
    $modelRows = ($models | ForEach-Object { "<tr><td>$($_.name)</td><td>$([math]::Round($_.size/1GB,1)) GB</td></tr>" }) -join ''
    $kb = 'Railway Engineering','MBA Learning','Business Strategy','Project Management','General Reference' |
          ForEach-Object { "<span class=chip>$_</span>" }
    @"
<!doctype html><html><head><meta charset="utf-8"><title>Local AI Assistant — Status</title><style>
body{background:#0b0d14;color:#e6e8f0;font-family:'Segoe UI',system-ui,sans-serif;margin:0;padding:32px}
h1{font-size:22px;margin:0 0 4px}.sub{color:#8b90a5;font-size:13px;margin-bottom:24px}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:14px}
.card{background:#141726;border:1px solid #23263a;border-radius:14px;padding:18px}
.k{color:#8b90a5;font-size:12px;text-transform:uppercase;letter-spacing:.05em}.v{font-size:20px;font-weight:600;margin-top:6px}
.dot{display:inline-block;width:9px;height:9px;border-radius:50%;margin-right:7px}
.bar{background:#23263a;border-radius:6px;height:8px;margin-top:10px;overflow:hidden}
.bar i{display:block;height:100%;background:linear-gradient(90deg,#6d5ef2,#8f7cff)}
table{width:100%;border-collapse:collapse;margin-top:8px;font-size:14px}td{padding:5px 0;border-bottom:1px solid #1d2032;color:#c5c9da}
.chip{display:inline-block;background:#1d2032;border:1px solid #2b2f47;color:#aeb3c9;border-radius:999px;padding:5px 12px;margin:3px;font-size:12px}
a{color:#8f7cff}</style></head><body>
<h1>Local AI Assistant — System Status</h1>
<div class="sub">Snapshot $(Get-Date -Format 'yyyy-MM-dd HH:mm') · refresh with: .\scripts\status.ps1 -Html</div>
<div class="grid">
<div class="card"><div class="k">Ollama</div><div class="v"><span class="dot" style="background:$(& $dot $ollamaUp)"></span>$(if($ollamaUp){"Running v$ollamaVer"}else{'Stopped'})</div></div>
<div class="card"><div class="k">Open WebUI</div><div class="v"><span class="dot" style="background:$(& $dot $webuiUp)"></span>$(if($webuiUp){'Running'}else{'Stopped'})</div><div class="sub" style="margin:8px 0 0"><a href="http://localhost:8080">localhost:8080</a></div></div>
<div class="card"><div class="k">Loaded model</div><div class="v" style="font-size:15px">$loadedTxt</div></div>
<div class="card"><div class="k">RAM</div><div class="v">$usedGB / $totalGB GB</div><div class="bar"><i style="width:$ramPct%"></i></div><div class="sub" style="margin:8px 0 0">committed $commit / $climit GB</div></div>
<div class="card"><div class="k">CPU</div><div class="v">$cpuLoad%</div><div class="bar"><i style="width:$cpuLoad%"></i></div></div>
<div class="card"><div class="k">Storage</div><div class="v" style="font-size:15px">Models $storGB GB<br>Documents $docsGB GB</div></div>
</div>
<div class="card" style="margin-top:14px"><div class="k">Installed models</div><table>$modelRows</table></div>
<div class="card" style="margin-top:14px"><div class="k">Knowledge bases (open in WebUI &gt; Workspace &gt; Knowledge)</div><div style="margin-top:8px">$($kb -join '')</div></div>
</body></html>
"@ | Set-Content -Path (Join-Path $repDir 'dashboard.html') -Encoding UTF8
    Start-Process (Join-Path $repDir 'dashboard.html')
    Write-Host "Dashboard written: reports\dashboard.html"
}
