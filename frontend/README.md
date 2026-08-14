# Local AI Assistant — Custom Frontend

The mockup UI, live: a single-page app in the project's design language (dark
`#0B0D14` ground, violet accent) wired to the real local stack. No Node, no
build step, no dependencies beyond Python — deliberately light for the 16 GB
machine.

```
Browser ── http://127.0.0.1:8090
             │  frontend/server.py  (Python stdlib, loopback-only)
             ├── static SPA (index.html)
             ├── /owui/*    → Open WebUI  127.0.0.1:8080   (models, knowledge, RAG chat)
             ├── /ollama/*  → Ollama      127.0.0.1:11434  (version, loaded models)
             └── /sys/stats → live RAM/CPU via PowerShell CIM
```

## Features (live data, not samples)

- **Home** — knowledge base count, installed models, loaded-in-RAM models,
  free RAM; top knowledge bases; quick actions.
- **Chat** — streaming answers from any Open WebUI model; select a knowledge
  base to get RAG-grounded, citation-instructed answers (`files:[{type:
  "collection"}]`); Arabic/English with correct RTL (`dir="auto"` bubbles).
- **Knowledge Bases** — collections with document counts and per-collection
  file lists (name, date, size).
- **Assistants** — every model/custom assistant published by Open WebUI.
- **Settings** — API key setup + connection test, live system info.
- **Sidebar status card** — Ollama/Open WebUI up-down dots, active model,
  RAM and CPU bars, refreshed every 7 s.

Document upload and knowledge-base administration deliberately stay in Open
WebUI (one backend of truth) — the "Open WebUI" quick action jumps there.

## Run (Gates 1–4 must already pass)

```powershell
# Stack up first:  .\scripts\start-ai.ps1
.\scripts\start-frontend.ps1        # starts server.py + opens the browser
```

First use: in Open WebUI go to **Settings → Account → API keys**, create a
key, paste it into the frontend's **Settings** view, Save & test. The key is
stored only in this browser's localStorage on this machine.

## Security posture

- `server.py` binds **127.0.0.1 only**; the proxy targets are loopback too.
- No external origins, no CDNs, no telemetry; the page is fully self-contained.
- The API key never leaves the machine (browser → loopback proxy → Open WebUI).
- Same rules as the rest of the kit (docs/08): no port forwarding, no tunnels.
