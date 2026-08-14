# Backup Strategy & Update Policy

## What to back up (valuable, hard to recreate)

| Data | Location | Priority |
|---|---|---|
| Open WebUI database — config, accounts, **conversation history**, assistant (model) definitions, custom prompts | `DATA_DIR\webui.db` | Critical |
| Uploaded documents | `DATA_DIR\uploads` | Critical (unless originals kept elsewhere) |
| Vector DB | `DATA_DIR\vector_db` | High (rebuildable by re-ingesting, but costly) |
| Knowledge register + test sets | your backup folder | High |
| This repo (scripts/docs/version register) | git remote | Covered |

**Not backed up:** model files (`%USERPROFILE%\.ollama\models`) — replaceable via
`ollama pull`; the model **register** (names + tags) is what you keep, not blobs.

## Procedure

`scripts/backup.ps1` stops nothing (SQLite copy is safe when WebUI is idle — run
it after `stop-ai.ps1` for a guaranteed-consistent copy). It zips `DATA_DIR` +
the version register to `Backups\localai-backup-<date>.zip` under your user
profile (change with `-Destination`). Weekly is a sensible cadence, plus always
**before any update**.

Backups contain confidential documents and chat history — store them on an
encrypted/access-controlled location only (BitLocker-protected drive or encrypted
external disk). Never a public cloud folder by default.

Restore: install same versions from the register → stop stack → replace
`DATA_DIR` contents from the zip → start → verify a chat, an assistant, and one
RAG query.

## Update policy

Never blind-update the whole environment at once.

Before any major update: 1) run backup; 2) record current working versions;
3) read the component's release notes; 4) update **one component at a time**;
5) re-run a mini test: one chat + three RAG questions (incl. one refusal case);
6) roll back if degraded (pin previous version, restore data backup).

Disable/ignore auto-update mechanisms where possible: launch Open WebUI
version-pinned (`uvx open-webui==X.Y.Z serve ...`); update Ollama deliberately
via its installer, not whenever the tray nags.

## Version register (keep current — audit + backup scripts snapshot it)

| Component | Version | Date verified | Notes |
|---|---|---|---|
| Windows 11 build | | | |
| Ollama | | | |
| Open WebUI | | | pinned version |
| LLM default | qwen3:4b @ digest | | `ollama list` shows digests |
| LLM advanced | | | |
| Embedding model | bge-m3 @ digest | | re-index required if changed |
| Python | | | |
| Intel Arc driver | | | |
| Docker/WSL2 | | | only if used |
