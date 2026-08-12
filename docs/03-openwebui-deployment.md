# Open WebUI Deployment — Method Decision, Install, Verification

## Deployment method decision (16 GB machine)

| Method | RAM overhead | Verdict |
|---|---|---|
| **Native Python (uv/pip)** | ~0.5–1 GB (WebUI process only) | **Chosen default** |
| Docker Desktop + WSL2 | +1.5–2.5 GB idle (WSL2 VM, vmmem, Docker daemon) | Fallback only; if used, cap WSL2 RAM via `.wslconfig` (`memory=3GB`) and stop Docker when the stack is down |

On a 16 GB laptop the Docker overhead is roughly the cost of an entire second 4B
model. Native wins unless the audit shows Python cannot be installed.

## Install (native, localhost-only)

`scripts/04-install-openwebui.ps1` automates this. Manual equivalent:

```powershell
# Requires Python 3.11 or 3.12 (audit checks this). Then:
pip install uv
# Data lives in %USERPROFILE%\open-webui\data (set DATA_DIR to control it)
$env:DATA_DIR = "$env:USERPROFILE\open-webui\data"
uvx --python 3.12 open-webui@latest serve --host 127.0.0.1 --port 8080
```

**`--host 127.0.0.1` is mandatory** — the default binds 0.0.0.0 (all interfaces,
LAN-visible). Ollama already defaults to 127.0.0.1:11434; leave it that way.

First launch: open **http://localhost:8080**, create the **admin account
immediately** (first signup becomes admin) with a strong password, then in
Admin Panel → Settings disable open signups (`Default User Role: pending` or
disable *Enable New Sign Ups*).

Connect to Ollama: Admin Panel → Settings → Connections → Ollama API =
`http://127.0.0.1:11434` (usually auto-detected).

## Verification checklist (Gate 4)

- [ ] `http://localhost:8080` loads; admin account created; signups closed
- [ ] Ollama connection green; `qwen3:4b` appears in the model selector
- [ ] New chat streams a response; conversation history persists after restart
- [ ] File upload works (any small PDF attaches to a chat)
- [ ] Workspace → Knowledge can create a collection (RAG plumbing present)
- [ ] Arabic prompt renders correctly **RTL** in both the input box and the answer
- [ ] `scripts/05-privacy-check.ps1` shows 8080 and 11434 listening on 127.0.0.1 only

## Service notes

- Stop with Ctrl+C in its console, or `scripts/stop-ai.ps1`.
- `scripts/start-ai.ps1` starts Ollama (if needed) and Open WebUI in a background
  window. Deliberately **not** installed as an auto-start Windows service: heavy AI
  services must not load at every boot on this machine (Section 29 of the master
  prompt). Revisit only if benchmarking proves the impact acceptable.
- Updates: `uvx open-webui@latest` fetches the newest release each launch. For a
  stable, version-pinned setup, pin (`open-webui==0.6.x`) per the update policy in
  `docs/11-backup-updates.md` and upgrade deliberately, not implicitly.
