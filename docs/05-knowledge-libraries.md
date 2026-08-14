# Knowledge Library Structure, Metadata, Version Control

## Principle

One giant knowledge base ruins retrieval precision. Create **separate logical
collections** in Open WebUI (Workspace → Knowledge), and attach only the relevant
collection(s) to each specialized assistant.

## Library structure

Create collections with these names (create on first need — empty collections
help nobody):

```
RE-Signalling          Railway: signalling, ATC, CBTC, interlocking
RE-Communications      Railway: telecom, radio, transmission
RE-RollingStock        Railway: rolling stock
RE-Systems-RAMS        Railway: systems engineering, RAMS, safety
RE-Maintenance-Asset   Railway: maintenance, asset management
RE-Standards           Railway: standards only (EN/IEC/ISO clauses)
PM-Core                Project mgmt: risk, contracts, procurement, cost, schedule, stakeholders
MBA-Core               MBA: AI in business, BI, analytics, strategy, finance, marketing, operations
MBA-Research-Notes     MBA: research papers + course notes
BIZ-Core               Business: strategy, marketing, e-commerce, procurement, ops, CX, product
REF-General            General reference: books, research, manuals, reports
```

Naming convention for files inside collections:
`<Category>_<Title>_<Rev>_<YYYY-MM>.<ext>` — e.g.
`CBTC_SystemRequirements_RevC_2025-11.pdf`. The filename is always retrievable
metadata even when the platform captures nothing else.

## Metadata

Capture where supported (Open WebUI stores filename, upload date, and content;
richer fields go in the filename convention and, for critical documents, a
one-line header added to the document itself):

Title · filename · author · date · version/revision · document type · category ·
subject · section · source. For standards, keep the standard number and year in
the filename (`EN50126-1_2017.pdf`).

## Version control — outdated revisions must not compete with current ones

- **Only the current revision lives in the active collection.**
- Superseded revisions move to an `ARCHIVE-<domain>` collection (or stay out of
  RAG entirely) — never side-by-side with the current one, or the assistant will
  cite them as equally authoritative.
- Keep `knowledge-register.md` (a simple table in your backup folder): filename,
  collection, revision, date ingested, QC result, superseded-by. This is the
  authoritative list of what the assistant knows.
- When revisions differ on a point and both are deliberately loaded (rare,
  comparison tasks only), the assistant must flag the version conflict —
  this rule is in the base system prompt (`docs/06-assistants.md`).
