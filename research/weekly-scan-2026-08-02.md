# Weekly Research Scan — 2026-08-02

Repos monitored: **OpenOats**, **QMD**, **AppFlowy**, **mail-app (Exo)**
Period: July 26 – August 2, 2026

---

## 1. OpenOats (yazinsai/OpenOats)

> Native macOS (Swift/SwiftUI) meeting companion app with on-device transcription (WhisperKit, Parakeet, Cohere, etc.), local knowledge-base search, and LLM-powered suggestions. MIT.

### Activity: Low (1 commit, July 19 — none in scan window)

The single recent commit (#687) fixes system audio silently dying after Bluetooth output reconnect. Earlier July activity (July 8) shipped Cohere Arabic transcription support and notification-triggered recording startup fixes. The project is in stabilization mode — polishing hardware edge cases and broadening language support.

### Architecture Deep Dive

Since activity was low, I analyzed the codebase for patterns:

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Pure state machine** | `MeetingState` is a three-state enum (idle/recording/ending) driven by `MeetingEvent`. The `transition()` function is pure — zero side effects. `AppCoordinator` dispatches side effects *after* the transition. Clean, testable, and directly applicable to Dahso's capture/sync/editing states. | Low | High |
| **Coordinator + Container separation** | `AppContainer` owns bootstrapping and lazy service init. `AppCoordinator` owns the state machine and event loops. Services injected via constructor or factory methods (`makeViewServices()` / `makeRecordingServices()`). No DI framework. | Med | Med |
| **Protocol-based backend abstraction** | `TranscriptionBackend` protocol with `checkStatus()`, `prepare()`, `transcribe()` — six conforming backends. Clean strategy pattern for pluggable providers. | Low | High |
| **Swift 6 @Observable with fine-grained control** | Manual `@ObservationIgnored` + `nonisolated(unsafe)` backing stores with explicit `access()`/`withMutation()` calls. Views only re-render on specific property changes. | Low | Med |
| **Settings with Keychain isolation** | Regular prefs via `UserDefaults`; secrets via `secretStore` with lazy loading. Test isolation through `.ephemeral` secret store and custom `UserDefaults` suite names. | Low | Med |
| **Baked-in UI test mode** | `AppRuntimeMode` enum (`.live` vs `.uiTest(scenario)`) configures the entire dependency graph at bootstrap, including scripted utterances and in-memory storage. | Med | Med |

---

## 2. QMD (tobi/qmd)

> On-device hybrid search engine for markdown files. Combines BM25 (SQLite FTS5), vector similarity (sqlite-vec), and LLM reranking — all local. By Tobi Lütke. MIT.

### Activity: Low (0 commits in scan window; v2.6.3 released June 24)

No new activity this week. The most recent release (v2.6.3) shipped several fixes relevant to Dahso:

| Change | What it means for Dahso |
|--------|------------------------|
| **SQLite busy timeout fix** | Concurrent qmd operations (e.g., `update` racing `embed`) no longer crash with "database is locked." Default 120s timeout, configurable via `QMD_SQLITE_BUSY_TIMEOUT`. If Dahso fans out concurrent qmd calls, this is critical. |
| **Special-character path fix** | Filenames with `#`, `&`, spaces, `[]` now survive the index/search/get round-trip. Existing indexes auto-migrate on `qmd update`. Dahso should run `qmd update` after upgrading. |
| **Embed timeout flag** | `qmd embed --timeout <minutes>` lets large indexes finish in one run instead of hitting the 30-minute cap. Useful for initial workspace indexing. |
| **MCP `collections` parameter** | Must use plural `collections` (array), not singular `collection`. Zod silently strips the wrong key and searches everything. |

### MCP Server Capabilities (4 tools)

1. **`query`** — Primary search. Accepts plain `query` string (auto-expanded into lex/vec/hyde) or typed `searches` array. Supports `intent`, `collections` scope, `limit`, `minScore`, `rerank` toggle. Returns docid, path, title, score, context, line number, snippet.
2. **`get`** — Single document retrieval by path or docid (`#abc123`). Supports line-range suffix (`file.md:100:40`). Fuzzy-match suggestions on miss.
3. **`multi_get`** — Batch retrieval by glob or comma-separated list, with `maxBytes`/`maxLines` limits.
4. **`status`** — Index health: total documents, embedding gaps, collection list with doc counts.

### Query Syntax Features for Dahso's UI

- **Auto-expand** (default): plain text generates lex+vec+hyde variants — simplest for users
- **Lex modifiers**: prefix matching, `"exact phrase"`, `-negation`
- **Intent annotation**: disambiguates vague queries (e.g., "performance" + intent "web page load times") — could be surfaced as an optional "context" field
- **Collection scoping**: filter search to specific collections

### Indexing Patterns

- Content-hash dedup: only re-index when hash changes; title-only changes get lightweight update
- Soft-delete for removed files; orphaned content cleaned up afterward
- Paths stored verbatim (no slug-ification — the v2.6.3 fix was a bug from the opposite approach)
- 900-token chunks with 15% overlap, scored break-point detection (headings, code fences, paragraph boundaries)

---

## 3. AppFlowy (AppFlowy-IO/AppFlowy)

> Open-source Notion alternative built with Flutter + Rust. 68.9k stars. AGPL.

### Activity: Very Low (last commit June 26 — i18n revert; last feature work March 2026)

The project has been largely dormant on the default branch since early 2026.

### Architecture Deep Dive

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Cell skin system** | Each cell type (text, number, checkbox, date, select_option, URL, relation, etc.) has an `EditableCellWidget` and an abstract "skin" interface. A factory `fromStyle(EditableCellStyle)` switches between four rendering modes: `desktopGrid`, `desktopRowDetail`, `mobileGrid`, `mobileRowDetail`. Cleanly separates cell behavior from presentation context. In SwiftUI, this maps to a protocol like `CellSkin` with `tableRow`, `rowDetail`, `kanbanCard` cases. | Med | **High** |
| **Generic CellController** | `CellController<DataType, SaveDataType>` with typed aliases (e.g., `DateCellController = CellController<DateCellDataPB, String>`). Each controller takes a `CellDataLoader` (with parser) and `CellDataPersistence`. Clean separation of load/parse/persist. | Med | High |
| **Shared DatabaseController** | Single source of truth for all views. Each layout (grid, board, calendar) is a plugin registered via `DatabaseTabBarItemBuilder` providing `content()` and `settingBar()`. Tab bar switches views of the same data. | Med | Med |
| **Board/Kanban via GroupController** | `BoardBloc` wraps `DatabaseController`, uses `AppFlowyBoardController` for drag-and-drop. Groups managed via `GroupController` in a `LinkedHashMap`. Board delegates `moveGroup`/`moveGroupRow` back to `DatabaseController`. | High | Med |
| **Plugin registry** | Lightweight `Plugin`/`PluginBuilder` with `PluginType` enum (document, grid, board, calendar, chat). Compile-time registration, not dynamic. | Low | Low |

---

## 4. mail-app / Exo (ankitvgupta/mail-app)

> Open-source AI-native desktop email client (Electron/React/TypeScript). Every email is automatically analyzed, prioritized, and optionally auto-drafted before the user opens it. Supports multiple AI agent providers.

### Activity: Low (6 commits July 14–15 — none in scan window)

Recent July activity focused on agent provider infrastructure:

| PR | What shipped | Why it matters |
|----|-------------|----------------|
| #187 | Consolidate background agent provider selection into General settings | Unified settings UX for agent configuration |
| #185 | Configurable default agent provider for background auto-drafts | Provider selection is no longer hardcoded |
| #183 | Hostler hosted cloud backend for agent sidebar | New cloud-hosted agent provider option |
| #186 | Fix test cleanup deleting production exo config | Test isolation improvement |
| #184 | Show Hostler settings save feedback | UX polish for settings |
| #181 | Fix account status indicator jitter | UI polish |

### Architecture Deep Dive: Agent Provider System

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Interface + Registry + Orchestrator** | `AgentProvider` protocol with `run()` (async generator), `cancel()`, `isAvailable()`, `updateConfig()`. Providers register with a Map-based `AgentProviderRegistry`. `AgentOrchestrator` routes commands to selected providers. Three clean layers. | Med | **High** |
| **AsyncGenerator streaming** | Providers yield `AgentEvent` discriminated unions (`text_delta`, `tool_call_start/end`, `state`, `error`, `done`). Uniform streaming contract across local and remote providers. | Med | High |
| **Graceful fallback resolution** | `resolveBackgroundAgentProviderId()` checks config gates and `isAvailable()` at call time, falling back to a default rather than failing silently. Both main process and renderer share the same resolver. | Low | High |
| **Sub-agent tool injection** | Providers implementing `asSubAgentTool()` are automatically registered as tools for the orchestrating agent. Enables agent-to-agent delegation without explicit wiring. | Med | Med |
| **Utility process isolation** | Agent orchestrator runs in an Electron utility process, communicating via typed IPC (`WorkerMessage`/`CoordinatorMessage`). Keeps agent work off the UI thread. Swift equivalent: background actor or XPC service. | Med | Med |

---

## Top 3 This Week

The three highest-impact, lowest-effort items to act on first — all changes to Dahso's own codebase:

### 1. Add Cell Rendering Context Protocol (from AppFlowy's cell skin system)
**Effort: Medium | Impact: High**

Dahso's database views (table, kanban, calendar, list) each need to render the same cell types differently — a status select in a table row is a colored pill, on a kanban card it's a badge, in row detail it's a full dropdown. AppFlowy solves this with a `CellSkin` abstraction: one protocol per cell type with factory methods for each rendering context. In SwiftUI, define a `CellRenderingContext` enum (`.tableRow`, `.kanbanCard`, `.rowDetail`, `.listItem`) and a `CellView` that switches on `(PropertyType, CellRenderingContext)` to pick the right view. This prevents the combinatorial explosion of per-view-per-type cell views.

### 2. Add Agent Provider Protocol to Agent Ops Layer (from mail-app's provider architecture)
**Effort: Medium | Impact: High**

Dahso's Agent Ops layer currently models tasks/runs/events as files but doesn't abstract over *who* runs the agent. mail-app's three-layer pattern (Provider protocol + Registry + Orchestrator) cleanly separates the "what" from the "who." Define an `AgentProvider` protocol in BugbookCore with `run(task:) async throws -> AsyncStream<AgentEvent>`, `isAvailable() -> Bool`, and `cancel()`. Register providers (Claude, Ollama, local script) in a `ProviderRegistry`. The existing `AgentCommand` becomes a thin orchestrator that resolves the provider and streams events to `events.jsonl`.

### 3. Adopt Pure State Machine Pattern for App Lifecycle (from OpenOats)
**Effort: Low | Impact: High**

OpenOats' `MeetingState` pattern — a pure `transition(state, event) -> state` function with side effects dispatched *after* by the coordinator — is directly applicable to Dahso's app lifecycle. Define a `WorkspaceState` enum (`.loading`, `.ready`, `.syncing`, `.error`) with `WorkspaceEvent` inputs. The `transition()` function is a pure switch with no side effects, making it trivially testable. The `AppCoordinator` (or ViewModel) calls `transition()` and then dispatches side effects (index rebuild, qmd sync, UI updates) based on the new state. This replaces scattered boolean flags with an explicit, exhaustive state graph.

---

## Proposed Tickets

### Ticket 1: Add CellRenderingContext protocol for multi-view cell rendering

**Title:** Add CellRenderingContext protocol for multi-view cell rendering

**Description:** Introduce a `CellRenderingContext` enum (`.tableRow`, `.kanbanCard`, `.rowDetail`, `.listItem`) and a `CellViewFactory` that returns the appropriate SwiftUI view for a given `(PropertyType, CellRenderingContext)` pair. This replaces ad-hoc per-view cell rendering with a systematic approach that scales as new view types are added.

Inspired by AppFlowy's `EditableCellSkin` system, where each cell type has an abstract skin interface with a `fromStyle()` factory that switches between desktop grid, row detail, mobile grid, and mobile row detail rendering modes. The skin separates cell behavior from presentation context.

Add to `Sources/Bugbook/Views/` — a new `CellViews/` directory with:
- `CellRenderingContext.swift` — the enum
- `CellViewFactory.swift` — the factory
- Per-type view files (`SelectCellView.swift`, `TextCellView.swift`, etc.) each handling all contexts via a switch

**Effort:** medium

**Source:** AppFlowy `frontend/appflowy_flutter/lib/plugins/database/widgets/cell/editable_cell_builder.dart` — the `EditableCellBuilder.buildStyled()` method and `IEditableCellSkin` interfaces

---

### Ticket 2: Add AgentProvider protocol and registry to Agent Ops layer

**Title:** Add AgentProvider protocol and provider registry to BugbookCore

**Description:** Define an `AgentProvider` protocol in `Sources/BugbookCore/Model/` with:
- `func run(task: AgentTask, context: AgentRunContext) async throws -> AsyncStream<AgentEvent>`
- `func isAvailable() -> Bool`
- `func cancel(runId: String)`
- `var config: AgentProviderConfig { get }`

Add a `ProviderRegistry` class in `Sources/BugbookCore/Engine/` that holds registered providers and resolves which one to use based on user config + availability checks (graceful fallback if preferred provider is unavailable).

Update `AgentCommand.swift` to resolve the provider from the registry before starting a run, and stream `AgentEvent` values to `events.jsonl` as they arrive.

Inspired by mail-app (Exo)'s `AgentProvider` interface + `AgentProviderRegistry` + `AgentOrchestrator` three-layer architecture, which cleanly supports Claude, Ollama, OpenCode, and Hostler providers behind a single streaming interface.

**Effort:** medium

**Source:** mail-app `src/main/agents/types.ts` (AgentProvider interface), `src/main/agents/orchestrator.ts` (AgentOrchestrator with registry)

---

### Ticket 3: Add pure WorkspaceState machine for app lifecycle

**Title:** Add pure WorkspaceState state machine for app lifecycle management

**Description:** Introduce a `WorkspaceState` enum and `WorkspaceEvent` enum in `Sources/BugbookCore/Model/` with a pure `transition(state:event:) -> WorkspaceState` function. States: `.uninitialized`, `.loading`, `.ready`, `.syncing`, `.error(Error)`. Events: `.workspaceFound`, `.indexLoaded`, `.syncStarted`, `.syncCompleted`, `.errorOccurred(Error)`, `.retry`.

The transition function is a pure switch statement with no side effects — making it trivially unit-testable. The `AppCoordinator` (or main ViewModel) calls `transition()` and dispatches side effects (index rebuild, qmd sync, UI state updates) based on the resulting state.

Inspired by OpenOats' `MeetingState` pattern at `OpenOats/Sources/OpenOats/Domain/MeetingState.swift`, where a three-state enum driven by `MeetingEvent` keeps all state transitions explicit and testable, with the coordinator handling side effects separately.

**Effort:** low

**Source:** OpenOats `OpenOats/Sources/OpenOats/Domain/MeetingState.swift` — pure `transition()` function pattern
