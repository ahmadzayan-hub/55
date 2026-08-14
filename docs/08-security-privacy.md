# Security & Privacy — Review Checklist, Data Flow, Boundaries (Gate 9)

## Security posture

The system handles private/confidential documents. Rules:

1. **Bind everything to localhost.** Ollama: default `127.0.0.1:11434` — do not
   set `OLLAMA_HOST=0.0.0.0`. Open WebUI: started with `--host 127.0.0.1`.
   Verified by `scripts/05-privacy-check.ps1`. LAN access only if explicitly
   decided later, and then with authentication + firewall scoping.
2. **Authentication on.** Open WebUI admin account with a strong unique password;
   open signups disabled; no shared accounts.
3. **No public exposure. Ever, by default.** No port forwarding, no public
   tunnels (ngrok/cloudflared), no reverse proxies to the internet, no external
   sync of knowledge databases. Any external integration requires explicit,
   deliberate approval.
4. **Windows Firewall** stays on. If Ollama/Python prompt for firewall access on
   first run, private-network scope only — and with 127.0.0.1 binding no inbound
   rule is actually needed; deny is safest.
5. **Defender stays on.** Never disabled for performance. If real-time scanning
   measurably slows model loading, the *only* acceptable tuning is a narrow
   exclusion for the model blob directory (`%USERPROFILE%\.ollama\models`) —
   models are static data files; never exclude executables or user documents.

## Data at rest — know where everything lives

| Data | Location | Sensitivity |
|---|---|---|
| Documents (uploaded copies) | `DATA_DIR\uploads` | **High** |
| Vector DB (embedded content) | `DATA_DIR\vector_db` | **High** — embeddings + chunk text reconstruct documents |
| Conversation history | `DATA_DIR\webui.db` | **High** — includes pasted content |
| WebUI config/accounts | `DATA_DIR\webui.db` | Medium |
| Model files | `%USERPROFILE%\.ollama\models` | Low (public weights) |
| Logs | `%LOCALAPPDATA%\Ollama\*.log`, WebUI console | Low–medium (may contain prompts) |
| Temp files | `%TEMP%` during parsing | Medium — cleaned by OS |

These live on the laptop's NVMe. Recommended: **BitLocker on** for the system
drive (Settings → Privacy & security → Device encryption) so a lost laptop does
not mean lost confidentiality. Backups inherit sensitivity — see docs/11.
Keep Windows user account access restricted (the DATA_DIR is only as private as
the Windows session).

## Privacy verification — what talks to the internet

**Local-only at runtime (inference + documents):**

```
User → Open WebUI (127.0.0.1:8080) → Ollama (127.0.0.1:11434) → local LLM → answer

Document → local parser → local chunking → bge-m3 (local, via Ollama)
        → local ChromaDB → retrieved context → local LLM → answer
```

No document content or prompt leaves the machine on these paths.

**Legitimate external traffic (installation/update only — separate class):**
- `ollama pull` / Ollama installer → ollama.com / registry (model downloads)
- `pip`/`uv` → PyPI (Open WebUI installs/updates)
- Windows Update, driver updates

**Open WebUI phone-home surfaces to disable/verify** (Admin Settings):
- Web Search feature: **keep off** (would send queries to external engines)
- OpenAI-compatible API connections: **none configured** (a configured cloud key
  would route chats externally — this is the hybrid-mode switch, off by default)
- Community/marketplace fetches: avoid importing remote tools/functions
- Update check pings release metadata; acceptable, or set `ENABLE_VERSION_UPDATE_CHECK=false`

**Verification procedure:** with the stack running and a RAG chat in progress, run
`scripts/05-privacy-check.ps1` — it lists listening sockets (must be 127.0.0.1
only) and any established external connections owned by `ollama` /
`open-webui`/`python` processes (must be none during inference).

## Prompt-injection defence

Documents may contain hostile text ("ignore previous instructions…"). Defence
layers: (1) the base system prompt classifies retrieved content as data/evidence,
never instructions (docs/06); (2) no auto-executing tools/functions are installed
in Open WebUI, so injected text has nothing to trigger; (3) treat any answer that
suddenly changes persona or asks to change settings as an injection flag — locate
and quarantine the offending document.

## Boundary summary (Section 34/38)

Never automatically: upload documents to cloud APIs · send prompts to external
models · enable public tunnels · expose Ollama or WebUI beyond localhost ·
sync knowledge DBs externally. A future hybrid mode (cloud model for
non-confidential advanced reasoning) is a **manual, per-task, user-controlled
choice** — a separately configured model connection that is never the default
and never receives confidential collections.
