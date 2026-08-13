# UI Generation Prompt — for AI UI tools (v0, Lovable, Bolt, Figma Make…)

Paste the prompt below into an AI UI-generation tool to produce the Local AI
Assistant frontend. It encodes the product description, the design system from
the project mockups (see `docs/13-ui-blueprint.md`), and every screen.

---

## PROMPT: "Local AI Assistant" — Private Knowledge Dashboard UI

### Product description

Build the complete user interface for **Local AI Assistant** — a private,
fully offline AI knowledge workspace that runs on a user's Windows laptop.
It is the frontend for a local AI stack (Ollama running a local LLM such as
qwen3:4b, with retrieval-augmented generation over the user's own document
libraries). Nothing leaves the machine: no cloud, no telemetry. The user is a
railway engineer and MBA student who queries technical documents (PDF, DOCX,
PPTX, XLSX, TXT, Markdown) in **both English and Arabic**.

The product's personality: calm, technical, trustworthy, private. It should
feel like a polished native Windows productivity app, not a flashy SaaS
landing page.

### Design system

- **Theme:** dark only.
- **Colors:** background `#0B0D14`; sidebar `#0D101B`; card surface `#141726`;
  raised surface `#1A1E30`; borders `#23263A`; primary text `#E6E8F0`; muted
  text `#8B90A5`; accent gradient violet `#6D5EF2 → #8F7CFF` (buttons, active
  states, progress bars); success green `#34D399` (status dots, "Processed"
  pills); warning amber `#FBBF24`; chip background `#1D2032` with border
  `#2B2F47`.
- **Typography:** Segoe UI / system sans. Page titles ~22px semibold; card
  titles 14px semibold; body 13–14px; section labels 11px uppercase with
  letter-spacing; numbers use tabular figures.
- **Shape & spacing:** cards with 13px radius and 1px border; 12px gaps in
  grids; pill-shaped chips and status badges; soft violet gradient on primary
  buttons.
- **Iconography:** thin-line 16px icons in nav; rounded-square colored glyph
  tiles (36–38px) for knowledge bases and assistants, each with its own tinted
  background (green for Railway, violet for MBA, amber for Business Strategy,
  cyan for Project Management, pink for Standards).
- **RTL support is mandatory:** Arabic text in chat must render right-to-left
  correctly; the layout must tolerate mixed Arabic/English content.

### App shell

Fixed left sidebar (~220px), content area to the right. Sidebar contains, top
to bottom:

1. Logo (violet gradient rounded square with "AI") + product name "Local AI
   Assistant" + tagline "Private AI knowledge hub".
2. Prominent violet-gradient "**+ New Chat**" button.
3. Nav items: Home, Chats, Knowledge Bases, Documents, Assistants, Tools,
   Analytics, Settings (active item gets a filled dark pill).
4. A "Recent chats" list (chat titles with timestamps).
5. Pinned at bottom: a **System Status mini-card** — Ollama ● Running,
   Open WebUI ● Running, model name (qwen3:4b), "RAM 8.2 / 16 GB" with a
   violet progress bar, CPU %.
6. User row: avatar, name "Engineer", subtitle "● Local Mode".

### Screens

**1. Home dashboard** — Greeting "Good morning, Engineer 👋" with subtitle
"Your private AI workspace". Row of four stat cards: Knowledge Bases (12
active), Documents (2,458), Conversations (156 this week), Storage Used
(82.4 GB). Two-column section: "Recent Conversations" list (icon, title,
last-message preview, relative timestamp) beside a "Quick Actions" grid
(Upload Document, New Chat, Create Assistant, Knowledge Base, System
Settings). Below: "Top Knowledge Bases" horizontal cards (name, doc count,
glyph). Include the System Status panel with RAM/CPU bars.

**2. Chat** — Header: assistant name "Railway Engineering Assistant",
subtitle "Specialized in Railway Systems & Engineering". Left panel:
collapsible chat history grouped by Today / Yesterday / Previous 7 Days.
Center: conversation thread — user messages in violet gradient bubbles
right-aligned; assistant answers in dark surface bubbles left-aligned with
markdown (numbered headings, bullet lists). Under each answer: **source
citation chips** (small PDF icon + filename + page, e.g.
"ATC_System_Architecture.pdf · Page 12"). Right panel: "Sources" card listing
cited PDFs with page numbers, and "Related Topics" card with clickable links
(Signal Systems, Train Detection, Safety Integrity Level…). Bottom: message
composer with attachment and image buttons and a violet send button.

**3. Knowledge Bases** — Grid of cards, one per library: glyph, name,
document count, size, "Updated 2h ago". Libraries: Railway Engineering, MBA
Learning, Business Strategy, Project Management, Standards Library, Research
Papers, General Reference. A "**+ Create Knowledge Base**" primary button
top-right. Detail view for one knowledge base: overview tab with description,
topic chips (Signalling, ATC, CBTC, Communications…), a donut chart of
document types (PDF 45%, DOCX 20%, PPTX 15%, XLSX 10%, TXT 5%), recent
documents row, and tabs for Documents / Chunks / Analytics / Settings.

**4. Documents** — Toolbar with search field, file-type filter chips (All,
PDF, DOCX, PPTX, XLSX, TXT, MD), and "**⬆ Upload Document**" button. Table
with columns: Name (with colored file-type badge), Type, Knowledge Base,
Size, Uploaded date, Status (green "Processed" pill; also design
"Processing" amber and "Failed" red states). Sample rows: ATC System
Architecture.pdf 2.4 MB · CBTC Technical Manual.pdf 5.7 MB · Risk Assessment
Report.docx 1.2 MB · MBA Strategy Framework.pptx 3.1 MB · Market
Analysis.xlsx 2.8 MB · Communication Systems.md 890 KB.

**5. Assistants** — Grid of assistant cards: glyph, name, one-line
description, linked knowledge base + doc count. Six assistants: Railway
Engineer ("Specialized in railway systems, signalling and ATC"), MBA Tutor
("Concepts, case studies and practice questions"), Business Analyst
("Strategy, market analysis, executive decision support"), Project Manager
("Risk, contracts, procurement, schedule"), Research Assistant ("Papers,
analysis, documentation"), Standards Expert ("Standards, regulations and
compliance"). Tabs: My Assistants / Templates. "**+ Create Assistant**"
button.

**6. Analytics** — Stat row: Total Conversations 1,234 (+12%), Documents
Processed 89 (+8.2%), Questions Asked 2,456 (+3.4%), Avg Response Time 2.3s
(−8.7%). A line/area chart "Conversations over time"; a horizontal bar list
"Top Topics" (ATC Systems 28%, Signalling 24%, Maintenance 18%, Safety 15%,
Standards 15%); "Most Used Knowledge Bases" bars; a weekly activity heatmap
grid.

**7. Settings** — Tabs: General / Models / RAG Settings / Interface /
Security / System. Models tab: active model card (qwen3:4b, "Change Model"
button), parameter sliders (Temperature 0.7, Top P 0.9, Context Length 8192),
and a read-only System Information panel (Windows 11, Intel Core Ultra 7
155H, 16 GB RAM, Intel Arc GPU, Ollama version, storage: Models 8.2 GB /
Documents 12.4 GB / Total 20.6 GB). RAG Settings tab: chunk size, overlap,
top-K, embedding model (bge-m3), hybrid search toggle.

**8. Document Viewer** — PDF page preview center (with page navigation
"12 / 45", zoom controls), right sidebar with Document Info (filename,
knowledge base, upload date, size, status), tags chips, and Related
Documents list.

### Behavior & quality bar

- Fully responsive; sidebar collapses on narrow widths.
- Interactive states: hover on cards/nav, visible keyboard focus, loading
  skeletons for chat and tables.
- All numbers and content above are realistic sample data — use them verbatim
  so the design reads as a real product.
- No cloud branding, no login screens with third-party providers — this is a
  local, single-user, private app.
