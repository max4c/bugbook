# Weekly Research Scan — 2026-05-24

Repos monitored: **OpenOats**, **QMD**, **AppFlowy**, **Exo (mail-app)**
Period: May 17–24, 2026

---

## 1. OpenOats (yazinsai/OpenOats)

> Native macOS (Swift/SwiftUI) meeting note-taker with on-device WhisperKit transcription, local knowledge-base search via embeddings, and LLM-powered suggestions. 2.4k stars, MIT.

### Activity: Moderate (12 commits, 6 merged PRs, 3 issues)

| PR | What shipped | Why it matters |
|----|-------------|----------------|
| #640 | **Retry silent mic capture on startup** — fixes first-launch audio silence | Resilient hardware initialization pattern |
| #628 | **Auto-pause after long silence** — 5-minute threshold, 0.01 audio level | Activity-based lifecycle management |
| #637 | Fix template creation form layout (pulled from grouped Form) | SwiftUI `Form(.grouped)` constrains child layouts — pull editors out for full width |
| #636 | Remove duplicate Ollama model picker chevron | Native picker already renders disclosure; don't double it |
| #635 | Expand advanced detection settings tap target | Full-row tappable areas for settings |
| #639 | Match Clean Up toolbar button height to adjacent controls | `.frame()` or `.controlSize()` alignment in toolbars |

**Notable commit:** `759e17e` — **Native OpenAI and Anthropic providers** added alongside OpenRouter/Ollama/MLX. Introduced `CompletionTransport` enum (`.chatCompletions` vs `.anthropicMessages`) so each engine reads `activeLLMApiKey`/`activeLLMBaseURL`/`activeLLMTransport` without knowing the provider.

### Patterns worth adapting for Bugbook

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Markdown chunking with header breadcrumbs** | `chunkMarkdownStatic` splits on headings, tracks hierarchy as breadcrumbs (e.g., "Sales > Pricing > Enterprise"), merges small sections (<80 words), splits large ones (>500 words) with 20% overlap. Preserves `relativePath`, `folderBreadcrumb`, `documentTitle` per chunk. | Low | High |
| **Content-hash cache invalidation** | `filename:sha256hash` keys for embeddings. Only re-embeds changed files. `embeddingConfigFingerprint()` invalidates the full cache when provider/model changes. | Low | Med |
| **vDSP-accelerated vector search** | Pre-normalizes embeddings at index time; search is a single `vDSP_dotpr` call per chunk via Apple Accelerate. Multi-query score fusion (1–4 variants, max cosine per chunk). | Med | High |
| **Context packs with sibling text** | `searchContextPacks` returns matched text + previous/next sibling chunks from the same file. Richer context without embedding extra text. | Trivial | Med |
| **Multi-provider LLM abstraction** | `LLMProvider` enum + `CompletionTransport` + computed accessors on `AppSettings`. New providers require only enum cases and settings fields. | Med | High |
| **Template resolution hierarchy** | Explicit session → family event preference → family history → global default → session fallback → generic. Deterministic UUIDs for built-ins. | Low | Med |

---

## 2. QMD (tobi/qmd)

> On-device hybrid search engine for markdown files. BM25 (FTS5), vector similarity (sqlite-vec), and LLM reranking — all local via GGUF models. 25.5k stars, MIT. By Tobi Lütke.

### Activity: Very High (20+ commits, 3 releases: v2.5.0–v2.5.2)

| Release / PR | What shipped | Why it matters |
|-------------|-------------|----------------|
| **v2.5.0** (May 19) | **`qmd doctor`** — index health diagnostics: SQLite/sqlite-vec versions, embedding fingerprint freshness, mixed-fingerprint detection, vector health checks | Self-diagnosing search infrastructure |
| **v2.5.0** | **`qmd skills`** — serve QMD skill instructions from CLI for agents | Agent-accessible skill metadata |
| v2.5.1 (May 20) | npm trusted publishing via OIDC | Publishing infra |
| v2.5.2 (May 22) | Shebang polyglot launcher for Windows + Unix + Bun fallback | Cross-platform execution |
| PR #665 (open) | **Path filtering + explain metadata** — `pathPrefix` param for folder-scoped search, `original_path` for roundtrip fidelity, `explain.scoreType`/`explain.backendSources` | Directly enables folder-scoped search in PKM apps |
| PR #669 (open) | **Title-match boost in hybrid search** — capped boost for lookup-style queries | Improves "find my note about X" workflows |
| PR #663 (open) | **`qmd serve`** — shared HTTP model server with `/embed`, `/rerank`, `/expand`, `/vsearch`, `/search` endpoints | Enables Swift apps to call QMD via HTTP instead of shelling out |
| PR #662 (open) | **`--low-vram` mode** — disposes heavy models after use, keeps only embedding model (~320MB) resident. ~3–5s latency per stage | QMD coexists with other apps on constrained Macs |
| PR #575 (open) | **Remote OpenAI-compatible embeddings** — `RemoteLLM` class with circuit breakers, Bearer auth, env var activation | Cloud fallback for users without GPUs or on iOS |

**Notable issues:** #674 Metal crash on exit (Node v26, macOS/Apple Silicon), #673 hardcoded 30-min session maxDuration aborts large-corpus embeddings, #671 scope `qmd update` to a single collection with `-c`.

### Patterns worth adapting for Bugbook

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Index health diagnostics** | `qmd doctor` reports SQLite/sqlite-vec versions, embedding freshness, mixed fingerprints. Bugbook analog: detect stale `_index.json`, orphaned row files, schema mismatches. | Low | Med |
| **Path-scoped search** (PR #665) | `pathPrefix` parameter limits search to a subfolder. Bugbook analog: scope search to a specific database folder. | Low | High |
| **Title-match boost** (PR #669) | Capped boost for exact/partial title matches before final scoring. Bugbook: weight `prop_title` matches higher in search results. | Low | High |
| **Shared model server** (PR #663) | HTTP endpoints replace CLI subprocess calls. Bugbook: Swift `URLSession` to QMD instead of `Process()`. | Med | High |
| **Graceful degradation** | If sqlite-vec is unavailable, BM25/FTS still works. Bugbook: if QMD isn't installed, fall back to basic index-based filtering. | Low | Med |
| **Collection context metadata** | Per-folder semantic hints (e.g., "engineering meeting notes") injected into search without modifying notes. | Low | Med |

---

## 3. AppFlowy (AppFlowy-IO/AppFlowy)

> Open-source AI-powered collaborative workspace (Flutter + Rust), 71.2k stars. Notion alternative emphasizing data privacy and local-first architecture.

### Activity: Moderate (v0.11.9 released May 12, 15+ issues filed this week)

Development happens on release branches, not `main`. Active issue filing continues.

**v0.11.9 highlights:**
- **Database search** — quick row search across database views
- **Relative date filters** — "today", "this week", "last 30 days" for date fields
- **Cached view loading** — lazy hydration, incremental sort, cached database views
- Relation picker sorted by recency; create page from relation
- "Hide all properties" button in database settings
- Hide-when-empty property visibility option in row detail
- Copy date cell value to clipboard from grid
- Space reordering via drag-and-drop in sidebar
- Mobile: workspace backup export/import

**Notable new issues this week:**

| Issue | Title | Bugbook relevance |
|-------|-------|-------------------|
| #8754 | Calendar does not support changing month for year-wide planning | **High** — build calendar with proper date-range navigation from the start |
| #8751 | Support expanding/collapsing toggle list in read-only mode | **High** — toggle/outline behavior in read mode |
| #8749 | Support reordering multiple blocks | **High** — multi-block drag/reorder |
| #8747 | Table minimum column size is way too high | **High** — table column sizing UX |
| #8746 | Changing from multiselect to text should keep content | **High** — field type conversion must preserve data |
| #8743 | Keyboard overlaps toolbar on mobile | **High** — classic iOS keyboard avoidance |
| #8739 | v0.11.9 unable to import MD files | **High** — markdown import regression |

### Patterns worth adapting for Bugbook

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Relative date filters** | "today", "this week", "last 30 days", "next 7 days" as date filter predicates. Pure date math on YAML frontmatter dates. | **Low** | **High** |
| **Database search within views** | Quick full-text search across rows in the current database view. Leverage existing reverse index. | **Low** | **High** |
| **Cached view loading** | Cache computed database view results (filtered/sorted/grouped) and invalidate only on file changes. | Med | High |
| **Hide empty groups** | Auto-collapse empty columns in kanban views. Simple UI toggle. | **Low** | Med |
| **View-as-metadata-on-shared-data** | All view types share one database with independent view configs. Views are projections, not copies. | Already done | — |
| **Per-field-type group controllers** | Group-by logic dispatches to type-specific handlers (group by status vs. date vs. select). | Med | Med |
| **Field type conversion with data preservation** | When changing a property type (e.g., multi_select → text), keep the underlying data and convert format. | Med | Med |
| **Calendar year-level navigation** | Build date-range navigation (month/year) into calendar view from the start, not just week/month toggle. | Low | Med |

---

## 4. Exo (ankitvgupta/mail-app)

> "Claude Code for your Inbox" — open-source AI-native desktop email client. Electron + React + TypeScript + SQLite. 431 stars, BSL-1.1. By Ankit Gupta.

### Activity: Very High (22 commits, 16 merged PRs, 4 issues)

| PR | What shipped | Why it matters |
|----|-------------|----------------|
| #141 | **One-click block-sender** — Gmail filter API + local DB + undo toast | Full destructive-action UX pattern: execute → show toast → 5s undo window → commit |
| #117 | **Send & Archive toggle** — single action to reply + archive | Compound action pattern reduces clicks |
| #144 (open) | **Binary triage** — collapse H/M/L priority into Priority/Other | 63 files changed, 821 deletions. Fewer choices = faster decisions |
| #145 (open) | **Unified inbox** — multi-account view via `currentAccountId === null` sentinel | `null` = "all" is a clean pattern for multi-collection views |
| #123 | **Agentic testing suite** — Claude Agent SDK drives live Electron app via chrome-devtools MCP | AI agent runs end-to-end verification of the actual application |
| #134 | **Pre-PR agentic-verify report** — upsert PR comment with full test results | Automated quality gate before review |
| #146 | **Preserve list focus on Esc back** from full-view email | Keyboard-first UX: focus state must survive navigation |
| #133 | **WCAG AA contrast** for inbox text | Accessibility compliance |
| #137 | **Accessible names** on icon buttons and selects | `aria-label` on every interactive element |
| #132 | **LLM eval errors surfaced distinctly** — don't cook midpoint scores on judge failures | Eval reliability improvement |
| #89 | Fix broken reply icon SVG + improve inline action buttons | Community contribution |
| #93 | Fix Settings panel responsive layout | Community contribution |

### Patterns worth adapting for Bugbook

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Keyboard-first navigation (j/k + Cmd+K)** | Vim-style j/k row navigation, Cmd+K command palette for page/database switching, Tab cycling, batch selection. | **Low** | **High** |
| **Undo toast for destructive ops** | 5-second deferred-commit: execute optimistically → show toast with undo → commit on timeout. Used for send, archive, block, delete. | **Low** | **High** |
| **Binary triage** (PR #144) | Simplify from 3+ priority levels to 2 states for faster triage. 821 lines deleted. Applicable to any multi-level status/priority system. | **Low** | Med |
| **Two-tier memory system** | `memories` table (explicit user directives, editable) + `draft_memories` (auto-learned observations, confidence voting). Bugbook: learn categorization preferences, auto-tagging patterns, view defaults. | Med | High |
| **Permission gate for agent actions** | Require approval before AI agents perform write operations. Every tool call logged to `agent_audit_log` with redaction. | Med | High |
| **Centralized AI service with cost tracking** | Single `AnthropicService` routes all LLM calls. Exponential backoff, per-call cost tracking, caller attribution, AbortController timeouts, test injection. | Med | High |
| **Agent worker thread isolation** | AI agent operations run in worker threads, not the main thread. Prevents UI blocking during long operations. | High | High |
| **Numbered migration system** | Array of versioned migrations with transactional execution and version bookkeeping in `schema_version` table. | Low | Med |
| **Unified multi-source view** | `currentAccountId === null` sentinel means "show all". Clean pattern for a unified view across all databases. | Low | Med |

---

## Top 3 This Week

### 1. Relative Date Filters for Database Views (from AppFlowy v0.11.9)
**Effort: Low | Impact: High**

Add relative date predicates — `today`, `yesterday`, `this_week`, `last_7_days`, `last_30_days`, `next_7_days` — to Bugbook's `Filter` enum and `QueryEngine`. Currently, date filters require absolute `YYYY-MM-DD` values (`due<2026-03-01`). Relative dates make saved views evergreen: a "Due This Week" kanban column stays useful without manual date editing. Implementation is pure date math in `QueryEngine.swift` — compute the date range at query time, compare against the existing date properties in the index. No schema changes, no new storage, no dependencies.

### 2. Keyboard-First Navigation with Cmd+K Palette (from Exo)
**Effort: Low | Impact: High**

Add j/k row navigation in table and list views, plus a Cmd+K command palette for switching between databases and pages. PKM power users expect keyboard-driven workflows. SwiftUI's `.onKeyPress` (macOS 14+) and `.focusable()` make j/k navigation straightforward. The Cmd+K palette is a filtered list overlay — type to filter, Enter to navigate, Esc to dismiss. Exo's implementation proves this is one of the highest-leverage UX investments for a productivity tool. Start with database views; extend to page navigation and agent commands later.

### 3. Undo Toast for Destructive Operations (from Exo PR #141)
**Effort: Low | Impact: High**

When deleting rows, archiving notes, or performing other destructive operations, show a toast with a 5-second undo window before committing the change. Exo uses this pattern for send, archive, block-sender, and delete — the action executes optimistically in the UI, a toast appears with an Undo button, and the actual file/index write happens only after the timeout. In Bugbook, this means `MutationEngine.execute()` gets a deferred mode: the UI updates immediately, a `ScheduledMutation` is held in memory, and committing (or rolling back) happens after the toast dismisses. This prevents accidental data loss without adding confirmation dialogs.

---

## Proposed Tickets

### Ticket 1: Add relative date filters to QueryEngine

**Title:** Add relative date filter predicates (today, this week, last 30 days) to QueryEngine

**Description:** Extend Bugbook's `Filter` enum in `Sources/BugbookCore/Model/Query.swift` with a new case `relativeDateRange(property: String, range: RelativeDateRange)` where `RelativeDateRange` is an enum: `today`, `yesterday`, `thisWeek`, `lastWeek`, `last7Days`, `last30Days`, `next7Days`, `thisMonth`. In `QueryEngine.swift`, resolve the relative range to absolute start/end dates at query time, then apply the same comparison logic already used for `greaterThan`/`lessThan` date filters. Update the CLI filter syntax to accept `due=_today`, `due=_this_week`, etc. (underscore prefix to distinguish from literal values). Update `ViewConfig` to allow these in saved view filters so views stay evergreen.

AppFlowy shipped this in v0.11.9 and it immediately made their database views more useful — a "Due This Week" view stays relevant without manual date updates. The same applies to Bugbook's kanban and calendar views.

- **Effort:** low
- **Source:** AppFlowy v0.11.9 release — relative date filters for date fields

### Ticket 2: Add keyboard navigation (j/k) and Cmd+K command palette

**Title:** Add j/k keyboard navigation and Cmd+K command palette to database views

**Description:** In the SwiftUI database views (`Sources/Bugbook/Views/`), add keyboard-driven row navigation:

1. **j/k navigation:** Track a `focusedRowIndex` in `DatabaseViewModel`. On `j` press, increment; on `k`, decrement. Highlight the focused row. On `Enter`, open the row detail. On `x`, toggle row selection. On `d`, trigger delete (with undo toast from Ticket 3). Use SwiftUI's `.onKeyPress` modifier (macOS 14+) on the view container.

2. **Cmd+K command palette:** Add a global `.keyboardShortcut("k", modifiers: .command)` that presents a filtered list overlay. Data source: all databases from `DatabaseStore.listDatabases()` + recent pages. Type to filter, arrow keys to navigate, Enter to open, Esc to dismiss. Render as a centered overlay sheet with a search field and scrolling result list.

Exo's keyboard-first design (j/k, Cmd+K, Tab cycling, batch selection) is one of its most praised features. PKM power users live on the keyboard.

- **Effort:** low
- **Source:** Exo (ankitvgupta/mail-app) — keyboard navigation across PRs #146, #141, and core `EmailList.tsx`

### Ticket 3: Add undo toast for destructive operations

**Title:** Add deferred-delete with 5-second undo toast for destructive row operations

**Description:** When a user deletes a row (or batch-deletes rows) in any database view, don't immediately call `MutationEngine.execute()`. Instead:

1. Remove the row from the UI immediately (optimistic update).
2. Show a toast at the bottom of the view: "[Row title] deleted — Undo" with a 5-second countdown.
3. If the user taps Undo, restore the row to the UI and cancel the mutation.
4. If the toast times out, execute the actual `Operation.deleteRow` mutation and patch the index.

Implementation: Add a `PendingDeletion` struct (rowId, row snapshot, timer) and an `UndoToastView` SwiftUI component. The `DatabaseViewModel` holds an optional `PendingDeletion` and exposes `undoDelete()`. The toast is a `.overlay()` on the database view with a slide-up animation.

Exo uses this exact pattern for send, archive, block-sender, and delete operations across their entire app. It prevents accidental data loss without modal confirmation dialogs.

- **Effort:** low
- **Source:** Exo (ankitvgupta/mail-app) PR #141 — one-click block-sender with undo toast pattern
