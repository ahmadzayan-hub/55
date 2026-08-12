# Final Deliverables Report (fill during implementation; complete at Gate 10)

## A. Architecture (as implemented)

```
Windows 11 (build ____)
 └─ Ollama ____ @ 127.0.0.1:11434            (native Windows service/tray)
     ├─ qwen3:4b   — default LLM             (Q4_K_M, ~2.6 GB)
     ├─ qwen3:8b   — deep-analysis LLM       (installed: Y/N)
     └─ bge-m3     — embedding model
 └─ Open WebUI ____ @ 127.0.0.1:8080         (native uv/pip, DATA_DIR=____)
     ├─ ChromaDB vector store (built-in)
     ├─ Knowledge libraries: RE-*, PM-Core, MBA-*, BIZ-Core, REF-General
     └─ Assistants: Railway Eng · MBA Learning · Business Strategy · Doc Analyst
```

## B. Installation record

| Software | Version | Install date | Method |
|---|---|---|---|
| Ollama | | | official installer |
| Open WebUI | | | uvx/pip, pinned |
| Python | | | |
| (Docker/WSL2 — only if used) | | | |

## C. Model register

| Model | Tag / digest | Size | Role | Scorecard result |
|---|---|---|---|---|
| qwen3:4b | | | default (pending bake-off) | |
| gemma3:4b | | | comparison (removed after bake-off: Y/N) | |
| qwen3:8b | | | deep analysis | |
| bge-m3 | | | embeddings | — |

## D. Configuration decisions

| Setting | Value | Why |
|---|---|---|
| WebUI bind | 127.0.0.1:8080 | privacy: no LAN/public exposure |
| Ollama bind | 127.0.0.1:11434 (default) | same |
| Context (STANDARD) | 8K | RAM headroom vs RAG needs (benchmarked) |
| Chunk / overlap / top-k | 800 / 100 / 5 (tuned to: ____) | Gate 6 test results |
| Hybrid search | on | exact technical terms & clause numbers |
| Embedding engine/model | Ollama / bge-m3 | multilingual AR+EN, local |
| OLLAMA_KEEP_ALIVE | 10m | RAM release vs reload cost |
| Auto-start at boot | disabled | 16 GB discipline |
| Signups | disabled after admin created | private system |

## E. Performance report (from reports/*.csv + observation)

| Metric | qwen3:4b | gemma3:4b | qwen3:8b |
|---|---|---|---|
| Load time (cold, s) | | | |
| Time to first token (s) | | | |
| Generation speed (tok/s) | | | |
| RAM resident (GB) | | | |
| CPU utilization during gen (%) | | | |
| GPU utilization (evidence) | | | |
| Weighted scorecard (docs/02) | | | |

## F. RAG evaluation (per library, from docs/07 test logs)

| Library | Retrieval precision | Faithfulness | Citation accuracy | Refusal rate | Median latency |
|---|---|---|---|---|---|
| | | | | | |

## G. Security review summary

- Listening sockets 127.0.0.1-only: PASS/FAIL (privacy-check output attached)
- WebUI auth + signups closed: __ · Firewall on: __ · Defender on: __
- External connections during inference: none observed / findings: __
- Document/vector/chat storage locations reviewed and access-controlled: __
- BitLocker: __ · Backup location encrypted: __

## H. User guide → `docs/09-operations.md` (startup, modes, upload + QC, knowledge
libraries, model selection, shutdown). I. Troubleshooting → `docs/10`.
J. Backup → `docs/11` + `scripts/backup.ps1`.

---

## Executive recommendation (complete after Gate 10)

- **Best default LLM:** ____ (measured winner; expected qwen3:4b)
- **Best embedding model:** bge-m3
- **Recommended context size:** 8K standard / 4K light / ____ deep
- **Recommended RAG settings:** chunk ____ / overlap ____ / top-k ____ / hybrid on
- **Expected performance:** ____ tok/s (4B), ____ s median RAG answer
- **Hardware limitation:** 16 GB soldered RAM → 4B default, 8B ceiling, 12B+ not recommended
- **Larger model justified?** ____ (only if 8B benchmark shows stable headroom and quality need)
- **Intel Arc acceleration working?** ____ (evidence: ollama ps / logs / tok/s delta; stock build = No expected)
- **NPU contributing?** No — unsupported by this stack (state evidence)
- **Docker: keep enabled?** ____ (native deployment ⇒ Docker not required; if installed, keep stopped)
- **Security status:** ____ (localhost-only, authenticated, no external inference traffic)
- **Next recommended improvement:** ____ (candidates: 8B as deep-analysis default; reranker if precision lags; IPEX-LLM Arc experiment; per-library metadata register automation)
