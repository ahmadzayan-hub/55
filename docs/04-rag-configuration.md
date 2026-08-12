# RAG Configuration — Embeddings, Chunking, Retrieval, Document QC, Ingestion

## Embedding model selection (Phase 4)

Requirement: local-only, English + Arabic + mixed + technical terminology,
lightweight, Open WebUI-compatible.

| Candidate | Size | Multilingual | Verdict |
|---|---|---|---|
| **bge-m3** (Ollama) | ~1.2 GB, 1024-dim, 8K input | Excellent, 100+ languages incl. Arabic | **Selected** |
| paraphrase-multilingual (MiniLM) | ~120 MB | Decent, weaker on technical text | Fallback if RAM-starved |
| snowflake-arctic-embed2 | ~1.2 GB | Strong but Arabic coverage weaker than bge-m3 | Not selected |
| nomic-embed-text | ~270 MB | English-focused | Rejected (Arabic requirement) |
| Cloud APIs (OpenAI etc.) | — | — | **Rejected — violates local-only principle** |

Install **only** the selected model:

```powershell
ollama pull bge-m3
```

Open WebUI: Admin Panel → Settings → Documents:
- Embedding Model Engine: **Ollama**
- Embedding Model: **bge-m3**
- (Set this **before** ingesting documents — changing the embedding model later
  requires re-indexing every knowledge base.)

Vector store: Open WebUI's built-in **ChromaDB** inside `DATA_DIR\vector_db`.
No separate database server — do not over-engineer.

## Retrieval settings — conservative start, tune experimentally

| Setting | Start | Tuning notes |
|---|---|---|
| Chunk size | **800** tokens | 500–1000 band. Smaller = precision, larger = context continuity. Standards/clauses → smaller (500–600); textbooks → larger (~1000) |
| Chunk overlap | **100** | Keep ~10–15% of chunk size |
| Top K | **5** | Raise to 8–10 for multi-section questions if context budget (8K) allows |
| Hybrid search (BM25 + vector) | **On** | Materially helps exact technical terms, clause numbers, acronyms (CBTC, ATC, EN 50126) |
| Reranker | Off initially | CPU cost; add only if Gate 6 precision is inadequate |
| Full-context mode | Off | Defeats retrieval; 16 GB cannot afford whole-document stuffing |

Change **one parameter at a time** and re-run the Gate 6 test set — defaults are
not assumed optimal, and neither is any single tweak.

## Document types

Supported via Open WebUI's extraction pipeline: PDF, DOCX, PPTX, XLSX, CSV, TXT,
Markdown. **Scanned PDFs**: extraction yields nothing without OCR. OCR is optional
and deliberate (resource-heavy): pre-process scanned files externally (e.g.,
`ocrmypdf --language ara+eng in.pdf out.pdf`) and upload the OCR'd copy. Never
bulk-OCR by default.

## Document quality control — mandatory per document

**Never assume a successfully uploaded file was correctly parsed.**

After each upload:
1. Open the document inside the knowledge collection and inspect the extracted
   text (or ask the model: *"Quote the first heading and the table of contents of
   <file> verbatim."*).
2. Check: title preserved · headings detected · tables still understandable ·
   page references available · Arabic extracted correctly (no reversed/disjointed
   letters, no mojibake) · English correct · mixed-language passages readable ·
   technical symbols/units intact.
3. Probe retrieval: ask one question whose answer you know sits in a specific
   section; verify the right chunk is cited.
4. **Failures:** flag the file, remove it from the collection, fix at source
   (re-export from Word, re-print to PDF, OCR, or convert to DOCX/Markdown) and
   re-ingest. A silently bad parse is worse than a missing document — it produces
   confident garbage.

Common Arabic-PDF failure: text extracts as isolated/reversed glyphs (legacy
encodings, missing ToUnicode maps). Fix at source; re-exporting to DOCX or
printing to a fresh PDF usually repairs it.

## Large-document / bulk ingestion strategy

Do not upload hundreds of PDFs blindly.

- **Classify first** into the library structure (`docs/05-knowledge-libraries.md`).
- **Deduplicate** before upload (same content, different filename).
- **Version-check**: only the current revision goes in the active collection
  (supersede workflow in docs/05).
- **Batches of ≤ 10–15 files**, QC each batch before the next; watch RAM/CPU
  during indexing (embedding runs locally and is CPU-bound).
- **Big textbooks/manuals**: split by chapter before upload where practical —
  preserves chapter/section boundaries, improves attribution, keeps chunks
  coherent. Standards: keep clause structure (smaller chunks). Technical manuals:
  split per equipment/subsystem so retrieval keeps context.
