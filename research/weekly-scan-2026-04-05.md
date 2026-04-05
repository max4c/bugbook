# Weekly Research Scan — 2026-04-05

Repos monitored: **OpenOats**, **QMD**, **AppFlowy**, **Exo (mail-app)**
Period: March 29 – April 5, 2026

---

## 1. OpenOats (yazinsai/OpenOats)

> Native macOS (Swift/SwiftUI) meeting note-taker with on-device WhisperKit transcription, local knowledge-base search via embeddings, and LLM-powered suggestions. ~2.1k stars, MIT.

### Activity: Moderate (6 merged PRs, 3 open issues)

| PR / Commit | What shipped | Why it matters |
|-------------|-------------|----------------|
| #261 | **User-editable note templates** (`TemplateStore.swift`) — create, edit, and apply custom note templates | Extensible template system for structured output |
| #255 | **EventKit calendar integration** — auto-titles sessions from calendar events, pulls attendee lists | Contextual auto-metadata from system sources |
| #257 | **Move KB file I/O off `@MainActor`** — Knowledge Base reads now async | Critical perf fix for file-heavy architectures |
| #258 | **AirPods mic bleed fix** with output device picker | Audio UX polish |
| #260 | **Template picker in session view** — apply template before/after meeting | Template UX integration |
| #259 | Minor: settings label cleanup | — |

#### Active Issues

- #288: Transcription missing other person's audio — real user pain point
- #279: Speaker attribution issues with MS Teams
- #304 (Closed): Windows support request — shows demand beyond macOS

### Patterns Worth Adapting for Bugbook

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **User-editable templates** | `TemplateStore.swift` — file-based template CRUD. Bugbook could offer templates for database schemas and page layouts. Users define a template as a markdown file with YAML frontmatter; `create` command accepts `--template <name>`. | **Low** | **High** |
| **Calendar-aware auto-metadata** | EventKit integration auto-populates title, attendees, date from calendar. Bugbook pages could auto-tag with calendar context (meeting name, project) when created during a calendar event. | Med | Med |
| **Async file I/O off MainActor** | PR #257 moved all Knowledge Base file reads off `@MainActor`. Bugbook's `RowStore` and `IndexManager` must follow the same pattern — any file I/O on the main actor will freeze the UI with large workspaces. | **Low** | **High** |
| **Meeting format spec** | Formal spec (`docs/meeting-format-spec.md`) with schema versioning (`schema: openoats/v1`), `x_` extension fields, and "parsers must ignore unknown fields" rule. Bugbook should formalize its row file format similarly. | Low | Med |
| **Progressive file enrichment** | Files go through raw → cleaned → AI-enriched stages in-place. Bugbook CLI agents could progressively add AI-generated summaries, tags, or backlinks to existing note bodies. | Low | Med |
| **Dataview-compatible inline fields** | Action items use `[owner:: Name] [due:: YYYY-MM-DD]` syntax for Obsidian Dataview compatibility. If Bugbook supports this convention, files become portable to/from Obsidian. | Low | Med |

---

## 2. QMD (tobi/qmd)

> On-device hybrid search engine for markdown files. BM25 (SQLite FTS5) + vector similarity (sqlite-vec) + LLM reranking — all local. ~17.2k stars, MIT. By Tobi Lütke.

### Activity: High (5 merged PRs, 7 open PRs, 6 open issues)

| PR | What shipped | Why it matters |
|----|-------------|----------------|
| #478 | **`rerank` parameter on MCP query tool** | Bugbook can now skip LLM reranking for fast keyword searches |
| #475 | **`handelize()` filename fix** — fixes mangled filenames with dots/timestamps | Fixes upstream filename resolution bugs |
| #453 | **Configurable `RERANK_CONTEXT_SIZE`** (default 2048→4096) | Better reranking for long documents |
| #458 | **Embedding reliability fixes** | Fewer silent failures during indexing |
| #456 | **`vec0 OR REPLACE` workaround** | sqlite-vec compatibility fix |

#### Notable Open PRs

| PR | Title | Relevance to Bugbook |
|----|-------|---------------------|
| **#503** | Cloud LLM support | Users without powerful local hardware could use cloud models for reranking |
| **#502** | Per-collection model config in `index.yml` | Different embedding models per Bugbook workspace |
| **#492** | Ebbinghaus memory decay with recall scoring | Spaced repetition — surface notes needing review. Extremely relevant for PKM |
| **#496** | Binary search for `findBestCutoff` and `isInsideCodeFence` | Chunking performance improvement |
| **#490** | Remote Ollama embeddings via `OLLAMA_EMBED_URL` | Alternative to local node-llama-cpp |

#### Notable Open Issues

| Issue | Title | Relevance |
|-------|-------|-----------|
| **#499** | Index should be part of `qmd://` link | ⚠️ Would change virtual path URI format — Bugbook's `normalizedRelativePath()` parses these |
| **#497** | `QMD_EMBED_MODEL` env var ignored → dimension mismatch | Users setting custom models may hit this |
| **#498** | sqlite-vec extension loading support | Platform compatibility |

### What Bugbook Should Do

**Upstream changes (update dependency, no Bugbook code changes):**
- FTS5 ranking fixes (#463, #462) — automatic improvement
- `qmd embed` reliability (#458, #456) — upstream fix
- `handelize()` filename fix (#475) — just update qmd

**Bugbook code changes needed:**

| Action | Detail | Effort | Impact |
|--------|--------|--------|--------|
| **Expose `--no-rerank` flag** | Pass `rerank: false` in `QmdBackend` for BM25-only searches via the `query` command. Skips expensive LLM reranking when users just want keyword search. | **Low** | **High** |
| **Pass `--chunk-strategy auto`** | Enable AST-aware chunking (merged last week in #449) for code files in workspaces. Add to `ensureCollection()` calls. | **Low** | Med |
| **Watch issue #499** | If `qmd://` URI format changes to include index, `normalizedRelativePath()` in `SearchCommand.swift` will break. No action yet, but monitor. | — | — |
| **Surface `rerank_context_size` as setting** | Expose `RERANK_CONTEXT_SIZE` env var in Bugbook settings for users with long documents. | Low | Low |

---

## 3. AppFlowy (AppFlowy-IO/AppFlowy)

> Open-source AI-powered collaborative workspace (Flutter + Rust), ~68.9k stars. Notion alternative emphasizing data privacy and local-first architecture.

### Activity: Moderate (v0.11.5 + v0.11.6 released)

**v0.11.6 (April 2, 2026):**
- **Document data corruption fix** — critical stability patch
- Block selection and select-all behavior improvements

**v0.11.5 (March 26, 2026):**
- AI Meeting Transcript — paste YouTube link → transcript
- **Database bulk edit optimization** — multi-row property editing
- Mobile: database embedded views support Feed and List views
- Fixes: shortcut conflicts, plus-menu insertion, filter evaluation

#### Tab Management — Major 2026 Focus (8+ issues updated this week)

| Issue | What | Timeline |
|-------|------|----------|
| #3101 | Navigation history (back/forward) | 2026 |
| #8350 | Support opening multiple windows | Q2 26 |
| #6279 | Change order of opened tabs | Q2 26 |
| #8545 | Right-click "open in new tab" | Q2 26 |
| #8561 | Missing keyboard shortcut for new tab | Q2 26 |
| #8477 | Go to doc section when switching to active tab | Q2 26 |

#### Database Issues Worth Watching

| Issue | What | Relevance |
|-------|------|-----------|
| **#5899** | Row records mentionable as pages | Bugbook's file-per-row architecture does this naturally |
| **#8623** | Kanban "No Status" column annoyance | UX problem Bugbook should solve preemptively |
| **#2418** | Deleted rows should go to Trash | Bugbook could implement soft-delete via a `_trash/` directory |
| **#8624** | Nested templates broken (databases inside templates shared, not copied) | Bugbook's directory-copy approach solves this |

### Patterns Worth Adapting for Bugbook

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Database bulk editing** | Select multiple rows → edit shared property (status, tags). In Bugbook, pipe selection through `bugbook batch` with a shared `--set` value. SwiftUI: multi-select + toolbar action. | **Low** | **High** |
| **Tab management / multi-window** | AppFlowy struggling with this in Flutter (10+ open issues). Bugbook on macOS can use native `WindowGroup` + `openWindow` for free. Implement now while it's a differentiator. | Med | High |
| **Soft-delete to Trash** | Issue #2418. Move deleted row files to `_trash/` with timestamp suffix. Recoverable via CLI (`bugbook restore <db> <row_id>`) or UI. | **Low** | Med |
| **Kanban empty-status handling** | Issue #8623. Make the "No Status" column hideable/collapsible. Validate required fields on card creation to prevent orphaned cards. | **Low** | Med |
| **Database row as mentionable page** | Issue #5899. Bugbook's file-per-row architecture means `[[row filename]]` wikilinks work naturally. Just need a link resolver in the markdown editor. | Med | High |
| **Feed/timeline view** | v0.11.2 added a Feed view type. For Bugbook: a chronological view sorted by `created_at` or `updated_at`, showing title + preview. Good for journals and activity streams. | Med | Med |

---

## 4. Exo (ankitvgupta/mail-app)

> AI-native email client built with Electron + TypeScript. Local-first with SQLite, deep Claude integration, agent system with tool use. Active development, pre-launch.

### Activity: Very High (20+ commits, 8 merged PRs)

| PR | What shipped | Why it matters |
|----|-------------|----------------|
| #49 | **Prompt injection prevention** — `<untrusted_email>` safety tags with loop-based stripping | Security pattern for AI processing of user content |
| #47 | **Prefetch pipeline concurrency fix** — reduced from 10→3 parallel tasks, added event-loop yields | Critical perf lesson for background AI processing |
| #45 | **Split view with custom filters** — configurable email splits with user-defined filter rules | Virtual views over a single data source |
| #43 | **Agent permission gate + audit log** — `permission-gate.ts`, `audit-log.ts` for tool access control | Safe agent automation pattern |
| #41 | **LLM cost tracking** — per-call cost tracking in `llm_calls` table with model-aware pricing | Essential for AI-powered apps |
| #39 | **Memory/learning system** — `draft-edit-learner.ts` extracts preferences from how users edit AI drafts | AI that improves from user behavior |
| #37 | **Dual command palette** — Cmd+K for commands, Cmd+J for agent | Power-user UX pattern |

### Architecture Deep Dive (Most Relevant Patterns)

#### Agent System
- `agent-coordinator.ts` → provider dispatch → `orchestrator.ts` lifecycle management
- `permission-gate.ts` gates tool access; `audit-log.ts` records all calls
- `AgentCommandPalette.tsx` (Cmd+J) for natural-language interaction
- Agent-to-agent delegation and external provider registration

#### Memory/Learning System
- `memory-context.ts` injects relevant memories into AI prompts
- `draft-edit-learner.ts` learns writing preferences from user edits
- `analysis-edit-learner.ts` learns priority preferences from overrides
- Configurable scoping (per-sender in email → per-project/tag in PKM)

#### Background Processing Pipeline
Multi-stage pipeline with lessons learned:
1. Parse/analyze new items
2. Enrich high-priority items
3. Auto-generate drafts
- Concurrency limits matter (10→3 was the fix)
- Event-loop yields prevent UI freezing
- Caching avoids duplicate expensive DB queries

### Patterns Worth Adapting for Bugbook

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Agent audit log** | Log all CLI agent actions (create/update/delete) with timestamp, caller, and parameters. Write to `.bugbook/agents/events.jsonl`. Bugbook already has the file — just ensure every mutation logs an event. | **Low** | **High** |
| **Dual command palette** | Cmd+K for navigation/commands, Cmd+J for agent chat. SwiftUI `CommandGroup` + sheet overlay. Separate entry points for structured commands vs. freeform AI. | Med | High |
| **Prompt injection prevention** | Wrap user-authored content in `<untrusted_content>` tags before passing to AI. Strip nested bypass attempts. Critical for AI features that process web clippings or imported content. | **Low** | Med |
| **Memory/learning from edits** | Track how users modify AI-generated content (summaries, tags). Over time, improve prompts based on patterns. Store in `.bugbook/agents/memories.json`. | High | High |
| **LLM cost tracking** | Centralized service logging model, tokens, cost per AI call. Store in `agents/events.jsonl` with `type: "llm_call"`. Essential for transparency. | **Low** | Med |
| **Background processing with concurrency control** | Limit parallel AI operations (3, not 10). Yield to event loop between batches. Directly applicable to Bugbook's index rebuilds and future AI enrichment pipeline. | Low | Med |
| **Virtual views / split filters** | User-defined filter presets over the same dataset — Bugbook's `ViewConfig` already supports this. The "split config editor" UX pattern is worth studying for a view builder. | Low | Med |

---

## Top 3 This Week

The three highest-impact, lowest-effort items to act on first. All are changes to Bugbook's own codebase.

### 1. Expose `--no-rerank` for Fast Keyword Search (from QMD #478)
**Effort: Low | Impact: High**
QMD's MCP query tool now accepts a `rerank` parameter. Bugbook's `QmdBackend` in `SearchCommand.swift` should pass `rerank: false` for BM25-only search modes. This skips the expensive LLM reranking step entirely, making keyword searches near-instant. One-line change in the query command builder.

### 2. Database Bulk Editing in SwiftUI (from AppFlowy v0.11.5)
**Effort: Low | Impact: High**
AppFlowy shipped database bulk edit optimization in v0.11.5 — select multiple rows, change a shared property. Bugbook already has `bugbook batch` on the CLI side. The SwiftUI gap is: multi-select in table/kanban views → toolbar action → `MutationEngine.execute()` with batch operations. The engine supports it; just wire up the UI. Multi-select is native in SwiftUI `List` and `Table`.

### 3. Agent Audit Log for All Mutations (from Exo #43)
**Effort: Low | Impact: High**
Exo's `audit-log.ts` records every agent tool call with timestamp, caller, and parameters. Bugbook already has `.bugbook/agents/events.jsonl` — but mutations via the CLI don't always log to it. Ensure every `MutationEngine.execute()` call from `BugbookCLI` writes a structured event to `events.jsonl` with the operation details. This gives full auditability for agent-driven changes and powers the Agent Hub dashboard.

---

## Proposed Tickets

### Ticket 1: Add `--no-rerank` flag to search commands

**Title:** Skip LLM reranking for keyword-only searches

**Description:** Bugbook's `QmdBackend` in `SearchCommand.swift` always delegates to qmd without specifying the `rerank` parameter. Since qmd #478 merged, the `query` MCP tool accepts `rerank: false` to skip LLM reranking entirely. Add a `--no-rerank` flag to `bugbook search` that passes this through. Default behavior: rerank enabled for hybrid/vector searches, disabled for BM25-only (`--mode keyword`). This makes keyword searches near-instant by avoiding the LLM reranking step.

**Effort:** Low (one flag + conditional parameter in `QmdBackend.buildQuery()`)

**Source:** [tobi/qmd#478](https://github.com/tobi/qmd/pull/478) — Add `rerank` parameter to MCP query tool

---

### Ticket 2: Wire up multi-select bulk editing in database views

**Title:** Add bulk property editing to table and kanban views

**Description:** AppFlowy v0.11.5 shipped database bulk editing — selecting multiple rows and changing a shared property in one action. Bugbook's `MutationEngine` already supports batch operations, and the CLI has `bugbook batch`. The missing piece is the SwiftUI UI: enable multi-select in `DatabaseTableView` and `DatabaseKanbanView`, show a floating toolbar when >1 row is selected, and wire the "Set Property" action to `MutationEngine.execute()` with batch `updateRow` operations. Use SwiftUI's native `Table` selection and `List` selection APIs.

**Effort:** Low (engine already supports batch; this is UI wiring)

**Source:** [AppFlowy v0.11.5 release notes](https://github.com/AppFlowy-IO/AppFlowy/releases/tag/0.11.5) — Database bulk edit optimization

---

### Ticket 3: Ensure all CLI mutations emit agent audit events

**Title:** Log all CLI mutations to `events.jsonl` for agent auditability

**Description:** Exo's agent system logs every tool call with timestamp, caller, and parameters to an audit log. Bugbook has `.bugbook/agents/events.jsonl` but CLI mutations (create, update, delete, batch) don't consistently write events to it. Add an `AuditLogger` that `MutationEngine` calls after every successful mutation, writing a JSON line with `{type: "mutation", timestamp, command, database, operations, caller}`. The `caller` field distinguishes "cli", "app", or a specific agent run ID. This powers the Agent Hub dashboard and gives users a complete audit trail of all automated changes.

**Effort:** Low (structured append to an existing JSONL file after each mutation)

**Source:** [ankitvgupta/mail-app#43](https://github.com/ankitvgupta/mail-app/pull/43) — Agent permission gate + audit log
