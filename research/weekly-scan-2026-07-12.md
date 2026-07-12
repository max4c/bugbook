# Weekly Research Scan — 2026-07-12

Repos monitored: **OpenOats**, **QMD**, **AppFlowy**, **Exo (mail-app)**
Period: July 5–12, 2026

---

## 1. OpenOats (yazinsai/OpenOats)

> Native macOS (Swift/SwiftUI) meeting note-taker with on-device WhisperKit transcription, local KB search via embeddings, and LLM-powered suggestions. 2.5k stars, MIT.

### Activity: Very High (3 releases, 10 merged PRs, 1 new issue)

| PR | What shipped | Why it matters |
|----|-------------|----------------|
| #675 | **Adaptive silence detection** — replaced fixed threshold with asymmetric EMA noise floor per mic. Unified silence timeout with sec/min picker. Extensive tests | Gold-standard pattern for any input-signal processing; the adaptive-threshold approach generalizes to auto-save idle detection |
| #682 | **Cohere Arabic transcription** — first-class cloud model for Arabic with dialect awareness, code-switching, API key validation, onboarding wizard integration | Clean example of adding a new provider to a pluggable LLM/model system |
| #678 | **Mic restart on hardware change** — observe `AVAudioEngineConfigurationChange`, auto-restart when Teams/Zoom steal mic | Pattern generalizable to any long-running hardware resource (file watchers, Bluetooth) |
| #677 | **Requesty LLM provider** (community PR) — new OpenAI-compatible router provider, mirroring OpenRouter integration | Demonstrates how easy new providers are when the interface is clean |
| #673 | **Sidecast truncation fix** — raised `sidecastMaxTokens` 700→1500; added `finish_reason: "length"` detection to append ellipsis | Good UX polish detail for any streaming LLM output |
| #680/#684 | Homebrew cask auto-updates for 1.83.1 and 1.84.1 | Mature release automation pipeline |
| #683 | **Fix notification-triggered recording** — recording via camera notification lacked transcription engine; also prevented duplicate processes via `LSMultipleInstancesProhibited` | Lifecycle management pattern for macOS apps |
| #672 | **Fix transient calendar banner** — moved `updateCalendarIntegration` before first `await` to eliminate nil-window race | Common SwiftUI async startup footgun |

**Issue #685:** Bluetooth headset reconnect stops system audio capture (mic-side fix from #678 doesn't cover the system audio tap). Shows the audio engine resilience pattern needs to cover both input streams.

### Patterns worth adapting for Bugbook

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **`@Observable` + `@MainActor` with `nonisolated(unsafe)` backing** | Swift 6.2 workaround for SwiftUI reading `@Observable @MainActor` properties without crashing. Documented in their `docs/superpowers/` specs. Every `@Observable @MainActor` class needs it. | Low | Critical |
| **Pluggable LLM provider enum** | Exhaustive switch across providers (OpenRouter, Ollama, Requesty, Cohere) with OpenAI-compatible client reuse. Adding a new provider = 1 enum case + 1 client config. | Low | High |
| **Dual-write storage** | Internal structured storage (for indexing/search) + user-facing markdown to `~/Documents/`. Gives data integrity + user ownership. | Low | High |
| **KB chunk + embed + cosine search** | `KBChunk` struct with `text`, `sourceFile`, `headerContext`. SHA256-based cache invalidation. Chunk by heading, preserve header hierarchy in each chunk. | Med | High |
| **Adaptive threshold with EMA** | Asymmetric EMA noise floor adapts to per-device characteristics. Generalizes to typing-idle detection, auto-save triggers. | Low | Med |

---

## 2. QMD (tobi/qmd)

> On-device hybrid search engine for markdown files. Combines BM25 (SQLite FTS5), vector similarity (sqlite-vec), and LLM reranking — all local. 17.2k stars, MIT. Bugbook delegates search/indexing to QMD as an external CLI tool.

### Activity: No code landed on main; 4 open/updated PRs, 5 new issues

| PR | Status | What it does | Why it matters |
|----|--------|-------------|----------------|
| #761 | **Open** | **Remote OpenAI-compatible embedding backend** — `embed` config accepts `http[s]://host:port/v1#model-id` URIs. Multi-endpoint sequential fallback with health TTL. Local GGUF as last-resort fallback. Also fixes CJK FTS rebuild "database is busy" bug. | Eliminates the ~300MB GGUF download for users with existing embedding servers |
| #504 | **Open** | **`qmd collection sync`** — mtime-first incremental re-indexing. Detects renames via hash matching and reuses embeddings. Exposes `sync()` on SDK `QMDStore` interface. | Purpose-built for Bugbook's use case — fast incremental updates without full re-index |
| #753 | **Open** | **Fix multi-get docid resolution** — resolves docids in `multi_get` / SDK `multiGet` lookups including comma-separated lists | Correctness fix for batch document retrieval |
| #496 | **Closed** (not merged) | Binary search for `findBestCutoff` and `isInsideCodeFence` (19x / 5x faster) | Perf improvement that may resurface later |

| Issue | Summary | Bugbook relevance |
|-------|---------|------------------|
| #762 | **MCP HTTP concurrency** — synchronous `better-sqlite3` + `node-llama-cpp` blocks event loop. Heavy queries block MCP `initialize` handshake. Under ~10 concurrent clients, new sessions get zero tools. | **High** if Bugbook uses MCP HTTP mode — add retry logic for `initialize` |
| #759 | **CLI vs MCP path resolution divergence** — unanchored `LIKE '%name'` suffix match can silently return wrong documents | **High** — always use full `qmd://collection/path` URIs |
| #760 | **Multi-get CSV format bug** — docid embedded inside first CSV column | **Medium** — malformed output if Bugbook parses `--format files` |
| #758 | **ternlight WASM embedding proposal** — ~5MB WASM, ~2–5ms latency, no native compilation | Watch — could simplify distribution if adopted |
| #757 | **Quoted phrase queries with dotted tokens** return no results | Low — edge case for version number searches |

### Bugbook integration notes

- **When PR #504 merges:** evaluate replacing Bugbook's re-index trigger with `qmd collection sync <name>`.
- **When PR #761 merges:** expose remote-embed config in Bugbook's settings UI.
- **Defensive action now:** normalize all QMD calls to use full `qmd://collection/path` URIs — the only form that resolves identically in both CLI and MCP transports (#759, #760).

---

## 3. AppFlowy (AppFlowy-IO/AppFlowy)

> Open-source AI-powered collaborative workspace (Flutter + Rust), 68.9k stars. Notion alternative emphasizing data privacy and local-first architecture.

### Activity: Low (0 merged PRs, 2 open PRs — both i18n, 5 new issues)

No code landed on `main` or `develop` this week. The team appears to be in a stabilization phase following v0.12.5 (June 23). The most valuable signals come from internal QA issues filed by annieappflowy/LucasXu0 targeting Q3 2026 priorities.

| Issue | Summary | Bugbook relevance |
|-------|---------|------------------|
| #8853 | **Table row drag beyond viewport** — cannot drag a row to a position outside the current scroll view | **High** — core UX challenge for any scrollable table/kanban. In SwiftUI: custom `DropDelegate` with timer-based auto-scroll at container edges |
| #8852 | **Block-level deep linking** — mention a table's copy-link-to-block not following mention style | **High** — stable per-block UUIDs + `appscheme://doc/{docId}/block/{blockId}` URIs are foundational for a PKM |
| #8851 | **Table block copy/paste** — ability to Cmd+C/V a simple table as a structured block | **High** — serialize complex blocks to custom UTType + markdown fallback |
| #8856 | **Time selector bug** — date/time picker UX issues | **Medium** — relevant for calendar view date pickers |
| #8854 | Linux installation tracker | None |

### Recent releases (for context)

| Version | Date | Key PKM-relevant changes |
|---------|------|------------------------|
| v0.12.5 | Jun 23 | Fix stale WebSocket causing disk-write failures / data loss — connection-health monitoring pattern |
| v0.12.4 | Jun 20 | Row-page comments with notifications; Kanban column color persistence; find-and-replace fixes |
| v0.12.2 | Jun 5 | Inline comments on database rows; cursor preservation during remote sync; tab management shortcuts |

### Patterns worth adapting for Bugbook

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Flush dirty state on scene phase change** | Issue #8847 (data gone after reboot) — ensure all unsaved state hits disk on `.background`/`.inactive`. Use `NSFileCoordinator` / write-ahead logging. | Low | Critical |
| **Stale connection guard** | v0.12.5 — detect stale sync connections before they silently drop writes. Ping/pong health check + buffered ops until ACK. | Med | Critical |
| **Block-level deep linking** | Assign stable UUID to every block. Generate `bugbook://db/{dbId}/row/{rowId}` URIs. Render as mention pills. | Med | High |
| **Nested block export** | PR #8738 (closed) — recursively walk children when exporting callouts/toggles to HTML/Markdown. AppFlowy's bug was skipping nested content. | Low | Med |
| **Blank toggle visual distinction** | Issue #8832 — dashed/dimmed indicator for empty toggles vs. filled arrow for toggles with children. | Low | Low–Med |

---

## 4. Exo / mail-app (ankitvgupta/mail-app)

> "Claude Code for your Inbox" — open-source AI-native desktop email client. Electron + React + TypeScript. 480 stars.

### Activity: Low (0 merged commits, 3 open PRs, 0 new issues)

| PR | Status | What it does | Why it matters |
|----|--------|-------------|----------------|
| #180 | **Open** (ready) | **Cmd+O palette for links/attachments** — extracts HTTP links and attachments from focused email. Features: dedup with punctuation trimming, Cmd+1–9 quick-select, image/PDF preview. **Extracts shared `PaletteShell.tsx` + `usePaletteSelection` hook** from duplicated command palette code. | The shared palette shell pattern is directly transferable to SwiftUI — one reusable component powering slash commands, Cmd+K navigation, link insertion |
| #181 | **Open** | **Fix account status indicator jitter** — fixed 16px slot around idle dot (8px) vs. syncing spinner (16px) to prevent layout shift | Simple but effective: fixed-size container pattern prevents jitter in any status indicator |
| #182 | **Open** | **Remove preview sidebar** — strips `EmailPreviewSidebar`, removes arrow-key handlers and palette entries | Clean feature-removal checklist (component + shortcuts + palette entries + tests) |

### Architecture deep-dive (since low weekly activity)

| Pattern | Exo implementation | Bugbook adaptation | Effort | Impact |
|---------|-------------------|-------------------|--------|--------|
| **Scoped memory system** | 4-level hierarchy: Person > Domain > Category > Global. Memories injected into LLM prompts per scope. Capped at 50–1000 per type. | Implement per-row, per-database, per-workspace, global context for AI features. Store as markdown frontmatter or index metadata. Feed relevant memories when generating summaries or answers. | Med | High |
| **Extension/plugin protocol** | Versioned API (`EXTENSION_API_VERSION = 1`), manifest-based activation, `EnrichmentProvider` / `BadgeProvider` / `SidebarPanel` registration, storage + secrets + logger APIs. | Design Swift protocols: `NoteEnrichmentProvider`, `BadgeProvider` for tags, sidebar panels for backlinks/graph. | High | High |
| **SQLite + FTS5 with WAL mode** | FTS5 virtual table on subject/body/addresses. HTML stripping before indexing. Query sanitization. Union-Find for thread merging. | Directly applicable: FTS5 for markdown note search, strip markdown before indexing, WAL for concurrent read/write. Union-Find could merge related notes via backlink clusters. | Low | High |
| **Optimistic reads / undo system** | Multiple undo queues (send, action). Store suppresses items in undo queues from display. Timer-based confirmation windows. | Implement for row operations: archive/delete/move get undo toast with 5s window. Filter pending items from row list via computed property on `DatabaseViewModel`. | Low | Med |
| **Keyboard shortcut architecture** | Single global listener, `isInputFocused()` guard, mode-based bindings, two-key sequences with timeout. | SwiftUI `.onKeyPress` with mode guards. g-prefix sequences for navigation (g-i = inbox, g-s = search). Check `NSApp.keyWindow?.firstResponder` for input focus. | Med | Med |
| **Style profiler / learner** | `style-indexer.ts` + `style-profiler.ts` learn writing style from sent content. `draft-edit-learner.ts` learns from user corrections. | Learn user's writing style from existing notes for AI-generated content. Track when users edit AI suggestions to improve future output. | Med | Med |

---

## Top 3 This Week

The three highest-impact, lowest-effort items to act on first. Each is a change to Bugbook's own codebase.

### 1. Reusable Command Palette Shell (from Exo PR #180 + AppFlowy slash menu)
**Effort: Low | Impact: High**
Build a shared `PaletteShell` SwiftUI component that powers both "/" slash commands in the block editor and "Cmd+K" quick navigation. Exo's PR #180 extracted a `PaletteShell` + `usePaletteSelection` hook from duplicated command palette code — the same extraction applies to SwiftUI. A single `PaletteViewModel` handles filtered search, keyboard selection (arrow keys + Cmd+1–9), and dismiss-on-select. The slash command menu (AppFlowy's #1 discoverability pattern) becomes one instantiation; Cmd+K note/database search becomes another. Ship the shell first, then plug in block types, formatting, and AI actions incrementally.

### 2. Scoped AI Context Injection (from Exo's 4-level memory system)
**Effort: Medium-Low | Impact: High**
Exo's scoped memory hierarchy (Person > Domain > Category > Global) maps directly to Bugbook's structure: Row > Database > Workspace > Global. When AI features generate summaries, answer questions, or suggest tags, inject context from the row's properties, the database schema (property definitions and option names), any workspace-level `AGENTS.md` instructions, and global user preferences. Store scoped context hints as a `_context.md` file alongside `_schema.json` in each database folder (similar to QMD's collection context metadata pattern from the March scan). This makes AI output immediately more relevant without per-prompt engineering.

### 3. Normalize QMD Integration to Full `qmd://` URIs (from QMD #759, #760)
**Effort: Low | Impact: High**
QMD issues #759 and #760 reveal that bare filenames in `multi-get` resolve differently between CLI and MCP transports — an unanchored `LIKE '%name'` suffix match can silently return the wrong document, and the CSV output format embeds docids incorrectly in the first column. The fix is entirely in Bugbook's code: normalize every QMD call to use full `qmd://collection/path` URIs, the only form that resolves identically in both transports. This also future-proofs against transport switches (CLI → MCP HTTP) and makes document references stable across collection renames.

---

## Proposed Tickets

### Ticket 1: Add reusable PaletteShell component for slash commands and Cmd+K

**Title:** Add reusable PaletteShell component for slash commands and Cmd+K

**Description:** Create a shared `PaletteShell` SwiftUI view and `PaletteViewModel` that provides:
- Filtered search over a generic list of `PaletteItem` (icon + title + subtitle + action)
- Keyboard navigation (arrow keys, Cmd+1–9 quick-select, Enter to confirm, Escape to dismiss)
- Overlay positioning (anchored below cursor for "/" trigger, centered for Cmd+K)

Instantiate it twice initially:
1. **Slash command menu** — triggered by "/" in the block editor body. Items: heading levels, todo, callout, divider, database embed. Renders as a filtered dropdown below the cursor.
2. **Cmd+K quick open** — triggered by Cmd+K globally. Items: all databases and recent rows. Renders as a centered modal overlay.

The shell is the reusable foundation; block types and AI actions get added incrementally without touching the shell code.

**Effort:** Low (2–3 days for the shell + two instantiations)

**Source:** [Exo PR #180](https://github.com/ankitvgupta/mail-app/pull/180) — `PaletteShell.tsx` + `usePaletteSelection` hook extraction; [AppFlowy slash command menu](https://github.com/AppFlowy-IO/AppFlowy) — "/" as the standard discoverability pattern for block editors

---

### Ticket 2: Add scoped AI context injection with per-database `_context.md`

**Title:** Add scoped AI context injection with per-database `_context.md`

**Description:** Implement a 3-level context hierarchy for AI features (row → database → workspace):
1. **Row context:** the row's own properties and body (already available via `QueryEngine`)
2. **Database context:** a new optional `_context.md` file alongside `_schema.json`. Contains free-text semantic hints about the database (e.g., "These are engineering tasks for the Bugbook Swift project. Priority should reflect user-facing impact."). Loaded by `DatabaseStore` alongside schema.
3. **Workspace context:** the existing `AGENTS.md` file at workspace root.

When any AI action runs (summarize, suggest tags, answer question), the relevant context layers are concatenated and injected into the prompt. This is the same pattern as QMD's collection context metadata (per-folder semantic hints injected into search without modifying notes) and Exo's 4-level scoped memory system.

Add a `ContextResolver` to `BugbookCore/Engine/` that assembles context for a given row ID:
```swift
struct ContextResolver {
    func resolve(rowId: String, databaseId: String, store: DatabaseStore) -> [ContextLayer]
}
```

**Effort:** Medium-Low (2–3 days — file loading is trivial; the value is in the prompt assembly)

**Source:** [Exo scoped memory system](https://github.com/ankitvgupta/mail-app) — `style-indexer.ts`, 4-level Person > Domain > Category > Global hierarchy; [QMD collection context metadata](https://github.com/tobi/qmd) — per-folder semantic hints

---

### Ticket 3: Normalize all QMD calls to use full `qmd://` URIs

**Title:** Normalize all QMD calls to use full `qmd://` URIs

**Description:** Audit and update every call site in Bugbook that invokes QMD (CLI or MCP) to pass full `qmd://collection/path` URIs instead of bare filenames or relative paths. QMD issues #759 and #760 document that:
- CLI and MCP have divergent path-resolution logic for bare names (unanchored `LIKE '%name'` suffix match)
- `multi-get --format files` embeds docids incorrectly in the first CSV column when using bare names
- `LIMIT 1` with no `ORDER BY` makes cross-collection matches arbitrary

The fix is a `QMDURIBuilder` utility in `BugbookCore/` that constructs canonical `qmd://collection/path` URIs from a database path and row filename:
```swift
struct QMDURIBuilder {
    static func uri(collection: String, path: String) -> String
}
```

All existing QMD call sites (search, get, multi-get) should route through this builder. Add a test that verifies URI format.

**Effort:** Low (1 day — utility + find-and-replace call sites)

**Source:** [QMD #759](https://github.com/tobi/qmd/issues/759) — CLI vs MCP path resolution divergence; [QMD #760](https://github.com/tobi/qmd/issues/760) — multi-get CSV format bug with bare names
