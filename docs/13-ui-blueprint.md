# UI Blueprint — Mapping the "Local AI Assistant" Mockups to the Stack

The two mockup sets (dark theme, purple accent: Home dashboard, chat with cited
sources, Documents, Knowledge Bases, Assistants, Analytics, Settings, Document
Viewer) define the product experience. This doc maps every screen to what the
Ollama + Open WebUI stack delivers **through configuration**, what this kit adds,
and what would require a custom frontend.

## Screen-by-screen mapping

| Mockup screen | Delivered by | How |
|---|---|---|
| **Chat with sources panel** (answer + cited PDFs with page numbers, e.g. "ATC System Architecture.pdf — Page 12") | Open WebUI, native | RAG citations appear under each answer when a Knowledge collection or attached file is used. Assistant prompts (docs/06) force source/section/page naming in the answer text too |
| **Specialized assistants** (Railway Engineer, MBA Tutor, Business Analyst, Project Manager, Research Assistant, Standards Expert) | Open WebUI Workspace → Models | Create each per docs/06: custom name, avatar, system prompt, attached collections. They appear as selectable "assistants" exactly like the mockup's grid |
| **Knowledge Bases grid** (Railway Engineering 1,245 docs · MBA Learning · Business Strategy · Project Management · Standards Library · Research Papers) | Open WebUI Workspace → Knowledge | Create the collections named in docs/05. Each shows document count and can be opened to browse its files |
| **Documents table** (name, type, knowledge base, size, upload date, processed status) | Open WebUI, native | Workspace → Knowledge → collection → file list shows processing status; upload via UI or API |
| **Settings → Models** (active model, temperature, top-p, context length, system info) | Open WebUI, native | Admin → Settings → Models (+ per-model advanced params: num_ctx, temperature…). System info panel: Admin → Settings → About |
| **Settings → RAG** (chunk size, overlap, top-k, embedding model) | Open WebUI, native | Admin → Settings → Documents — set per docs/04 |
| **Home / System Status card** (Ollama running, loaded model, RAM/CPU bars, storage used) | **This kit** | `.\scripts\status.ps1 -Html` renders `reports\dashboard.html` — a dark/purple snapshot dashboard in the mockup's design language with service status, loaded model, RAM/CPU/storage, and knowledge-base shortcuts |
| **Document Viewer** (PDF preview + metadata) | Partially | Open WebUI previews extracted content per file; full PDF page rendering with a metadata sidebar is custom-frontend territory — meanwhile the source citation opens the relevant chunk |
| **Analytics** (conversations over time, top topics, response time, activity heatmap) | **Not in stock Open WebUI** | Basic usage stats exist in the admin panel; the mockup's analytics page would need a custom frontend reading `webui.db` |
| **Greeting/branding** ("Local AI Assistant", "Good morning, Engineer") | Open WebUI, partial | Admin → Settings → Interface: custom name/branding, default prompts. Exact layout is custom |

## Recommendation

Phase 1–6 (all gates): run on Open WebUI configured to mirror the mockups —
same assistant names, same knowledge-base names, same RAG behavior. You get
~85% of the mockup experience with zero custom code, which the master prompt's
"do not over-engineer" rule requires.

**Custom frontend (optional, post-Gate 10):** if the exact mockup UI matters,
the right architecture is a local web app (e.g., Next.js/React, dark/purple
design tokens from the mockups) speaking to **Open WebUI's REST API** (chat,
RAG, knowledge) rather than reimplementing RAG — keeping one backend of truth,
adding the Home dashboard, Analytics page, and Document Viewer the mockups show.
Localhost-only binding and the same security posture (docs/08) would apply.
Treat it as a separate project gate-kept by a working, validated base platform.

Design tokens observed in the mockups (for the dashboard + any future frontend):
background `#0b0d14`, surface `#141726`, border `#23263a`, text `#e6e8f0`,
muted `#8b90a5`, accent violet `#6d5ef2→#8f7cff`, success `#34d399`,
rounded-14px cards, Segoe/system sans.
