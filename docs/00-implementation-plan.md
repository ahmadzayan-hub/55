# Implementation Plan — Phases, Gates, Execution Rules

## Execution rule

Work sequentially: **Inspect → Install → Verify → Benchmark → Optimize → Document.**
For every major action: explain what is being done, why it is necessary, execute the
exact command, verify the result, diagnose failures, and continue only after the
stage works. Never claim success without validation. Never install ten components
and troubleshoot everything afterward.

## Phases

### Phase 1 — System audit (Gate 1)
Run `scripts/00-audit.ps1`. Installs nothing, changes nothing. Produces a readiness
report in `reports\` with every finding classified PASS / WARNING / ACTION REQUIRED.
Then run `scripts/01-memory-check.ps1` and act on its recommendations manually
(this kit never disables Windows security services or Defender).
**Gate 1 passes when:** no ACTION REQUIRED items remain, ≥ 40 GB SSD free,
and available RAM can practically reach ~8 GB before launching models.

### Phase 2 — Ollama (Gates 2–3)
Run `scripts/02-install-ollama.ps1`. Verify `ollama --version` and `ollama list`.
Pull **one** model first (`qwen3:4b`), test it interactively (English, Arabic, mixed,
tables, technical reasoning), then benchmark with `scripts/03-benchmark.ps1`.
Only after a baseline exists, optionally pull `gemma3:4b` for comparison.
**Gate 2 passes when:** Ollama service responds on 127.0.0.1:11434.
**Gate 3 passes when:** the 4B model completes the full benchmark prompt set with
no crash, no sustained paging, and coherent Arabic + English output.

### Phase 3 — Open WebUI (Gate 4)
Follow `docs/03-openwebui-deployment.md`. Default: **native install** (uv/pip) bound
to 127.0.0.1 — avoids Docker Desktop + WSL2 memory overhead on a 16 GB machine.
**Gate 4 passes when:** UI loads at http://localhost:8080, admin account created,
Ollama models appear, a chat works, Arabic renders RTL correctly.

### Phase 4 — Local embeddings (part of Gate 5)
Pull `bge-m3` via Ollama and set it as Open WebUI's embedding model
(`docs/04-rag-configuration.md`). No cloud embedding API.

### Phase 5 — RAG (Gates 5–8)
Create one small knowledge library, upload one known PDF, **validate the extracted
text** (never trust a successful upload), then run the retrieval test set in
`docs/07-retrieval-testing.md`.
**Gate 5:** one PDF indexed and its text verified.
**Gate 6:** factual/multi-section/comparison questions answered from the document
with correct attribution.
**Gate 7:** questions with no answer in the documents are refused, not hallucinated.
**Gate 8:** Arabic and English retrieval both validated.

### Phase 6 — Security & operations (Gates 9–10)
Run `scripts/05-privacy-check.ps1`, complete the review in
`docs/08-security-privacy.md`, set up daily procedures (`docs/09-operations.md`),
backups (`scripts/backup.ps1`), and fill in `docs/12-final-report.md`.

### Phase 7 — Only after all gates
Consider: 8B model as advanced default, larger context, specialized assistants at
scale, experimental Intel Arc acceleration (IPEX-LLM), 12–14B experiments.

## Do not over-engineer

No extra databases, agent frameworks, orchestration systems, Kubernetes, multiple
vector DBs, multiple embedding models, or multiple LLM servers. The stack is:
Ollama + Open WebUI (with its built-in ChromaDB vector store) + one embedding model.
Add complexity only when a **measured** limitation justifies it.

## Approval boundary

The audit (Phase 1) and this plan constitute the "first action" deliverable.
Installation phases (2+) proceed only after the owner reviews the readiness report
and approves. Any external/cloud integration, experimental driver, or unsupported
runtime requires explicit approval — stability takes priority over theoretical
acceleration.
