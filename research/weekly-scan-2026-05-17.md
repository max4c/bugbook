# Weekly Research Scan — 2026-05-17

Repos monitored: **OpenOats**, **QMD**, **AppFlowy**, **Exo (mail-app)**
Period: May 10–17, 2026

---

## 1. OpenOats (yazinsai/OpenOats)

> Native macOS (Swift/SwiftUI) meeting assistant with on-device WhisperKit transcription, local knowledge-base search via embeddings, and LLM-powered contextual suggestions. MIT.

### Activity: High (8 commits, 2 open PRs, 11 new issues)

| Commit/PR | What shipped | Why it matters |
|-----------|-------------|----------------|
| #589 | **Unified home timeline workspace** — single surface for all meetings and notes | Consolidation pattern: one "home" view instead of scattered entry points |
| #604/#608 | **Main window as default meeting review surface** — moved management workflows into main window | Reduced navigation depth; everything accessible from one pane |
| #610 | **Auto-generate post-meeting notes when configured** | Template-driven auto-processing after lifecycle events |
| #611 | Fix intent card tap target to cover entire tile | Polish: hit targets should be generous |
| — | Post-update What's New sheet, live scratchpad visibility fix, markdown fence cleanup | Onboarding + editor stability |

**Notable open PRs:** #623 Fix banner button, #622 True default notes template fallback.

**Notable issues:** #625 System audio tap format failure, #624 AI sidecast incomplete sentences, #618 Speaker renaming, #615 LM Studio as first-class provider, #602 Native Anthropic/OpenAI providers.

### Patterns worth adapting for Dahso

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Provider abstraction (enum-based)** | `LLMProvider` and `EmbeddingProvider` as `CaseIterable + Codable + Identifiable` enums. Dispatch via single async function. Supports Ollama, OpenRouter, Voyage AI. SwiftUI picker integration is free. | **Low** | **High** |
| **Content-addressed KB cache** | `filename:sha256` keys with config fingerprint invalidation. Only re-embeds changed docs. Uses vDSP/SIMD for normalized dot-product search. | **Low** | **High** |
| **Markdown-aware semantic chunking** | Header hierarchy (H1→H6), 80–500 word bounds, 20% overlap. Adjacent chunk retrieval for context expansion. Multi-query fusion with max-similarity scoring. | Med | High |
| **Template system with @Observable** | Built-in templates with deterministic UUIDs (survive resets). User-customizable system prompts. JSON persistence. Directly reactive in SwiftUI. | **Low** | Med |
| **Three-layer suggestion architecture** | Pre-fetch cache (30s TTL) → burst-decay throttle → streaming LLM. Lifecycle-tracked suggestions (streaming/completed/superseded). | High | Med |
| **Unified home timeline** | Single chronological view combining all entity types. Good for "what happened today" across databases. | Med | Med |

---

## 2. QMD (tobi/qmd)

> On-device hybrid search engine for markdown files. BM25 (SQLite FTS5) + vector similarity (sqlite-vec) + LLM reranking — all local via node-llama-cpp with GGUF models. 17.2k stars, MIT. By Tobi Lütke.

### Activity: Very High (25+ commits, active PRs, 3 new issues)

| Commit/PR | What shipped | Why it matters |
|-----------|-------------|----------------|
| May 16 | **Unified model resolution** — single code path for all model loading | Simplifies provider logic; reduces GPU fallback noise |
| May 16 | **CLI-served skills** — expose capabilities via CLI interface | CLI as integration surface for external tools |
| May 16 | Local benchmark support, partial embedding fixes, bin wrapper tests | Testing infrastructure maturity |
| May 15 | **Terse MCP collection summaries** for server instructions | Better context injection into LLM system prompts |
| May 14 | **Absolute line numbers in snippets** (community) | Better source attribution in search results |
| May 12 | candidateLimit forwarding fix | Correct search result limiting |

**Notable open PRs:** `--watch` mode for periodic re-indexing (May 15), MCP `update`/`embed` tools (May 7), remote embedding + reranking + query expansion (May 5), configurable FTS5 tokenizer (May 4), stateless MCP HTTP mode (May 4).

**Notable issues:** #645 `exclude:` patterns to prevent double-indexing nested collections, #642 Share pre-built indexes across team members, #641 Configurable chunk size/overlap.

### Patterns worth adapting for Dahso

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **`--watch` mode (FSEvents auto-reindex)** | Periodic re-indexing triggered by file changes. On macOS, FSEvents makes this trivial. Dahso could auto-rebuild `_index.json` when row files change outside the app. | **Low** | **High** |
| **Terse collection summaries for MCP** | Dynamic system prompt injection telling the LLM what data exists and how to search it. Concise descriptions prevent token waste. | **Low** | **High** |
| **Unified model resolution** | Single code path resolving model paths, checking GPU availability, handling fallbacks. Prevents scattered model-loading logic. | **Low** | Med |
| **Content-addressable storage** | SHA256 hash as key. Deduplicates content, trivial change detection. Multiple paths can reference same content. | **Low** | Med |
| **Exclude patterns for collections** | Glob-based exclusion prevents indexing build artifacts, node_modules, or nested sub-databases. | **Low** | Med |
| **MCP `update`/`embed` tools** | Expose write operations (not just read) via MCP. Lets agents trigger re-indexing or update metadata. | Med | Med |
| **Stateless MCP HTTP mode** | HTTP transport without session state. Simpler deployment, works with any HTTP client. | Med | Med |

---

## 3. AppFlowy (AppFlowy-IO/AppFlowy)

> Open-source AI-powered collaborative workspace (Flutter + Rust), 70.6k stars. Notion alternative emphasizing data privacy and local-first architecture.

### Activity: Moderate (v0.11.9 released May 12, 7 new issues)

**v0.11.9 highlights:**

| Feature | Why it matters |
|---------|----------------|
| **Relative date filters** (today, this week, last 30 days) | Standard UX for temporal queries; avoids manual date entry |
| **Database search** (find rows across a database) | Full-text search within structured data |
| **Space reordering** (drag-and-drop) | Workspace organization polish |
| **Hide empty groups** (default ON for new grouped views) | Cleaner kanban/grouped views |
| **Relation cell picker sorted by recency** | Faster relation assignment |
| **Create pages from relation properties** | Inline entity creation without context-switching |
| **Mobile workspace backup export/import** | Data portability |
| **Numeric filtering for rollup fields** | Computed field querying |

**Notable issues (May 10–17):**

| Issue | Title | Relevance |
|-------|-------|-----------|
| #8725 | Grid View Group by Date hides rows | Grouped view rendering bugs |
| #8722 | Local auto-save + cross-check before cloud sync | Users want Obsidian-like local file guarantees |
| #8720 | Local Backup feature request | Data sovereignty demand |
| #8718 | **Deep link endpoint for external clippers** (`appflowy-flutter://new`) | URL scheme for automation |

### Patterns worth adapting for Dahso

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Relative date filters** | Operators: `today`, `this_week`, `last_7_days`, `last_30_days`, `this_month`, `next_week`. Resolve to concrete date ranges at query time. | **Low** | **High** |
| **Deep link URL scheme** | `dahso://create?db=tasks&title=...&status=opt_todo`. Enables Shortcuts, Alfred, Raycast, agent integration without MCP. | **Low** | **High** |
| **Create entities from relation picker** | When assigning a relation, offer "Create new..." inline. Reduces friction for building connected data. | **Low** | Med |
| **Hide empty groups in kanban** | Default ON, toggle OFF. Keeps board views clean when many status options exist but few are active. | **Low** | Med |
| **Database search (row-level FTS)** | Search bar above table/kanban that filters visible rows by text match across all properties. Quick local filter, not full semantic search. | Med | Med |
| **Relation picker sorted by recency** | Most-recently-used relations appear first. Simple LRU cache per relation property. | **Low** | Low–Med |
| **Local-first gaps as differentiator** | #8722/#8720 show AppFlowy users frustrated by cloud dependency. Dahso's markdown-on-disk model is inherently stronger here. | — | — |

---

## 4. Exo / mail-app (ankitvgupta/mail-app)

> Open-source AI-native desktop email client ("Claude Code for your Inbox") built with Electron/React/TypeScript. Uses Claude for automatic analysis, prioritization, and draft generation. 427 stars.

### Activity: Low (no commits to main since April 24; 2 PRs, 3 issues since May 10)

| PR/Issue | What | Relevance |
|----------|------|-----------|
| #117 | Send & Archive toggle for replies | UX pattern: compound actions |
| #115 | Regenerating drafts doesn't update UI | Optimistic update bug |
| #114 | Block, Filter, Unsubscribe feature request | Automation/rule system |

### Architectural Analysis (Low activity → deep dive)

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Prioritized background AI queue** | `PrefetchService` with numeric priorities, per-type concurrency limits (10 for analysis, 3 for lookups, 1 for drafts), deduplication per entity, throttled progress updates (max 1/sec). | Med | **High** |
| **Hierarchical memory context** | Four scopes: Person → Domain → Category → Global. Memories have "use cases" for relevance filtering. Low-confidence observations promoted after repeated confirmation. Bullet-point injection into prompts. | Med | **High** |
| **Offline action queue + replay** | `pending-actions.ts` queues failed operations (max 3 retries) with replay on reconnection. `NetworkMonitor` detects online/offline. Outbox pattern for pending writes. | **Low** | Med |
| **Centralized LLM service with cost tracking** | All AI calls through single `createMessage()`. Exponential backoff. Every call logged to `llm_calls` table with caller attribution. Test injection via `_setClientForTesting()`. | **Low** | Med |
| **Style/behavior learning** | `style-profiler.ts` analyzes sent messages to build per-correspondent profiles. Formality scoring, greeting patterns, word count. Injected into drafts. | High | Med |
| **Agent audit log** | Tool calls logged with redacted payloads + user approval flags. Agent-to-agent delegation. Conversation persistence per entity. | **Low** | Low–Med |
| **Extension manifest system** | `mailExtension` key in `package.json`. Declarative contribution points: sidebar panels, settings, activation events. Per-extension key-value storage + TTL-based enrichment cache. | High | Med |

---

## Top 3 This Week

The three highest-impact, lowest-effort items to act on first — all changes to Dahso's own codebase:

### 1. Relative Date Filters in QueryEngine (from AppFlowy v0.11.9)

**Effort: Low | Impact: High**

Dahso's `QueryEngine` already handles date properties with `>` and `<` operators against literal dates. Add relative date tokens (`_today`, `_this_week`, `_last_7_days`, `_last_30_days`, `_this_month`) that resolve to concrete date ranges at query time. Implementation: extend the `Filter` enum or add a resolution step in `QueryEngine.execute()` that expands relative tokens before comparison. CLI syntax: `--filter "due>_last_7_days"`. This eliminates the most common friction point in temporal queries — users shouldn't need to type `2026-05-10` when they mean "last week."

### 2. Deep Link URL Scheme for External Integration (from AppFlowy #8718)

**Effort: Low | Impact: High**

Register a `dahso://` URL scheme in the macOS/iOS app supporting routes like `dahso://create?db=tasks&title=Deploy+fix&status=opt_todo` and `dahso://query?db=tasks&filter=status%3Dopt_doing`. This enables integration with Shortcuts, Raycast, Alfred, browser extensions, and any automation tool — without requiring MCP setup. Implementation: add a URL handler in the SwiftUI app's `onOpenURL` modifier that parses the route and dispatches to `MutationEngine` or `QueryEngine`. The CLI already defines the parameter space; the URL scheme is just a different transport.

### 3. FSEvents-Based Index Auto-Rebuild (from QMD `--watch` mode)

**Effort: Low | Impact: High**

When the SwiftUI app is running, watch database directories via `DispatchSource.makeFileSystemObjectSource` or `FileManager` directory monitoring. When row `.md` files change outside the app (e.g., via CLI, git pull, or another editor), automatically trigger `IndexManager.rebuild()` for the affected database. Currently, if an agent modifies files via CLI while the app is open, the UI shows stale data until manual refresh. This closes the gap between CLI and GUI without requiring IPC or polling. Implementation: one `DirectoryMonitor` class per open database, debounced to 500ms, calling `refresh()` on the `DatabaseViewModel`.

---

## Proposed Tickets

### Ticket 1: Add relative date filter tokens to QueryEngine

**Title:** Add relative date filter tokens (_today, _this_week, _last_30_days) to QueryEngine

**Description:** Extend Dahso's filter system to recognize relative date tokens that resolve at query time. Currently, filtering by date requires literal YYYY-MM-DD values, which is cumbersome for the most common queries ("what's due this week?", "what changed recently?").

Add a resolution step in `QueryEngine.execute()` that expands tokens before comparison:
- `_today` → current date
- `_yesterday` → current date - 1
- `_this_week` → Monday of current week
- `_last_7_days` → current date - 7
- `_last_30_days` → current date - 30
- `_this_month` → first of current month
- `_next_week` → next Monday

CLI usage: `dahso query tasks --filter "due>_last_7_days" --filter "due<_next_week"`

Update `DahsoCore/Engine/QueryEngine.swift` to detect and expand these tokens, and update the CLI help text. No schema changes needed — this is purely a query-time convenience.

**Effort:** Low (single-file change in QueryEngine + CLI help update)

**Source:** AppFlowy v0.11.9 release — relative date filters for database views. Users consistently request temporal shortcuts over manual date entry.

---

### Ticket 2: Register dahso:// URL scheme for external tool integration

**Title:** Register dahso:// URL scheme for Shortcuts/Raycast/automation integration

**Description:** Add a custom URL scheme handler to the macOS and iOS apps enabling external tools to create rows, open databases, and run queries without MCP or CLI access.

Routes:
- `dahso://create?db={name}&{prop}={value}` — create a row
- `dahso://open?db={name}` — open a database view
- `dahso://open?db={name}&row={id}` — open a specific row
- `dahso://query?db={name}&filter={expr}` — run a query and display results

Implementation in `Dahso/App/` (macOS) and `DahsoMobile/App/` (iOS):
1. Register the URL scheme in Info.plist
2. Add `.onOpenURL { url in ... }` handler in the app's root view
3. Parse URL components and dispatch to existing ViewModel methods
4. For `create`, call `MutationEngine`; for `query`, set filters on `DatabaseViewModel`

The CLI already defines the full parameter vocabulary — the URL scheme reuses it over a different transport. This enables Apple Shortcuts workflows, Raycast extensions, browser bookmarklets, and agent integrations that can't use the CLI (e.g., iOS Shortcuts).

**Effort:** Low (Info.plist + one URL router + dispatch to existing code)

**Source:** AppFlowy issue #8718 — deep link endpoint for external clippers. Also inspired by QMD's `qmd://` virtual path URIs.

---

### Ticket 3: Auto-rebuild database index when files change externally

**Title:** Add FSEvents directory monitoring for automatic index rebuild on external file changes

**Description:** When the SwiftUI app is running and a database's row files are modified outside the app (via CLI, git operations, or text editors), automatically detect the change and rebuild the index so the UI stays current.

Currently, if an agent creates/updates rows via `dahso create` or `dahso update`, the desktop app shows stale data until the user navigates away and back (triggering a fresh `loadIndex`). This breaks the "one core library, two consumers" promise — both consumers write, but neither notifies the other.

Implementation:
1. Add a `DirectoryMonitor` utility class using `DispatchSource.makeFileSystemObjectSource(.write)` on the database directory's file descriptor
2. Debounce events to 500ms (filesystem writes are often multi-step)
3. On trigger: call `IndexManager.isStale()` → if true, `rebuild()` → `DatabaseViewModel.refresh()`
4. Wire up in `DatabaseViewModel.init()` for each open database; tear down on deinit
5. On iOS, use `NSFilePresenter` for the same effect within the app sandbox

This closes the CLI↔GUI synchronization gap without IPC, polling, or architecture changes.

**Effort:** Low (one new utility class + ViewModel wiring)

**Source:** QMD's `--watch` mode PR (May 15, 2026) for periodic re-indexing on file changes. Also addresses the same gap AppFlowy users complain about in issue #8722 (local auto-save / cross-check).
