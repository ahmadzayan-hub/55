# Troubleshooting Playbook

Format per issue: **Symptom → Likely cause → Diagnostic → Corrective action.**

## "The term '.\scripts\...\.ps1' is not recognized"
- **Cause:** the most common Gate-1 stumble — PowerShell is running from
  `C:\Users\<you>`, not from inside the cloned repo, so the relative path
  `.\scripts\...` points nowhere.
- **Diagnose:** run `Get-Location` — if it prints your home folder instead of
  the repo folder (e.g. `...\55`), that's the cause. `dir` should show
  `docs`, `scripts`, `frontend` if you're in the right place.
- **Fix:** `cd` into the cloned repo first, every session:
  ```powershell
  cd $env:USERPROFILE\55        # or wherever you cloned it
  .\scripts\00-audit.ps1
  ```
  If the folder isn't there yet, clone it (`git clone
  https://github.com/ahmadzayan-hub/55.git`) and `cd 55` before running
  anything — see the Quick Start in the repo README.

## Ollama not starting
- **Cause:** service/tray not running; port 11434 taken; corrupted install.
- **Diagnose:** `ollama list` (connection error?); `Get-NetTCPConnection -LocalPort 11434`; `%LOCALAPPDATA%\Ollama\server.log`.
- **Fix:** start Ollama app; kill/reassign the conflicting process; reinstall Ollama (models survive reinstall).

## Model not loading
- **Cause:** insufficient free RAM; corrupted download; wrong tag.
- **Diagnose:** `ollama run <model>` error text; free RAM in `status.ps1`; `ollama list` shows the model?
- **Fix:** free RAM (close apps, `ollama stop` other models); `ollama rm <model> && ollama pull <model>`; verify tag spelling.

## Out of memory / Windows paging (disk 100%, everything crawls)
- **Cause:** model + context too big for current free RAM; too many co-loaded models; Docker/WSL eating headroom.
- **Diagnose:** committed memory vs limit (`status.ps1`); `ollama ps` (how many models resident?); Task Manager disk column.
- **Fix:** `ollama stop <model>` extras; drop context to 4–8K; use 4B not 8B; `wsl --shutdown`; reboot if commit stays high. Set `OLLAMA_MAX_LOADED_MODELS=1`.

## Very slow generation
- **Cause:** paging (see above); running 8B/14B on busy system; thermal throttling on battery; huge context filled.
- **Diagnose:** tok/s vs your benchmark baseline; power mode; context length in use.
- **Fix:** resolve memory first; plug in / set Best Performance; shorten context; smaller model.

## Open WebUI cannot connect to Ollama
- **Cause:** Ollama down; wrong URL in Connections; (Docker only) `localhost` inside container ≠ host.
- **Diagnose:** `Invoke-RestMethod http://127.0.0.1:11434/api/version`; Admin → Settings → Connections.
- **Fix:** start Ollama; set URL `http://127.0.0.1:11434`; in Docker use `http://host.docker.internal:11434`.

## Open WebUI won't start / crashes
- **Cause:** port 8080 taken; Python version unsupported; broken upgrade.
- **Diagnose:** console output at launch; `Get-NetTCPConnection -LocalPort 8080`.
- **Fix:** change `--port`; use Python 3.11/3.12; pin previous version (`uvx open-webui==<last-working> serve ...`) and restore data from backup if migration corrupted it.

## Docker failure (only if Docker path chosen)
- **Cause:** WSL2 not enabled/updated; virtualization off in BIOS; resource exhaustion.
- **Diagnose:** `wsl --status`; `docker info`; audit report virtualization line.
- **Fix:** `wsl --update`; enable VT-x in BIOS; cap WSL2 via `%USERPROFILE%\.wslconfig` (`memory=3GB`) then `wsl --shutdown`. Or switch to the native install (recommended).

## Port conflict
- **Diagnose:** `Get-NetTCPConnection -LocalPort 11434,8080 | Select LocalAddress,OwningProcess`; `Get-Process -Id <pid>`.
- **Fix:** stop the other app, or move WebUI (`--port 8081`) / Ollama (`OLLAMA_HOST=127.0.0.1:11435`, then update WebUI connection).

## PDF upload fails
- **Cause:** oversized file; encrypted PDF; extraction timeout.
- **Diagnose:** WebUI console log during upload; try a 1-page test PDF.
- **Fix:** split the PDF; remove password; raise upload limit in Admin → Documents; convert to DOCX.

## Bad text extraction (garbage/empty content)
- **Cause:** scanned PDF (no text layer); legacy Arabic encoding; complex layout.
- **Diagnose:** QC workflow in docs/04 — ask the model to quote the document verbatim.
- **Fix:** OCR the file (`ocrmypdf --language ara+eng`); re-export from source app; convert to DOCX/Markdown; re-ingest and re-verify.

## RAG can't find information you know is there
- **Cause:** bad extraction (most common); chunk boundaries split the answer; top-k too low; embedding model changed after ingestion.
- **Diagnose:** QC the specific document; ask a verbatim-quote question; check Admin → Documents settings unchanged since ingestion.
- **Fix:** fix extraction; top-k 5→8; adjust chunk size and **re-index**; re-index after any embedding model change.

## Wrong citations
- **Cause:** chunks too large (attribution blur); duplicate/near-duplicate documents; stale index.
- **Fix:** smaller chunks; deduplicate collection; delete + re-add the document.

## Arabic problems (extraction, rendering, retrieval)
- **Cause:** PDF lacks proper Unicode mapping; font issues; model weakness.
- **Diagnose:** paste extracted Arabic into a text editor — reversed/disjointed letters = extraction fault, not model fault.
- **Fix:** re-export/OCR the document; verify bge-m3 is the embedding model; for generation quality compare qwen3 vs gemma3 on the Arabic prompt set.

## High RAM usage / high CPU usage at idle
- **Cause:** model kept alive; multiple models resident; WSL2 `vmmem`; indexing job running.
- **Fix:** `ollama stop <model>`; `OLLAMA_KEEP_ALIVE=10m`; `wsl --shutdown`; let indexing finish before new work.

## Model crash mid-generation
- **Cause:** memory exhaustion at long context; corrupted model file.
- **Diagnose:** `server.log` tail; did context exceed benchmarked setting?
- **Fix:** reduce context; re-pull model; keep the benchmark CSV as the known-good envelope.
