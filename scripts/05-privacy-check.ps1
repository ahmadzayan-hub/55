# 05-privacy-check.ps1 — Gate 9 exposure verification (read-only).
# Confirms AI services listen on localhost only and shows any external
# connections owned by stack processes. Run while the stack is up (ideally mid-chat).

$ErrorActionPreference = 'SilentlyContinue'
$fail = $false

Write-Host "=== Listening sockets for stack ports (11434 Ollama, 8080 WebUI, 3000 alt) ==="
foreach($p in 11434,8080,3000){
    $conns = Get-NetTCPConnection -State Listen -LocalPort $p
    if(-not $conns){ Write-Host ("Port {0,-5}: not listening" -f $p); continue }
    foreach($c in $conns){
        $proc = (Get-Process -Id $c.OwningProcess).ProcessName
        $ok = $c.LocalAddress -in '127.0.0.1','::1'
        if(-not $ok){ $fail = $true }
        Write-Host ("Port {0,-5}: {1,-12} on {2,-12} {3}" -f $p, $proc, $c.LocalAddress, $(if($ok){'[PASS localhost]'}else{'[FAIL — EXPOSED beyond localhost]'}))
    }
}

Write-Host "`n=== External connections held by stack processes (should be NONE during inference) ==="
$stackProcs = Get-Process | Where-Object { $_.ProcessName -match 'ollama|open-webui|python|uvx?' }
$external = Get-NetTCPConnection -State Established | Where-Object {
    $_.OwningProcess -in $stackProcs.Id -and
    $_.RemoteAddress -notmatch '^127\.|^::1$|^0\.0\.0\.0$'
}
if($external){
    $external | ForEach-Object {
        $pn = (Get-Process -Id $_.OwningProcess).ProcessName
        Write-Host ("  {0,-12} -> {1}:{2}" -f $pn, $_.RemoteAddress, $_.RemotePort)
    }
    Write-Host "  NOTE: expected ONLY during 'ollama pull' or pip/uv installs — never during document Q&A."
} else { Write-Host "  none — PASS" }

Write-Host "`n=== Windows Firewall profiles ==="
Get-NetFirewallProfile | ForEach-Object {
    Write-Host ("  {0,-8} enabled: {1}" -f $_.Name, $_.Enabled)
    if(-not $_.Enabled){ $fail = $true }
}

Write-Host "`n=== Inbound firewall rules mentioning ollama/webui (should be none or Block) ==="
$rules = Get-NetFirewallRule -Direction Inbound -Enabled True | Where-Object { $_.DisplayName -match 'ollama|open.?webui|python' }
if($rules){ $rules | ForEach-Object { Write-Host ("  {0}  Action={1}" -f $_.DisplayName, $_.Action) } }
else { Write-Host "  none found (fine — localhost binding needs no inbound rule)" }

Write-Host "`n=== Defender real-time protection ==="
$mp = Get-MpComputerStatus
if($mp){ Write-Host ("  RealTimeProtection: {0}" -f $mp.RealTimeProtectionEnabled); if(-not $mp.RealTimeProtectionEnabled){ Write-Host "  WARNING: Defender real-time protection is OFF — turn it back on." } }

Write-Host ("`nRESULT: " + $(if($fail){"FAIL — fix exposed bindings/firewall before Gate 9."}else{"PASS — localhost-only posture confirmed."}))
