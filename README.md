# Private Local AI Knowledge Assistant — Windows Implementation Kit

A complete, phased implementation package for building a **private, local-first,
source-grounded AI knowledge assistant** on a Windows 11 laptop
(Intel Core Ultra 7 155H, 16 GB LPDDR5, Intel Arc iGPU, 1 TB NVMe).

## Target architecture

```
Windows 11
   └── Ollama (local model runtime, bound to 127.0.0.1)
         └── Qwen3 / Gemma3 local LLMs (4B default, 8B advanced)
               └── Open WebUI (native install, bound to 127.0.0.1)
                     └── Local embedding model (bge-m3 via Ollama)
                           └── Local RAG / vector search (Open WebUI built-in ChromaDB)
                                 └── Private knowledge libraries (Railway / MBA / Business / Reference)
                                       └── PDF, DOCX, PPTX, XLSX, CSV, TXT, Markdown
                                             └── Specialized assistants (4 role-tuned system prompts)
```

**Design principle:** Local first · private by design · resource efficient ·
source grounded · simple to operate. Quality × Speed × Memory × Stability × Privacy —
never "largest model that technically loads."

## How to use this kit

Work **sequentially** through the gates. Every phase has a script to execute on the
Windows laptop (PowerShell) and a document explaining what, why, and how to verify.
Do not proceed past a gate until it passes.

| Gate | What must be true | Script / doc |
|------|-------------------|--------------|
| 1 | Windows environment healthy | `scripts/00-audit.ps1` · `docs/01-system-readiness.md` |
| 2 | Ollama operational | `scripts/02-install-ollama.ps1` |
| 3 | 4B model stable | `scripts/03-benchmark.ps1` · `docs/02-model-strategy.md` |
| 4 | Open WebUI operational | `scripts/04-install-openwebui.ps1` · `docs/03-openwebui-deployment.md` |
| 5 | One PDF successfully indexed | `docs/04-rag-configuration.md` |
| 6 | RAG answers test questions correctly | `docs/07-retrieval-testing.md` |
| 7 | RAG refuses unsupported questions | `docs/07-retrieval-testing.md` |
| 8 | Arabic/English retrieval validated | `docs/07-retrieval-testing.md` |
| 9 | Security & privacy reviewed | `scripts/05-privacy-check.ps1` · `docs/08-security-privacy.md` |
| 10 | Backup & operating procedures documented | `scripts/backup.ps1` · `docs/09-operations.md`, `docs/11-backup-updates.md` |

## Quick start (on the Windows laptop)

```powershell
# 0. Clone the repo and MOVE INTO ITS FOLDER — every command below assumes
#    your PowerShell prompt is inside the repo root, not your home folder.
cd $env:USERPROFILE
git clone https://github.com/ahmadzayan-hub/55.git
cd 55                                          # <- easy to miss; see docs/10 if a
                                                #    script says "not recognized"

# 1. Allow running the kit's scripts for this PowerShell session:
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# 2. Gate 1 — audit (installs nothing, changes nothing)
.\scripts\00-audit.ps1

# 3. Gate 2 — install Ollama after reviewing the audit report
.\scripts\02-install-ollama.ps1

# 4. Gate 3 — pull one model and benchmark it
ollama pull qwen3:4b
.\scripts\03-benchmark.ps1 -Model qwen3:4b

# 5. Gate 4 — install Open WebUI (native, localhost-only)
.\scripts\04-install-openwebui.ps1

# Daily operation
.\scripts\start-ai.ps1      # start stack
.\scripts\status.ps1        # dashboard
.\scripts\stop-ai.ps1       # clean shutdown
.\scripts\backup.ps1        # backup user data
```

## Repository map

```
docs/
  00-implementation-plan.md    Phases, gates, execution rules
  01-system-readiness.md       Pre-assessment, audit interpretation, risks
  02-model-strategy.md         Model selection, benchmarking, scorecard, context sizing
  03-openwebui-deployment.md   Deployment method decision + install + verification
  04-rag-configuration.md      Embeddings, chunking, retrieval, document QC, ingestion
  05-knowledge-libraries.md    Library structure, metadata, version control
  06-assistants.md             System prompts: base RAG + 4 specialized assistants
  07-retrieval-testing.md      Test set design, metrics, evaluation scoring
  08-security-privacy.md       Security review, data-flow/privacy verification, boundaries
  09-operations.md             Operating modes, startup/shutdown, monitoring dashboard
  10-troubleshooting.md        Playbook: symptom → cause → diagnostic → fix
  11-backup-updates.md         Backup strategy, update policy, version register
  12-final-report.md           Deliverables A–J template + executive recommendation
  13-ui-blueprint.md           Mapping the "Local AI Assistant" UI mockups to the stack
  14-ui-generation-prompt.md   Ready-to-paste prompt for AI UI tools to generate the frontend
  15-agent-orchestration.md    Tool-using agent design, verified endpoints, security posture
scripts/
  00-audit.ps1                 Full system audit → readiness report (read-only)
  01-memory-check.ps1          Memory consumers + safe optimization recommendations
  02-install-ollama.ps1        Install + verify Ollama
  03-benchmark.ps1             Model benchmark: load, TTFT, tok/s, RAM → CSV
  04-install-openwebui.ps1     Native Open WebUI install, localhost-bound
  05-privacy-check.ps1         Port bindings, firewall, exposure verification
  start-ai.ps1 / stop-ai.ps1   Daily startup / clean shutdown
  start-frontend.ps1           Launch the custom frontend UI (see frontend/)
  status.ps1                   One-screen dashboard (-Html renders reports\dashboard.html)
  backup.ps1                   Backup Open WebUI data, config, version register
frontend/
  src/ + dist/ + server.py     React "Local AI Assistant" UI (mockup design, live data)
benchmarks/
  prompts.json                 Bilingual (AR/EN/mixed) benchmark prompt set
reports/                       Audit + benchmark output lands here (gitignored)
```
