# Weekly Scan — June 14, 2026

Repos surveyed: [OpenOats](https://github.com/yazinsai/OpenOats), [QMD](https://github.com/tobi/qmd), [AppFlowy](https://github.com/AppFlowy-IO/AppFlowy), [Exo (mail-app)](https://github.com/ankitvgupta/mail-app)

---

## 1. OpenOats (yazinsai/OpenOats)

**What it is:** Swift-based macOS meeting assistant that transcribes calls locally and surfaces context from a personal knowledge base in real-time. Privacy-first, local-first. 95% Swift.

### Activity (June 7–14)

Low commit activity in the final 7-day window (commits landed May 23 and earlier). 21 PRs were merged May 11–23 covering:

- **Bug fixes (6 PRs):** Microphone capture, menu crashes, timeout handling, button crashes
- **UX polish (6 PRs):** Button heights, tap targets, form alignment
- **Features (6 PRs):** Auto-pause on silence, native OpenAI/Anthropic providers, auto-generated meeting notes, unified home timeline (#589)
- **Maintenance (3 PRs):** Homebrew version bump, workspace consolidation

7 open issues (June 7–12): microphone not recording (#651), silence timeout not stopping (#650), Homebrew cask deprecation (#652), FunASR/SenseVoice transcription request (#644).

### Patterns worth noting

| Pattern | Description | Effort | Impact |
|---------|-------------|--------|--------|
| Multi-provider LLM abstraction | Runtime-swappable providers (Ollama, OpenRouter, OpenAI, Anthropic) without code changes | High | High |
| Unified home timeline | PR #589 consolidated scattered dialogs into a single timeline view | Medium | High |
| Staged suggestion pipeline | Relevance filter gates suggestions before generation to reduce noise/cost | Medium | Medium-High |
| Hierarchical note chunking | 80–500 word chunks split by heading hierarchy, preserving parent-child context | Low-Medium | Medium |
| Knowledge base incremental re-indexing | Only re-embeds changed files; metadata tracks file modifications | Medium | Medium |

### Relevance to Bugbook

The multi-provider LLM pattern and unified timeline are directly applicable. OpenOats' approach to chunking by heading hierarchy aligns well with Bugbook's markdown-based row files. The staged suggestion pipeline (score relevance before surfacing) could improve AI-suggested backlinks or related notes.

---

## 2. QMD (tobi/qmd)

**What it is:** Local CLI search engine for personal knowledge bases. Combines BM25 full-text search, vector semantic search, and LLM-based reranking. All on-device using GGUF models. TypeScript (82%) + Python (14%).

> **Note:** QMD is an upstream dependency for Bugbook — search and indexing are delegated to it. Changes here are NOT Bugbook code changes.

### Activity (June 7–14)

2 commits merged (June 7–8) for CLI reference and MCP parameter documentation. 10 open PRs with significant momentum, 5 updated June 13–14.

**Key open PRs:**

| PR | Title | Status | Bugbook relevance |
|----|-------|--------|-------------------|
| #734 | Fix MCP idle session cleanup (TTL + connection caps) | Open | **High** — prevents resource leaks in long-running agent integrations |
| #733 | Make node-llama-cpp optional dependency | Open | **Medium** — improves macOS Apple Silicon install reliability |
| #732 | SQLite busy_timeout optimization | Open | **Medium** — reduces contention on concurrent index access |
| #731 | Expose `--plain` query parameter via MCP | Open | **Medium** — skip query expansion when Bugbook preprocesses queries |
| #730 | Expose `--explain` for retrieval scores | Open | **High** — enables Bugbook to surface ranking rationale in search UI |
| #629 | Remote embedding/reranking support (vLLM, Ollama) | Open | **Medium** — offload LLM work on resource-constrained machines |

**Open issues (7):** Embedding timeout for large collections (#724), npm install failures on Apple Silicon (#699), path normalization with spaces (#717).

### Upstream watch items

- **PR #734 (session cleanup):** Critical if Bugbook uses QMD's MCP server for agent search — without it, sessions accumulate unbounded.
- **PR #730 (`--explain`):** Once merged, Bugbook can surface search confidence scores in the UI — a Bugbook-side code change, not upstream.
- **PR #733 (optional deps):** Improves first-run experience for Bugbook users installing QMD.

---

## 3. AppFlowy (AppFlowy-IO/AppFlowy)

**What it is:** Open-source Notion alternative. Flutter (frontend) + Rust (backend). Mature product with database views, block editor, real-time collaboration, and AI features. v0.12.2 shipped June 5, 2026.

### Activity (June 7–14)

Moderate-to-steady activity focused on quality polish:

- Autofill hints for text inputs (accessibility)
- UI polish: toast components, dialogs, padding refinements
- Mobile feature parity improvements
- Internationalization updates (Italian, French)

**v0.12.2 notable features (shipped June 5):**
- Kanban column coloring with customization
- Inline comments in database row pages
- Property visibility controls ("hide when empty", "hide all")
- Linked view management
- Formula and rollup property filtering
- Document version history (restore previous versions)
- Page-level references and mentions

**Active PRs (71 open):** Row children/nesting, gallery view controls, Notion-like drag-and-copy, full-width page layouts, favorites functionality.

**Recent issues:** Currency formatting corruption, Android filter sync failures, Notion ZIP import issues, comment synchronization delays, Ctrl-F search failures.

### Patterns worth noting

| Pattern | Description | Effort | Impact |
|---------|-------------|--------|--------|
| Property visibility toggles | "Hide when empty" / "always hide" per property in views | Low | High |
| Kanban column coloring | Custom colors per select option, reflected in board columns | Low | Medium |
| Inline comment threads on rows | Contextual discussion threads inside database row detail views | Medium | High |
| Document version history | Restore previous versions of pages | Medium | High |
| Mention/cross-reference system | @-mention rows and pages, creating bidirectional links | Medium | High |
| Multi-view linked databases | Same database rendered in multiple views, each with own filters/sorts | Medium | Medium |

### Relevance to Bugbook

AppFlowy's v0.12.2 is the most directly relevant release. Property visibility controls and kanban column coloring are low-effort, high-polish features that map directly to Bugbook's existing `ViewConfig` and `PropertyDefinition` types. Inline comment threads could power agent collaboration — agents leave threaded comments on rows they're working on. The mention system enables `[[page]]`-style linking that Bugbook's markdown editor could adopt.

**Architecture risk insight:** AppFlowy is still fixing comment sync and cursor preservation issues. This suggests investing heavily in sync test infrastructure if Bugbook adds real-time collaboration.

---

## 4. Exo / mail-app (ankitvgupta/mail-app)

**What it is:** Open-source AI-native desktop email client. "Claude Code for your Inbox." Electron + React + TypeScript. Deeply integrates Claude AI into email workflows.

### Activity (June 7–14)

- **June 12:** Test fixture correction for reminder service
- **May 27–29:** Search context handling fix, OpenCode agent provider integration, search fan-out fix

**Open PRs (4):**

| PR | Title | Impact |
|----|-------|--------|
| #172 | Gmail filter reliability (retry transient 500s) | Stability |
| #171 | Split tab keyboard shortcut (Superhuman parity) | UX |
| #173 | Agentic verification testing | QA |
| #166 | Model picker dropdown + Ollama validation | Flexibility |

### Patterns worth noting

| Pattern | Description | Effort | Impact |
|---------|-------------|--------|--------|
| Command palette (Cmd+K) | Quick action discovery and execution from keyboard | Medium | High |
| SQLite FTS5 local search | Full-text search with offline-first capability | Medium | High |
| MCP server for knowledge retrieval | Expose app data to AI agents via MCP protocol | Medium | High |
| Optimistic UI with universal undo | Instant feedback on mutations, undo stack for safety | Medium | High |
| Sidebar agent panel | Contextual AI suggestions, backlinks, metadata in sidebar | Medium | Medium |
| Density settings | Comfortable/default/compact display modes | Low | Medium |
| Style learning | System learns user preferences for AI-generated content | Low | Low-Medium |

### Relevance to Bugbook

Exo's command palette (Cmd+K) is the standout pattern. Bugbook's SwiftUI app could implement a similar overlay for quick navigation (jump to database, search rows, create new entry, switch views) — a single keystroke to access any action. The MCP server pattern is also relevant: Bugbook could expose its databases via MCP so external agents (Claude Code, etc.) can query the knowledge base without going through the CLI.

The optimistic UI pattern (mutation appears instantly, undo available) would improve Bugbook's inline cell editing feel, particularly for kanban drag-and-drop and table property changes.

---

## Top 3 This Week

These are the three highest-impact, lowest-effort changes to Bugbook's own codebase.

### 1. Add property visibility controls to database views

**Why:** AppFlowy v0.12.2 shipped "hide when empty" and "always hide" per-property toggles. Bugbook's table views can get cluttered when many properties are empty. This is a small schema extension + SwiftUI view change.

**What changes:** Add a `visibility` field to `ViewConfig.hidden_columns` (or a new `column_visibility` map) supporting `visible`, `hide_when_empty`, and `always_hide` states. Update the table/kanban/list views to filter columns accordingly. Update the CLI `query` command to respect visibility in `--format text` output.

**Effort:** Low — extends existing `ViewConfig` type, minimal UI work  
**Impact:** High — immediately declutters views for power users with many properties

### 2. Add a command palette (Cmd+K) to the SwiftUI desktop app

**Why:** Exo's Cmd+K palette is the fastest way to navigate a complex app. Bugbook has databases, rows, views, pages — a palette lets users jump to any of them in two keystrokes. Every major productivity app ships one.

**What changes:** Add a `CommandPaletteView` overlay triggered by Cmd+K. Index databases, recent rows, views, and actions (create row, switch view, open settings). Use fuzzy matching on titles. Wire to `DatabaseStore.listDatabases()` and `QueryEngine` for search.

**Effort:** Medium — new SwiftUI view + fuzzy matching logic, but no core engine changes  
**Impact:** High — transforms navigation speed for power users

### 3. Add kanban column color customization

**Why:** AppFlowy v0.12.2 added column coloring to kanban boards. Bugbook already stores `color` in select option configs (`_schema.json`), but the kanban view likely doesn't use them yet. This is mostly a SwiftUI rendering change.

**What changes:** In the kanban board view, read the `color` field from the `group_by` property's select options and apply it as the column header background/accent. Optionally add a color picker in the schema editor for select options.

**Effort:** Low — the data model already supports colors; this is a view-layer change  
**Impact:** Medium — visual polish that makes boards more scannable and personalized

---

## Proposed Tickets

### Ticket 1: Add property visibility controls to database views

**Title:** Add "hide when empty" and "always hide" property visibility to views

**Description:** Extend `ViewConfig` in `Schema.swift` to support per-property visibility states beyond the current binary `hidden_columns` list. Add three states: `visible` (default), `hide_when_empty` (only show column if at least one visible row has a non-empty value), and `always_hide` (never render). Update `DatabaseViewModel.refresh()` to compute visible columns based on the active view's visibility settings and current query results. Update the table view column header to include a visibility toggle in the column context menu. This is inspired by AppFlowy v0.12.2's property visibility controls, which significantly reduce visual clutter in databases with many optional properties.

**Effort:** Low

**Source:** [AppFlowy v0.12.2 release](https://github.com/AppFlowy-IO/AppFlowy/releases) — property visibility controls ("hide when empty", "hide all")

---

### Ticket 2: Add command palette (Cmd+K) to desktop app

**Title:** Add Cmd+K command palette for quick navigation and actions

**Description:** Create a `CommandPaletteView` SwiftUI overlay that appears on Cmd+K (or Cmd+P) and provides fuzzy-matched access to: all databases (via `DatabaseStore.listDatabases()`), recently accessed rows (track in a local recents list), all named views across databases, and quick actions (create row, switch view, open settings). Use a simple substring/fuzzy match on display names. Dismiss on Escape or selection. This is a standard productivity pattern used by Exo, Raycast, VS Code, and Notion. It dramatically reduces navigation friction in apps with many entities.

**Effort:** Medium

**Source:** [Exo (ankitvgupta/mail-app)](https://github.com/ankitvgupta/mail-app) — Cmd+K command palette for action discovery and keyboard-driven navigation

---

### Ticket 3: Render kanban column colors from select option config

**Title:** Apply select option colors to kanban board column headers

**Description:** Bugbook's `_schema.json` already stores a `color` field on each select option (e.g., `"color": "blue"` for "Todo", `"color": "yellow"` for "In Progress"). The kanban board view should read the `color` from the `group_by` property's options and render it as the column header background or accent bar. Map the color names to SwiftUI `Color` values (a simple string-to-color dictionary). This is a view-only change — no model or engine modifications needed. Inspired by AppFlowy v0.12.2's kanban column coloring feature.

**Effort:** Low

**Source:** [AppFlowy v0.12.2](https://github.com/AppFlowy-IO/AppFlowy/releases) — kanban board column coloring with customization
