# Weekly Research Scan — 2026-05-10

Repos monitored: **OpenOats**, **QMD**, **AppFlowy**, **Exo (mail-app)**
Period: May 3–10, 2026

---

## 1. OpenOats (yazinsai/OpenOats)

> Native macOS (Swift/SwiftUI) meeting assistant with on-device WhisperKit transcription, local KB embedding search, and multi-provider LLM suggestions. 2.4k stars, MIT.

### Activity: High (17 commits, 12+ merged PRs, releases v1.74.5–v1.74.12)

| PR | What shipped | Why it matters |
|----|-------------|----------------|
| #589 | **Unified Home Timeline Workspace** (open, high-risk) | Single-window redesign: meetings timeline + collapsible detail pane. Directly comparable to Dahso's table/detail pattern. |
| #587 | **Reusable Meeting Detail Pane** | Extracted detail pane into reusable component — progressive disclosure pattern. |
| #575 | **Calendar Settings Tab with Filtering** | Dedicated settings with exclusion-list approach, card-based UI, per-account grouping. |
| #597/599 | **Audio race condition + SPM resource fix** | Robustness: retry logic for system audio tap on Sequoia 15.7.x. |
| #581 | **KB indexing resilience** | Knowledge base indexer handles Ollama model failures gracefully without crashing. |

### Patterns worth adapting for Dahso

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Unified timeline with collapsible detail pane** | Single-window layout: chronological items on left, inline detail expansion on right. Maps to Dahso's row list + row detail view. | Med | High |
| **Template system with deterministic UUIDs** | JSON-stored templates (name, icon, system prompt). Built-ins use deterministic UUIDs and auto-replenish. User templates layer on top with full CRUD. | Low | Med |
| **JSONL for append-only data** | Session transcripts use append-only `.jsonl` — crash-resilient, git-friendly, no full-file rewrites. Applicable to Dahso's agent `events.jsonl`. | Trivial | Med |
| **Schema version in YAML frontmatter** | `openoats/v1` field in frontmatter enables forward-compatible parsing. Dahso could version its row format similarly. | Trivial | Low |
| **Markdown asset path sandboxing** | Only allows relative paths starting with `images/` or `attachments/`, blocks `..` traversal. Critical if agents write markdown. | Trivial | Low |

---

## 2. QMD (tobi/qmd)

> On-device hybrid search engine for markdown files. BM25 (SQLite FTS5) + vector similarity (sqlite-vec) + LLM reranking — all local via node-llama-cpp. 24.5k stars, MIT. By Tobi Lütke.

### Activity: High (18 commits on May 9 alone via PR #636, 3 community PRs merged May 3)

| Change | What shipped | Why it matters |
|--------|-------------|----------------|
| d045a8b | **CJK FTS5 fix** — space-separate CJK chars for tokenizer | Dahso users with CJK content get correct search results. No Dahso code change needed. |
| 92aaded | **Preserve inactive docs during orphan cleanup** | Previously `qmd update` could delete refs to files Dahso moved/renamed. Now safe. |
| 004714a | **Fix hybrid RRF weighting by query type** | Improves quality of `--mode hybrid` results. |
| dff6513 | **Preserve doc IDs across case-only renames** | Dahso renames pages via UI; prevents broken search refs. |
| 3d991b2 | **CLI status no longer imports llama** | `qmd --version` drops from ~3s to ~50ms. Benefits `QmdService.detect()`. |

### Notable Open PRs

| PR | Title | Dahso relevance |
|----|-------|-----------------|
| #608 | **Daemon-aware CLI fast-path: ~4x speedup** | Hybrid search drops from ~13s to ~3s cold, ~30ms warm. Dahso already prewarms daemon. |
| #622 | **`--no-expand` flag for qmd query** | Skip expensive query expansion for incremental/typeahead searches. |
| #632 | **MCP tools for update and embed** | Enables MCP-based indexing without subprocess spawning. |
| #624 | **Stateless MCP HTTP server** | Eliminates session loss on daemon restart. |
| #628 | **Wire `--context` flag through query expansion** | Better results when rich context metadata is provided. |

### Actionable for Dahso (dependency-update items noted as such)

| Action | Type | Effort | Impact |
|--------|------|--------|--------|
| Bump minimum QMD version to 2.1.0 in `detect()` | Dependency update | Trivial | Med |
| Add `--no-expand` to `QmdService` for typeahead/refinement queries | Dahso code | Low | Med |
| Pass `--context` metadata at query time (not just registration) | Dahso code | Low | Med |
| Switch from CLI subprocess to MCP HTTP transport (when #632+#624 merge) | Dahso code | Med | High |
| Expose embedding progress in SwiftUI during initial collection setup | Dahso code | Med | Med |

---

## 3. AppFlowy (AppFlowy-IO/AppFlowy)

> Open-source AI collaborative workspace (Flutter + Rust). Local-first, self-hosted, cross-platform. 70.3k stars.

### Activity: Moderate (issue-driven week; latest release v0.11.8 on Apr 24)

No new commits merged to `main` this week. Active community issues and feature requests:

| Issue | Title | Relevance |
|-------|-------|-----------|
| #8707 | **Agentic AI Workspace Assistant for Databases, Tasks, Calendars** | Validates Dahso's agent collaboration direction |
| #8708 | **Native Calendar & Task Alerts/Reminders** | Calendar view + notification system |
| #8690 | **Hide when empty option for property visibility** | Simple UX win for database views |
| #8689 | **Hide all properties button** | Bulk view configuration |
| #8165 | **Link to grid page (row as page reference)** | Cross-referencing rows as pages |
| #8698 | **Freeze pane in grid view** | Table view usability |

### Recent Release Patterns (v0.11.7–v0.11.8)

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Lazy hydration for database views** | Only load visible rows; hydrate on scroll. Critical for 100+ row databases. | Low | High |
| **Incremental sort** | Avoid re-sorting entire dataset on single-row change. Patch sort position instead. | Low | Med |
| **Background sync with cache persistence** | Store computed view state locally, sync deltas in background. Faster cold-start. | Med | High |
| **Advanced filter logic (AND/OR)** | v0.11.5 added compound filter conditions with proper eval order. Dahso currently ANDs all filters. | Med | Med |
| **View tab bar pattern** | Unified switching between grid/kanban/calendar/list of same data, stored per-view config. | Low | High |
| **Hide-when-empty property visibility** | Conditional field display — only show properties that have values for a given row. Reduces noise. | Trivial | Med |
| **Freeze pane (pinned columns)** | Pin title + key columns while horizontal scrolling. Essential for wide schemas. | Med | Med |

### Architecture Insights (Rust backend: `flowy-database2`)

The `services/` layer separates concerns cleanly:
- `filter/` — controller + entities + task pattern
- `sort/` — same pattern, independent module
- `group/` — per-field-type grouping implementations
- `calculations/` — computed aggregates (sum, count, avg)
- `snapshot/` — state versioning

Each module operates independently and composes through the `view_editor`. This maps well to Dahso's `QueryEngine` + `MutationEngine` split.

**AI integration** (`flowy-ai/src/`): MCP support, local AI with sub-modules (chat, completion, database, prompt), `flowy-sqlite-vec` for local vector search, offline AI support. Confirms AI-native architecture is the direction.

---

## 4. Exo (ankitvgupta/mail-app)

> Open-source AI-native desktop email client (Electron + React + TypeScript). Claude AI integrated for triage, drafts, research, and agent delegation. 427 stars.

### Activity: Low on main (last merge Apr 24), but 2 active PRs

| PR | Title | Relevance |
|----|-------|-----------|
| #113 | **Versioned config migration** — distinguishes legacy vs fresh installs | Config evolution pattern for Dahso schemas |
| #112 | **AWS Bedrock as AI provider** — dependency injection of Anthropic client interface | Multi-provider abstraction |

### Architecture Patterns (Deep Dive)

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Risk-tiered permission gate for agent tools** | 4 tiers: auto / notify / confirm / confirm-with-preview. Trivial reads auto-approve; destructive ops require preview. | Low | High |
| **Tool registry by domain** | Tools organized as `email-tools`, `browser-tools`, `analysis-tools`. Each declares risk level, input schema, execution fn. Central `registry.ts` for discovery. | Low | Med |
| **Multi-provider LLM abstraction** | `getFeatureModelConfig(feature)` returns `{provider, model}` tuples. Per-feature routing (analysis → Anthropic, drafts → Ollama). Factory satisfies structural protocol. | Med | High |
| **Agent orchestrator with sub-agent delegation** | `AgentOrchestrator` manages concurrent tasks with per-task AbortControllers. `asSubAgentTool()` enables agents calling agents. Audit log tracks all tool calls. | Med | High |
| **Optimistic reads / offline action queue** | Set of locally-applied IDs prevents stale sync data from reverting user actions. Pending ops queue with retry (max 3, sequential). | Med | Med |
| **Style learning / memory system** | Per-recipient formality profiles, persistent user preferences, draft memories with voting-based promotion. | Med | Med |
| **Versioned config migration** | `configVersion` field + forward-only migration fns. Preserves legacy settings while applying new defaults to fresh installs. | Trivial | Med |

---

## Cross-Repo Themes

1. **Agent collaboration is table-stakes** — OpenOats has real-time suggestions, AppFlowy filed #8707 for agentic workspace assistant, Exo has a full agent orchestrator. All moving toward AI-as-coworker, not AI-as-sidebar.

2. **Local-first validated at scale** — All four repos prioritize on-device processing. QMD (24.5k stars) proves local hybrid search works. OpenOats runs whisper + embeddings + LLM locally. The pattern is mature.

3. **Permission/trust boundaries for AI** — Exo's 4-tier permission gate is the most explicit, but all repos grapple with "what can AI do without asking?" Dahso's agent layer needs this before shipping.

4. **Performance through laziness** — AppFlowy's lazy hydration, QMD's daemon fast-path, OpenOats's hash-based change detection. Don't load/compute until needed.

---

## Top 3 This Week

These are the three highest-impact, lowest-effort changes to Dahso's own codebase:

### 1. Add risk-tiered permission gate to agent tool execution
**Why:** Dahso's agent layer (`AgentCommand.swift` + agent workspace) currently has no trust boundaries. Before agents can safely operate on user data, tool invocations need risk classification: reads auto-approve, metadata edits notify, deletions require confirmation with preview.
**Inspired by:** Exo's `AgentOrchestrator` + tool registry with 4-tier permission model.
**Effort:** Low | **Impact:** High

### 2. Implement lazy row hydration in database views
**Why:** `DatabaseViewModel.refresh()` currently loads all matching rows into memory. For databases with 100+ rows, this causes sluggish view switches and unnecessary memory pressure. Load only visible rows, hydrate on scroll.
**Inspired by:** AppFlowy v0.11.7's lazy hydration feature and incremental sort.
**Effort:** Low | **Impact:** High

### 3. Add hide-when-empty property visibility to table/list views
**Why:** Databases with many optional properties (10+ columns) create noisy, sparse views. Allowing properties to auto-hide when empty for a given row dramatically improves information density without losing data.
**Inspired by:** AppFlowy issue #8690 (closed this week) and their property visibility system.
**Effort:** Trivial | **Impact:** Medium

---

## Proposed Tickets

### Ticket 1: Add risk-tiered permission gate to agent tool execution

**Title:** Add permission tiers to agent tool invocations

**Description:** Implement a `ToolPermission` enum (`auto`, `notify`, `confirm`, `confirmWithPreview`) in DahsoCore's Agent layer. Each agent tool (query, create, update, delete, batch) declares its risk tier. The `AgentCommand` executor checks the tier before running:
- `auto`: read-only operations (query, get, db list, db schema)
- `notify`: metadata edits (update single property)
- `confirm`: row creation, body edits
- `confirmWithPreview`: deletion, batch operations

Add a `ToolRegistry` protocol where tools register their name, description, risk level, and execution function. The desktop app shows inline confirmation UI; the CLI prompts on stderr.

**Effort:** Low — the agent command structure already exists; this adds a classification layer and gate check before execution.

**Source:** [ankitvgupta/mail-app `src/main/agents/`](https://github.com/ankitvgupta/mail-app) — agent orchestrator with tiered permissions and tool registry pattern.

---

### Ticket 2: Implement lazy row hydration in DatabaseViewModel

**Title:** Lazy-load rows in database views with windowed hydration

**Description:** Refactor `DatabaseViewModel.refresh()` to implement windowed loading:
1. Query returns `totalCount` and first page of row IDs (limit 50)
2. SwiftUI `LazyVStack`/`LazyVGrid` triggers hydration of row properties as they scroll into view
3. Keep a hydration window of ±20 rows around the visible range
4. Dehydrate rows scrolled far out of view to reclaim memory

This applies to all view types (table, kanban, calendar, list). The `QueryEngine` already supports `limit`/`offset` — wire pagination through to the view layer.

**Effort:** Low — QueryEngine pagination exists; the change is in the ViewModel and SwiftUI view layer.

**Source:** [AppFlowy v0.11.7 release notes](https://github.com/AppFlowy-IO/AppFlowy/releases) — lazy hydration for databases, shipped April 2026.

---

### Ticket 3: Add hide-when-empty property visibility option

**Title:** Add hide-when-empty display option for database properties

**Description:** Add a `visibility` field to `ViewConfig` with options: `always`, `hideWhenEmpty`, `hidden`. In table view, columns with `hideWhenEmpty` are shown only if ≥1 visible row has a value. In list/detail views, empty properties with this setting are omitted from the row card entirely.

Implementation:
1. Add `columnVisibility: [String: PropertyVisibility]` to `ViewConfig`
2. After `refresh()`, compute which `hideWhenEmpty` columns have any non-nil values in the current result set
3. Pass visible columns to the view layer
4. Add a "Hide when empty" toggle in the column header context menu

**Effort:** Trivial — view-layer only change, no storage format modification.

**Source:** [AppFlowy issue #8690](https://github.com/AppFlowy-IO/AppFlowy/issues/8690) — "Hide when empty option for property visibility", closed May 9, 2026.
