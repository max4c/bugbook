# Weekly Research Scan — 2026-06-28

Repos monitored: **OpenOats**, **QMD**, **AppFlowy**, **Exo (mail-app)**
Period: June 21–28, 2026

---

## 1. OpenOats (yazinsai/OpenOats)

> Native macOS (Swift 6.2/SwiftUI) meeting note-taker with on-device WhisperKit transcription, local knowledge-base search via embeddings, and LLM-powered suggestions. 2.5k stars, MIT. Currently at v1.82.0.

### Activity: Low-Moderate (3 commits, 2 merged PRs, 4 active issues)

| PR | What shipped | Why it matters |
|----|-------------|----------------|
| #664 | **Fix system audio tap race on USB/Bluetooth devices** — two-layer retry (inner: 40 attempts × 75ms, outer: 3 tap recreations), cooperative async cancellation via `Task.sleep`, immediate resource ID registration | Gold-standard pattern for resilient hardware integration in Swift concurrency. Resolved 4 open issues. |
| #666 | **Stamp bundle version from git tag** — `git describe --tags --abbrev=0` injects version into built bundle without modifying source plist, env-var override for CI | Clean build/release pattern for Sparkle auto-update apps |

**Active issues:** #668 (sidebar text truncation + message persistence request), #667 (audio tap format failure, reopened), #665 (ElevenLabs diarization limited to 2 speakers), #651 (mic not recording)

### Patterns worth adapting for Bugbook

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Multi-provider LLM protocol** | `OpenRouterClient`, native OpenAI/Anthropic clients, LM Studio, Ollama auto-discovery. All features route through selected provider. | Med | Very High |
| **Dual embedding strategy** | `OllamaEmbedClient` for local, `VoyageClient` for cloud, unified `KnowledgeBase` orchestrator over Markdown files. `PreFetchCache` for performance. | Med–High | Very High |
| **Burst/decay API throttle** | `BurstDecayThrottle.swift` + `RealtimeGate.swift` — rate limiting with decay for API calls, latency control for streaming responses. Essential for real-time AI features. | Low | Med |
| **Overlay/mini-bar panel** | `OverlayPanel.swift` + `MiniBarPanel.swift` — floating compact UI modes for quick capture. | Med | Med–High |
| **Template system** | `TemplateStore.swift` — reusable note templates with customizable Markdown output. | Low | Med |
| **Repository + importer pattern** | `SessionRepository.swift` with `LegacySessionReader` migration and `GranolaImporter`. Clean import/migration for bringing in data from other tools. | Med | High |

---

## 2. QMD (tobi/qmd)

> On-device hybrid search engine for markdown files. Combines BM25 (SQLite FTS5), vector similarity (sqlite-vec), and LLM reranking — all local via node-llama-cpp with GGUF models. MIT. By Tobi Lütke.

### Activity: High (v2.6.3 released June 24 — 13 merged PRs in one cycle)

| PR | What shipped | Why it matters |
|----|-------------|----------------|
| #686 | **SQLite concurrent opens safety** — `PRAGMA busy_timeout = 120000ms`, versioned IMMEDIATE transactions for trigger rebuild, WAL retry logic | **Critical for Bugbook:** prevents SQLITE_BUSY crashes when CLI + app write simultaneously |
| #737 | **CJK FTS rebuild OOM fix** — `Statement.iterate()` in 500-row streaming batches, shadow table + atomic swap for crash safety | Fixes crash on large CJK note collections |
| #731 | **Plain `query` MCP parameter** — simple string alternative to structured `searches` array, auto-routed through expand → RRF fuse → rerank pipeline | **Huge ergonomic win:** send a plain string instead of constructing typed sub-queries |
| #708 | `--timeout` flag for embedding sessions | Large vaults can exceed default 30-min cap |
| #677 | `--host` flag for MCP HTTP server | Enables running qmd as a network-accessible daemon |
| #701 | Report ignored documents during indexing | Clearer feedback for users |
| #729 | Fix bun global install detection | Launcher reliability |

**Notable open PRs:**

| PR | What's coming | Bugbook relevance |
|----|--------------|-------------------|
| #703 | **Path filtering + explain metadata** — `pathPrefix` restricts search to subfolder, `explain` flag returns per-result score breakdown | Folder-scoped search in editor; search quality transparency UI |
| #705 | **OpenAI-compatible remote LLM** — `RemoteLLM` class with circuit breakers, `HybridLLM` routes embed/generate independently | "Bring your own inference" for power users |
| #663 | **Shared model server** — `qmd serve` centralizes GGUF models, multiple clients share warm instances, `--low-vram` mode | Critical for memory-constrained laptops (16GB) |

**Notable issues:**
- #747: Qwen3 reranker double-sigmoid compresses scores to [0.5, 0.73] — ordering is correct but discrimination is reduced. Upstream fix pending (node-llama-cpp #617).
- #735: Metal shader JIT failure on M5 Max + macOS 26.4 — upstream llama.cpp issue.
- #717: `QMD_EDITOR_URI` broken with spaces in paths — relevant if Bugbook registers a URI scheme for "click to open."

### Patterns worth adapting for Bugbook

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **MCP HTTP daemon mode** | `qmd mcp --http --daemon --port 8181` — persistent process, plain `query` string, JSON output. Replaces cold CLI invocations. | Low | High |
| **Path-prefix filtering** (PR #703, coming soon) | Restrict search to a subfolder — enables project/notebook-scoped search in the editor. | Med | High |
| **Collection context metadata** | Per-folder semantic hints ("these are daily notes" vs "project docs") injected into search without modifying note files. | Low | Med |
| **Editor URI scheme** | `bugbook://open?file={path}&line={line}` for deep-linking from qmd results. Fix upstream #717 or URL-encode in Bugbook. | Low | Med |

**Upgrade note:** Bugbook should update to qmd ≥ 2.6.3 to get the SQLite concurrency fix (#686) and CJK OOM fix (#737). This is a dependency update, not a Bugbook code change.

---

## 3. AppFlowy (AppFlowy-IO/AppFlowy)

> Open-source AI-powered collaborative workspace (Flutter + Rust), 68.9k stars. Notion alternative emphasizing data privacy and local-first architecture.

### Activity: Low (1 commit to main, v0.12.5 hotfix release)

**v0.12.5** (June 23) — Critical patch: fixed a WebSocket connection issue that could cause writes to disk to fail, leading to **data loss in rare cases**.

Only commit to main: `5cf3a36` — "chore: revert en-US i18n change (#8838)" (June 26). Stabilization phase following the hotfix.

**Community activity** concentrated on internationalization (Russian, Japanese, Spanish translations — PRs #8841, #8837, #8833) and unmerged feature PRs.

**Notable open PRs:**

| PR | Feature | Relevance to Bugbook |
|----|---------|---------------------|
| #8773 | **Multi-row grid selection** — ChangeNotifier-based selection controller with drag, shift-click, Ctrl+A. Centralized `GridSize` constants. | High — directly applicable to Bugbook's table view |
| #8819 | Copy text action for toggle/list blocks via 3-dot menu | Med — common user request for block editors |
| #8755 | Toggle expand/collapse in read-only mode (separate `_readOnlyCollapsed` state) | Med — smart pattern for preview/publish modes |
| #8805 | Fix search box losing focus during find-and-replace (delayed focus restore) | Low–Med — common rich-text editor problem |
| #8783 | Guillemet auto-formatting (`<<`/`>>`) via reusable `_handleDoubleCharacterReplacement` | Low — shows value of extensible shortcut system |

**Performance PR series** (danteboe, open):

| PR | Optimization | Swift equivalent |
|----|-------------|-----------------|
| #8734 | Canonicalize const widgets to reduce rebuild churn | `EquatableView` / `@State` with manual cache invalidation |
| #8728 | Stream-serialize RAG IDs to avoid intermediate Vec allocations | `AsyncSequence`-based serialization |
| #8731 | SvgPicture cache keyed by path+size | `NSImage`/`UIImage` cache by asset name |
| #8730 | Thread-local buffer reuse for JSON log serialization | `Thread.current.threadDictionary` or actor-isolated buffers |

**Notable issues (June 21–28):**
- #8830/#8835: Korean IME input duplication on Windows and Linux — CJK input handling remains a cross-platform challenge
- #8831: Android editing sluggishness on text-heavy pages — viewport-based lazy rendering needed
- #8832: Notion-like visual distinction between empty and populated toggle blocks
- #8839: Password changes don't invalidate existing sessions — security gap relevant if Bugbook adds cloud sync

### Patterns worth adapting for Bugbook

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Multi-row drag selection** | Selection controller + centralized row height constants. Directly applicable to Bugbook's table view. | Med | High |
| **Read-only toggle state separation** | Separate `_readOnlyCollapsed` state from document state — useful for preview/embed modes of database views. | Low | Med |
| **Data-integrity lesson** | v0.12.5 confirms: **never gate local writes on network/WebSocket status**. Bugbook's atomic-write-then-rename approach is correct; validate it extends to any future sync layer. | N/A | Critical |
| **i18n with structured JSON per locale** | ~2,776 keys in community-contributed locale files. If Bugbook goes multi-language, this is the proven pattern. | Med | Med |

---

## 4. Exo / mail-app (ankitvgupta/mail-app)

> Open-source AI-native desktop email client ("Claude Code for your Inbox"). Electron + React + TypeScript + Tailwind, ProseMirror editor, SQLite + FTS5 local persistence. 475 stars, MIT.

### Activity: Moderate (3 commits, 3 merged PRs, 2 closed PRs)

| PR | What shipped | Why it matters |
|----|-------------|----------------|
| #166 | **Ollama Cloud model-picker dropdown** — 7 curated models (GLM 5.2 default) + "Custom" escape hatch for arbitrary model IDs | Clean "curated + custom" UX pattern for LLM selection |
| #179 | **Fix installed agent provider config** — `loadProvider()` now receives enriched config, fixing `not_configured` status for installed agents (e.g., YC agent) | Agent registry/config pattern |
| #178 | **Pre-PR gate: accept inconclusive verdict for dependency-only diffs** — extracts reusable `isNoUiSurfaceDiff()` classifier | CI/tooling pattern for agentic verification |

**Notable open PRs:**
- #169: AI calendar invite editor — AI parses email threads → structured editable form (meeting details)
- #171: Split-tab keyboard shortcut (Superhuman mirror) — Tab/Shift+Tab cycling
- #170: Fix snooze in All Inboxes (cross-account operation)

### Patterns worth adapting for Bugbook

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Extension manifest + protocol** | Declarative `ExtensionManifest` (Zod-validated) + `ExtensionModule` with `activate()`/`deactivate()` lifecycle. Enrichment providers, badge providers, sidebar panels, settings contributions. | Med | High |
| **"Curated + Custom" model picker** | Dropdown with known-good models prominently listed + free-text input for custom model IDs. The right UX for LLM selection in any app. | Low | High |
| **Agent coordinator / permission gate / audit log** | Coordinator dispatches, workers execute, permission gate enforces, audit log records. Separation prevents AI footguns. | High | High |
| **AI extraction to editable structured form** | AI proposes structured output (calendar event), user reviews/edits, then confirms. Directly applicable to note → task extraction. | Med | High |
| **Keyboard shortcut modes** | Dual shortcut schemes (Gmail vs Superhuman). Power users expect configurable keyboard bindings. | Med | Med–High |
| **Optimistic reads** | Show local state immediately, reconcile with server later. Relevant for any future sync layer. | Low | Med |

---

## Top 3 This Week

The three highest-impact, lowest-effort items to act on first — all changes to Bugbook's own codebase:

### 1. Add global search bar backed by qmd MCP HTTP (from QMD PR #731, #677)
**Effort: Low | Impact: High**
qmd v2.6.3 ships a plain `query` string parameter for MCP search and supports persistent HTTP daemon mode (`qmd mcp --http --daemon`). Bugbook should add a `QMDSearchService` in BugbookCore that connects to the daemon endpoint and a Cmd+K search bar in the SwiftUI frontend. Send a single string, get back ranked results with file paths and snippets — no need to construct typed sub-queries. The search bar replaces shelling out to the CLI (cold start per query) with a persistent HTTP connection.

### 2. Add LLM provider protocol with model-picker settings UI (from OpenOats + Exo PR #166)
**Effort: Low–Medium | Impact: High**
Both OpenOats and Exo independently converged on protocol-based multi-provider LLM abstractions. Bugbook should define an `LLMProvider` Swift protocol in BugbookCore with implementations for Claude, OpenAI, and Ollama. Pair it with a Settings tab using the "curated + custom" model-picker UX from Exo (dropdown of known-good models + free-text input for custom model IDs). This unlocks AI features (summarize notes, extract tasks, "chat with your notes") without locking users to a single provider.

### 3. Add multi-row drag selection to table database view (from AppFlowy PR #8773)
**Effort: Low–Medium | Impact: High**
AppFlowy's open PR #8773 implements click-and-drag multi-row selection in grid views with a centralized selection controller, shift-click range extension, and Cmd+A select-all. Bugbook's table view currently edits one row at a time. Adding a `SelectionController` class and multi-select gestures enables bulk operations (batch status update, bulk delete, multi-row drag-to-kanban). The pattern is straightforward in SwiftUI with `DragGesture` + a `Set<RowID>` selection model.

---

## Proposed Tickets

### Ticket 1: Add Cmd+K global search bar with qmd MCP HTTP backend

**Title:** Add Cmd+K global search bar backed by qmd MCP HTTP daemon

**Description:**
Add a `QMDSearchService` class to `BugbookCore/` that connects to qmd's MCP HTTP endpoint (default `localhost:8181`) and sends search queries using the new plain `query` string parameter. Add a `SearchBarView` to the SwiftUI desktop app triggered by Cmd+K that displays ranked results (title, path, snippet, relevance score) and navigates to the selected row/page on selection.

The service should:
- Discover/start the qmd daemon if not running (or surface a "start qmd" prompt)
- Use the plain `query` parameter from qmd PR #731 (no structured sub-queries needed)
- Parse JSON results and map to Bugbook's `Row` / page types
- Support cancellation (debounce keystrokes, cancel in-flight requests)

This replaces per-query CLI invocation with a persistent HTTP connection, eliminating cold-start latency.

**Effort:** Low

**Source:** [qmd PR #731 — feat(mcp): plain `query` param](https://github.com/tobi/qmd/pull/731), [qmd PR #677 — feat(mcp): --host flag](https://github.com/tobi/qmd/pull/677)

---

### Ticket 2: Add LLM provider protocol and model-picker settings

**Title:** Add LLMProvider protocol with model-picker settings UI

**Description:**
Define an `LLMProvider` protocol in `BugbookCore/` with `sendMessage()`, `streamMessage()`, and `listModels()` methods. Create concrete implementations for:
- Claude (Anthropic API)
- OpenAI-compatible (covers OpenAI, local servers)
- Ollama (auto-discover local models)

Add a "Models" tab to the macOS Settings view with:
- Provider selector dropdown
- "Curated + Custom" model picker (dropdown of known-good models per provider + free-text input for arbitrary model IDs, following Exo's UX pattern)
- API key / base URL fields per provider
- "Test connection" button

Store configuration in the workspace config. This protocol becomes the foundation for all AI features (summarization, task extraction, "chat with your notes").

**Effort:** Low–Medium

**Source:** [Exo PR #166 — Ollama Cloud model-picker dropdown](https://github.com/ankitvgupta/mail-app/pull/166), [OpenOats multi-provider architecture](https://github.com/yazinsai/OpenOats/tree/main/Sources/OpenOats/Intelligence)

---

### Ticket 3: Add multi-row selection to table database view

**Title:** Add multi-row drag selection to table database view

**Description:**
Add a `SelectionController` (or `@Observable` class) to `Bugbook/ViewModels/` that tracks a `Set<String>` of selected row IDs. Wire it into the table database view with:
- Click to select single row
- Shift+click to extend selection range
- Cmd+click to toggle individual row in selection
- Click+drag to select a range of rows
- Cmd+A to select all visible rows
- Escape to clear selection

When multiple rows are selected, show a floating action bar with bulk operations: "Set Status", "Set Priority", "Delete", "Move to…" — all routed through `MutationEngine.execute()` as a single batch mutation (one index update, per ARCHITECTURE.md design).

**Effort:** Low–Medium

**Source:** [AppFlowy PR #8773 — Multi-row grid selection](https://github.com/AppFlowy-IO/AppFlowy/pull/8773)
