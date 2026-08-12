# System Readiness — Pre-Assessment, Audit, Risks

Run `scripts/00-audit.ps1` on the laptop to produce the measured report. This
document records the **analytical pre-assessment** from the known hardware
specification and defines how to interpret the audit output.

## SYSTEM READINESS (pre-assessment from stated specification)

| Item | Value | Classification |
|------|-------|----------------|
| CPU | Intel Core Ultra 7 155H — 16 cores / 22 threads (6P + 8E + 2 LP-E) | **PASS** — strong CPU inference; AVX2/VNNI used by llama.cpp backend |
| RAM | 16 GB LPDDR5-7467, soldered, not upgradeable | **WARNING** — the defining constraint; dictates 4B default / 8B ceiling |
| Available RAM | To be measured — target ≥ 8 GB free before loading models | Measured by audit |
| GPU | Intel Arc integrated, no dedicated VRAM; "shared GPU memory ~8.8 GB" **is the same 16 GB system RAM**, not extra memory | **WARNING** — treat as CPU-only until acceleration is proven with evidence |
| NPU | Intel AI Boost | **WARNING** — Ollama has no NPU support; assume zero contribution unless verified |
| Storage | 1 TB NVMe (~954 GB formatted) | **PASS** — ample; models ~3–6 GB each |
| Windows | Windows 11 (build measured by audit) | Measured by audit |
| Virtualization / WSL2 / Docker | Measured by audit | Only needed if Docker deployment is chosen (it is not the default) |
| PowerShell / Python / Git | Measured by audit | Python 3.11–3.12 needed for native Open WebUI |
| Ports 11434 / 8080 / 3000 | Measured by audit | Must be free or deconflicted |

## RESOURCE ASSESSMENT — the main bottleneck

**RAM is the single dominant bottleneck.** Everything else is comfortable.

Realistic memory budget in STANDARD mode:

| Component | Typical RAM |
|---|---|
| Windows 11 + drivers + background | 4.5–6 GB |
| Ollama + qwen3:4b (Q4_K_M) @ 8K context | 3.5–4.5 GB |
| Open WebUI (native) + ChromaDB + embedding model resident | 1.5–2.5 GB |
| Browser (a few tabs) | 1–2 GB |
| **Total** | **~11–14 GB** — workable, little headroom |

An 8B model at Q4 adds ~2.5–3 GB over the 4B; feasible only with disciplined
background-app hygiene (DEEP ANALYSIS mode). 12–14B models will page on this
machine under normal conditions — experimental only, after benchmarking.
Second bottleneck: **memory bandwidth** — LPDDR5-7467 is good for an iGPU-class
machine and is what actually sets CPU token generation speed (~expect 10–20 tok/s
on a 4B Q4 model, ~6–12 tok/s on 8B; confirm by benchmark).

## RECOMMENDED INITIAL STACK

| Decision | Recommendation | Why |
|---|---|---|
| LLM (default) | **qwen3:4b** (Q4_K_M, ~2.6 GB) | Best-in-class ≤4B multilingual incl. Arabic; strong technical reasoning; hybrid think/no-think modes |
| LLM (comparison) | **gemma3:4b** (~3.3 GB) — pull only for the bake-off | Strong multilingual alternative; benchmark decides, not reputation |
| LLM (advanced) | **qwen3:8b** — only after Gate 6 and only in DEEP ANALYSIS mode | Quality step-up when RAM discipline allows |
| Embedding model | **bge-m3** via Ollama (~1.2 GB) | Top open multilingual retriever (100+ languages incl. Arabic), 8K token input, dense retrieval, native Open WebUI/Ollama integration |
| Open WebUI deployment | **Native (uv/pip)**, bound to 127.0.0.1:8080 | Saves the ~1.5–2.5 GB Docker Desktop + WSL2 overhead — decisive on 16 GB |
| Vector DB | Open WebUI built-in **ChromaDB** | Zero extra components; adequate at this document scale |
| RAG starting settings | chunk 800 tokens / overlap 100 / top-k 5 / context 8K | Conservative; tune experimentally per docs/04 |
| Acceleration | **CPU-only first.** Arc via IPEX-LLM = optional later experiment; NPU = not used | No stable Ollama support today; stability > theoretical speed |

## RISKS

| Risk | Severity | Mitigation |
|---|---|---|
| Memory pressure → paging → severe slowdown/instability | High | 4B default; 8K context cap; native (non-Docker) WebUI; operating modes; free ≥8 GB before model launch; monitor committed memory |
| Believing "8.8 GB shared GPU memory" is extra memory | High | It is system RAM. All sizing in this kit uses the 16 GB physical total only |
| Assuming Arc/NPU acceleration without evidence | Medium | CPU-only baseline; any acceleration claim requires logs/benchmarks (docs/02 §GPU/NPU) |
| Silent bad PDF extraction (esp. scanned or complex Arabic PDFs) → unreliable RAG | High | Mandatory extraction validation per document (docs/04 QC workflow); OCR optional and deliberate |
| Arabic RTL/extraction defects | Medium | Bilingual test set (Gate 8); flag and re-convert failing documents |
| Accidental network exposure of private documents | Medium | Everything bound to 127.0.0.1; WebUI auth on; privacy-check script; no tunnels |
| Docker/WSL2 idle RAM drain if installed | Medium | Native deployment default; if Docker exists, keep it stopped when not needed |
| Uncontrolled auto-updates breaking a working stack | Medium | Version register + one-component-at-a-time update policy (docs/11) |
| Outdated document revisions polluting answers | Medium | Metadata + supersede workflow (docs/05) |

## Interpreting the audit report

- **PASS** — proceed.
- **WARNING** — proceed, but note it in the final report and monitor.
- **ACTION REQUIRED** — stop; fix before the next gate (e.g., <40 GB disk free,
  port 11434/8080 occupied, no Python for native WebUI, security product blocking
  localhost servers).

The audit makes **no changes** to Windows. Memory optimization
(`scripts/01-memory-check.ps1`) only *reports and recommends* — closing Chrome/Edge
tab hoards, Teams, Adobe background updaters, stopping idle Docker/WSL, and trimming
startup apps is done by the owner, manually, in Settings → Apps → Startup and Task
Manager. Windows security services and Defender are never disabled.
