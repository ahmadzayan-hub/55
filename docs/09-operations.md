# Operations — Modes, Startup/Shutdown, Dashboard, Resource Management

## Operating modes (16 GB discipline)

| | LIGHT | **STANDARD (normal)** | DEEP ANALYSIS |
|---|---|---|---|
| Model | qwen3:4b | qwen3:4b (or bake-off winner) | qwen3:8b |
| Context | 4K | 8K | 8–16K (measured first) |
| RAG | basic, top-k 3 | top-k 5, hybrid | top-k 8 |
| Background apps | anything | reasonable | close browsers/Teams/Adobe; stop Docker/WSL |
| Free RAM before start | ≥ 5 GB | ≥ 8 GB target | ≥ 9–10 GB |
| Use | quick Q&A on battery | daily work | large document analysis, then **return to STANDARD** |

Mode is a behavior, not an installation: pick the model + context in Open WebUI
and manage background apps accordingly.

## Daily startup (automated by `scripts/start-ai.ps1`)

1. Check available RAM (script warns below target).
2. Start Ollama if not running.
3. Start Open WebUI if required.
4. Confirm the selected model responds (1-token ping).
5. Open http://localhost:8080 in the browser.
6. Select the assistant / knowledge library for the session.
7. Work.

Nothing here auto-starts at Windows boot — deliberate choice on 16 GB (revisit
only if benchmarks prove boot-time impact acceptable). If the stock Ollama app
registers itself in Startup Apps, disable it there (Settings → Apps → Startup);
the start script launches it on demand.

## Shutdown (`scripts/stop-ai.ps1`)

1. `ollama stop <model>` — unload models from RAM immediately.
2. Stop the Open WebUI process.
3. Optionally stop the Ollama service/tray app.
4. If Docker/WSL were used: `wsl --shutdown` and quit Docker Desktop.

Models otherwise stay resident (default keep-alive ~5 min after last use; the
start script sets `OLLAMA_KEEP_ALIVE=10m` — long enough for a working session
pattern, short enough to release RAM when you move on). Clean shutdown matters on
battery: an idle loaded model is multi-GB of RAM held for nothing.

## Dashboard

`scripts/status.ps1` prints one screen: Ollama up? · loaded models + size +
CPU/GPU split (`ollama ps`) · Open WebUI up? (port 8080) · RAM total/free/
committed · CPU load · model storage consumption · listening sockets for 11434/8080.

Manual equivalents:

```powershell
ollama list        # installed models + sizes
ollama ps          # loaded models, RAM, CPU/GPU split, keep-alive
Get-Process ollama, python* | Select ProcessName, @{n='RAM(GB)';e={[math]::Round($_.WorkingSet64/1GB,2)}}
Get-Counter '\Memory\Available MBytes','\Memory\Committed Bytes'
```

Watch for trouble: **committed memory approaching the commit limit** and heavy
disk activity during generation = paging = wrong mode for current RAM; drop to a
smaller model/context or close apps.

## Resource monitoring during heavy work

Keep Task Manager → Performance open during first-time operations (model load,
bulk indexing, 8B experiments): RAM utilization, committed, CPU, disk. Record
observations in the final report §E.
