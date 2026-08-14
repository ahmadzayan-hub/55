# 03-benchmark.ps1 — model benchmark harness (Gate 3 + bake-off).
# Runs benchmarks/prompts.json against one model via the Ollama API, records
# load time, time-to-first-token (approx), tok/s, and RAM to reports\bench-<model>-<date>.csv
# Usage: .\scripts\03-benchmark.ps1 -Model qwen3:4b [-NumCtx 8192]

param(
    [Parameter(Mandatory=$true)][string]$Model,
    [int]$NumCtx = 8192
)
$ErrorActionPreference = 'Stop'
$root    = Split-Path $PSScriptRoot -Parent
$prompts = Get-Content (Join-Path $root 'benchmarks\prompts.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$repDir  = Join-Path $root 'reports'
New-Item -ItemType Directory -Force -Path $repDir | Out-Null
$csv = Join-Path $repDir ("bench-{0}-{1}.csv" -f ($Model -replace '[:/]','_'), (Get-Date -Format 'yyyyMMdd-HHmm'))

function FreeRamGB { [math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,2) }

# sanity: API up, model present
$null = Invoke-RestMethod 'http://127.0.0.1:11434/api/version' -TimeoutSec 5
$tags = Invoke-RestMethod 'http://127.0.0.1:11434/api/tags'
if(-not ($tags.models.name -contains $Model)){ throw "Model '$Model' not pulled. Run: ollama pull $Model" }

Write-Host "Benchmarking $Model  (num_ctx=$NumCtx)"
Write-Host "Free RAM before: $(FreeRamGB) GB"
& ollama stop $Model 2>$null   # ensure a cold load for the first prompt

$rows = @()
$i = 0
foreach($p in $prompts){
    $i++
    Write-Host ("[{0}/{1}] {2} ({3}) ... " -f $i, $prompts.Count, $p.id, $p.lang) -NoNewline
    $body = @{ model=$Model; prompt=$p.prompt; stream=$false
               options=@{ num_ctx=$NumCtx; temperature=0.6 } } | ConvertTo-Json -Depth 5
    $t0 = Get-Date
    $r  = Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/generate' -Method Post `
            -Body ([Text.Encoding]::UTF8.GetBytes($body)) -ContentType 'application/json' -TimeoutSec 600
    $wall   = ((Get-Date) - $t0).TotalSeconds
    $loadS  = [math]::Round($r.load_duration/1e9,2)
    $ttftS  = [math]::Round(($r.load_duration + $r.prompt_eval_duration)/1e9,2)
    $tokS   = if($r.eval_duration){ [math]::Round($r.eval_count/($r.eval_duration/1e9),2) } else { 0 }
    $ramNow = FreeRamGB
    Write-Host ("{0} tok/s, TTFT {1}s, load {2}s" -f $tokS, $ttftS, $loadS)
    $rows += [pscustomobject]@{
        model=$Model; prompt_id=$p.id; category=$p.category; lang=$p.lang
        load_s=$loadS; ttft_s=$ttftS; tokens_out=$r.eval_count; tok_per_s=$tokS
        wall_s=[math]::Round($wall,1); free_ram_gb=$ramNow; num_ctx=$NumCtx
        quality_1to5=''; arabic_1to5=''; english_1to5=''; reasoning_1to5=''; halluc_1to5=''
        response=($r.response -replace "[`r`n]+",' ' ).Substring(0,[math]::Min(400,$r.response.Length))
    }
}

$rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
Write-Host "`nLoaded model state:"; ollama ps
$proc = Get-Process ollama -ErrorAction SilentlyContinue | Sort-Object WorkingSet64 -Descending | Select-Object -First 1
if($proc){ Write-Host ("Ollama process RAM: {0:N1} GB" -f ($proc.WorkingSet64/1GB)) }
Write-Host @"

CSV written: $csv
NEXT: open the CSV, read each response, and fill the human-score columns
(quality/arabic/english/reasoning/halluc, 1-5; halluc 5 = no hallucination —
check 'halluc-probe' admitted not knowing the fictional standard).
Then compute the weighted scorecard per docs/02-model-strategy.md.
"@
