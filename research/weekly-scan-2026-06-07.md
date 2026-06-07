# Weekly Research Scan — 2026-06-07

Repos monitored: **OpenOats**, **QMD**, **AppFlowy**, **Exo (mail-app)**
Period: May 31–June 7, 2026

---

## 1. OpenOats (yazinsai/OpenOats)

> Native macOS (Swift/SwiftUI) meeting note-taker with on-device WhisperKit transcription, local knowledge-base search via embeddings, and LLM-powered suggestions. 2.4k stars, MIT.

### Activity: Low (0 commits, 0 merged PRs, 10 issues updated)

No code shipped this week — last commit was May 23. Community engagement continues with bug reports and feature requests:

| Issue | What's happening | Why it matters |
|-------|-----------------|----------------|
| #649 | Import Meeting Recordings silently fails — progress bar completes but no transcript appears | Highlights fragility of background-process-to-UI handoff |
| #648 | Request for Speechmatics API as transcription backend | Users want more ASR provider choices |
| #646 | Meeting title renaming UX — button too hidden, requests AI-auto-naming | Smart-titling is a universal PKM need |
| #644 | Request for FunASR/SenseVoice — self-hosted, 5–10× faster, 50+ languages, speaker diarization | Local ASR performance matters |
| #645 | Start-recording button broken after calendar sharing enabled | Lifecycle bugs from feature interaction |

### Patterns worth adapting for Bugbook (architecture deep-dive)

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Background AI engine (detached)** | `NotesEngine` runs post-meeting summarization detached from UI. Validates provider availability before executing, auto-refreshes UI on completion. Clean pattern for background auto-summarize/auto-tag in Bugbook. | Med | High |
| **Multi-provider LLM abstraction** | Common interface over OpenRouter, native OpenAI/Anthropic, and Ollama. Provider selection at runtime with per-provider API key management via Keychain. | Med | High |
| **Unified timeline workspace** | `HomeTimelineWorkspaceView` aggregates calendar events + saved sessions in a single chronological view. `MeetingDetailPane` is extractable — shown inline or expanded. | Med | High |
| **Pre-fetch + burst-decay throttle** | `PreFetchCache` + `BurstDecayThrottle` manage real-time LLM call rate. Allow initial burst for responsiveness, then decay. Avoids overwhelming the LLM during rapid input. | Low | Med |
| **Template system with fallback** | `TemplateStore` provides reusable note templates with a guaranteed default fallback. Per-type template selection. | Low | Med |
| **Screen-sharing privacy flag** | One-line `NSWindow` flag hides the app from screen sharing. Trivial privacy feature for sensitive notes. | Trivial | Low |

---

## 2. QMD (tobi/qmd)

> On-device hybrid search engine for markdown files. Combines BM25 (SQLite FTS5), vector similarity (sqlite-vec), and LLM reranking — all local via node-llama-cpp with GGUF models. 26.2k stars, MIT. By Tobi Lütke.

### Activity: High (4 commits merged, 8 PRs opened/updated, 6 issues)

| PR/Commit | What shipped | Why it matters |
|-----------|-------------|----------------|
| #698 (merged) | **Literal filesystem paths** — dropped `handelize()` at index time. `Budget & Revenue (Q4).md` no longer becomes `Budget-Revenue-Q4.md`. Auto-migrates existing indexes. | If Bugbook was working around mangled paths, that workaround can be removed |
| merged | **Dotted token splitting in FTS5** — version strings like `2026.4.10` now searchable | Edge-case search fix for technical notes |
| merged | **macOS path normalization** — `realpathSync` for symlink compat in tests | Apple Silicon test reliability |

**Notable open PRs:**

| PR | What's proposed | Effort to adopt | Impact |
|----|----------------|-----------------|--------|
| #711 | **`busy_timeout` for overlapping processes** — sets `PRAGMA busy_timeout = 120000`, configurable via `QMD_SQLITE_BUSY_TIMEOUT_MS` | Zero (env var) | **High** — prevents SQLITE_BUSY crashes when background indexing overlaps with search |
| #703 | **Path filtering (`--path`/`pathPrefix`)** — scope searches to specific folders. Also adds `explain.scoreType` and `explain.backendSources` | Low (pass flag) | **High** — Bugbook can scope to specific databases |
| #704 | **Title-match boosting** in hybrid search — capped boost for lookup-style "find note by name" queries | Zero (upgrade) | Med |
| #708 | **`--timeout` for embed** — remove 30-min cap with `--timeout 0` | Low | Med |
| #705 | **Remote OpenAI-compatible LLM backends** — `RemoteLLM` + `HybridLLM` for offloading inference | Med | Low–Med |
| #713 | **Pluggable lexical backends** — swap FTS5 for custom search via stdin/stdout JSON protocol | N/A | Low |

**Notable issues:**

| Issue | Detail |
|-------|--------|
| #710 | SQLITE_BUSY with overlapping processes — addressed by PR #711 |
| #699 | npm install fails on macOS Apple Silicon with Node 26 (active discussion) |
| #697 | Blended scores can't distinguish relevant from irrelevant — RRF dominates. Workaround: filter on `rerankScore > 0.55` via `--explain` |
| #685 | Only one result per file — long notes with multiple relevant sections lose coverage |

### Patterns worth adapting for Bugbook

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Guard qmd with busy_timeout** | Set `QMD_SQLITE_BUSY_TIMEOUT_MS=120000` in Bugbook's process-launch environment. Prevents crashes when `qmd embed` and `qmd query` overlap. | **Trivial** | **High** |
| **Path-scoped search** | When PR #703 merges, pass `--path` to scope searches to a specific database folder instead of post-filtering. | **Low** | **High** |
| **Score-based result filtering** | Don't rely on blended scores for relevance thresholds. Use `--explain` and filter on `rerankScore` to distinguish relevant from irrelevant results. | **Low** | Med |
| **Literal path awareness** | Remove any path-mangling workarounds now that qmd v2.5.3+ stores actual filesystem paths. | **Low** | Med |

---

## 3. AppFlowy (AppFlowy-IO/AppFlowy)

> Open-source AI-powered collaborative workspace (Flutter + Rust), 72k stars. Notion alternative emphasizing data privacy and local-first architecture.

### Activity: High (v0.12.2 released June 5, 6 PRs, 10+ issues)

**v0.12.2 highlights:**
- Revamped tab management with keyboard shortcuts
- Inline comments in database rows (granular annotation threads)
- Kanban board column coloring
- Fixes: page mention resolution, cursor position loss during sync, copy/paste with files, duplicate child view keys

**Prior release in window — v0.12.0 (May 25):**
- Document version history with view/restore
- AI auto-summarization for YouTube videos
- File translation

**Notable PRs:**

| PR | What's proposed | Why it matters |
|----|----------------|----------------|
| #8755 | **Read-only toggle collapse** — introduces `_readOnlyCollapsed` (transient UI state) separate from persisted `collapsed` attribute, with `_effectiveCollapsed` getter. Avoids write transactions for UI-only state. | **Excellent pattern** for SwiftUI read-only vs. editable document modes |
| #8783 | **Guillemet auto-formatting** (`<<` → «, `>>` → ») — registered via `buildCharacterShortcutEvents`, conflict-tested against `=>`, `->`, blockquote toggles | Clean character-shortcut architecture |
| #8773 | **Mouse drag multi-row selection** — `GridSelectionController` with shift-click range, ctrl-multi, drag-by-Y-coordinate mapping | Selection state management pattern for table/grid views |

**Notable issues:**

| Issue | Detail | PKM lesson |
|-------|--------|------------|
| #8792 | Comments don't sync between clients without restart | Real-time sync for ancillary data (comments, annotations) needs its own push channel |
| #8784 | Grid items not displayed in Calendar view | Multi-view data binding (grid/calendar/board) requires careful view-model synchronization |
| #8791 | Feature request: llama.cpp as local AI backend | Users want choice of local AI backends beyond Ollama |
| #8736 | "Lines are vanishing" — document content loss | Content integrity in collaborative editing is non-trivial |

### Patterns worth adapting for Bugbook

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Transient UI state layer** | Separate `@State` (read-only collapsed) from persisted model. Computed `effectiveCollapsed` getter picks the right source. Prevents unnecessary document writes in preview/read mode. | **Low** | **High** |
| **Document version history** | View/restore previous versions. Table-stakes for serious PKM. | Med | High |
| **Keyboard-driven tab management** | Cmd+1–9 for tabs, shortcuts for new/close/cycle. Essential for multi-document workflows. | **Low** | High |
| **Character shortcut registry** | Central builder for auto-formatting rules. Conflict-tested. Undoable. Extensible. | **Low** | Med |
| **Grid selection controller** | Centralized selection state with shift-range, ctrl-multi, drag support. Unmodifiable set exposure. | Med | Med |
| **Inline comments at row level** | Comment threads on database records, not just documents. Adds annotation depth. | High | Med |

---

## 4. Exo (ankitvgupta/mail-app)

> AI-native desktop email client — "Claude Code for your Inbox." Electron + React + TypeScript + ProseMirror. 455 stars.

### Activity: Moderate (0 commits merged, 4 open PRs, 0 issues updated)

All activity is on feature branches, not yet merged to main:

| PR | What's proposed | Why it matters |
|----|----------------|----------------|
| #169 | **AI calendar invite editor** (~820 lines) — AI extracts scheduling details (title, guests, date/time, location) from email text, pre-fills editable form, creates Google Calendar events with inline re-auth | AI entity extraction from unstructured text → structured data |
| #170 | **Fix snooze in All Inboxes** — `currentAccountId` null in unified view, derives account from selected email's `accountId` | Multi-account context resolution pattern |
| #171 | **Split tab keyboard shortcut** — Tab/Shift+Tab cycles through inbox splits (Superhuman keybinding mode) | Keyboard-first split-view navigation |
| #166 | **Ollama Cloud model picker** — curated dropdown (7 models, default Kimi K2.6) with "Custom…" escape hatch | Polished model-selection UX |

### Patterns worth adapting for Bugbook (architecture deep-dive)

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Context-aware AI command palette (Cmd+J)** | Inspects current selection context (email, draft, nothing) and surfaces relevant AI actions. Suggested actions from analysis metadata + free-form custom prompt. | **Low** | **High** |
| **Hierarchical memory system** | Four scopes: Person → Domain → Category → Global. Separate caps for drafting (1000) vs analysis (50). Persisted in SQLite, injected as formatted bullets into LLM prompts. | Med | **High** |
| **AI entity extraction → structured data** | PR #169 extracts dates, guests, location from unstructured email text into a pre-filled form. Same pattern applies to extracting tasks, dates, people from notes into frontmatter fields. | **Low** | **High** |
| **Hybrid local + remote search** | FTS5 for instant local results (150ms debounce, 20 results) + remote API for comprehensive search. Progressive result display. | Low–Med | High |
| **LLM cost tracking** | Per-call token/cost tracking in SQLite `llm_calls` table with per-model pricing. Important for any app making paid API calls. | **Low** | Med |
| **Anti-prompt-injection wrapping** | Untrusted content (external emails/imported notes) wrapped in safety markers before injection into LLM prompts. | **Low** | Med |
| **Exponential backoff with jitter** | 5 retries for rate limits, 3 for server/connection errors. Robust LLM client pattern. | **Low** | Low–Med |

---

## Top 3 This Week

The three highest-impact, lowest-effort items to act on first — all changes to Bugbook's own codebase:

### 1. Transient UI State Layer for Document Views (from AppFlowy PR #8755)
**Effort: Low | Impact: High**

Introduce a `@State` property in Bugbook's SwiftUI document views that tracks UI-only state (collapsed/expanded sections, scroll position) separately from the persisted document model. A computed `effectiveState` getter picks the right source based on editing mode. In read-only/preview mode, toggling a section header only changes local state — no document write, no undo entry, no sync trigger. This is a one-property-per-view change that eliminates unnecessary I/O in the most common interaction pattern (reading notes).

### 2. Guard QMD Launches with busy_timeout (from QMD PR #711 / Issue #710)
**Effort: Trivial | Impact: High**

Set `QMD_SQLITE_BUSY_TIMEOUT_MS=120000` in the process environment wherever Bugbook shells out to `qmd`. This single environment variable prevents `SQLITE_BUSY` crashes when background `qmd embed` (indexing) overlaps with user-triggered `qmd query` (search). Without it, concurrent qmd processes fail hard instead of queuing. One line in the process-launching code; zero qmd version dependency (the env var is being added in PR #711, expected to merge imminently).

### 3. Context-Aware AI Command Palette (from Exo's Cmd+J agent palette)
**Effort: Low | Impact: High**

Add a keyboard-triggered overlay (Cmd+J or similar) that inspects the current context — what's selected, which view is active, what database is open — and presents a filtered list of AI actions. When a note is selected: summarize, extract tasks, find related notes, ask a question. When text is highlighted: rewrite, translate, explain, link. When a database row is focused: fill empty fields, classify, tag. Include a free-form prompt input as an escape hatch. In SwiftUI this is a `.sheet` or popover with a `TextField` filter and a `List` of `Action` items. The context inspector is the valuable part — the UI is standard.

---

## Proposed Tickets

### Ticket 1: Add transient UI state layer for read-only document views

**Title:** Separate read-only UI state from persisted document model in views

**Description:** In Bugbook's SwiftUI document views (note detail, database row pages), introduce a transient `@State` property for UI-only state like collapsed/expanded toggle sections. Add a computed `effectiveCollapsed` getter that returns the transient state in read-only mode and the persisted state in edit mode. This prevents unnecessary document writes, undo entries, and sync triggers when users are just reading notes — the most common interaction.

Inspired by AppFlowy's PR #8755 which solved the same problem for their toggle list blocks: they introduced `_readOnlyCollapsed` (UI-only) separate from the persisted `collapsed` attribute, with `_effectiveCollapsed` prioritizing the read-only state when not editing.

**Effort:** Low
**Source:** https://github.com/AppFlowy-IO/AppFlowy/pull/8755

---

### Ticket 2: Set QMD_SQLITE_BUSY_TIMEOUT_MS in qmd launch environment

**Title:** Guard qmd process launches with SQLite busy_timeout

**Description:** In every place Bugbook spawns a `qmd` subprocess (search, indexing, embedding), set the environment variable `QMD_SQLITE_BUSY_TIMEOUT_MS=120000` (2 minutes). This causes concurrent qmd processes to queue on SQLite lock contention instead of crashing with `SQLITE_BUSY`. The scenario: background `qmd embed` runs while the user triggers `qmd query` — without the timeout, the second process fails hard. This is a one-line addition to the `ProcessInfo` environment dictionary in the process-launching code.

Motivated by QMD issue #710 (crash reports from overlapping processes) and the fix in PR #711 which adds the `PRAGMA busy_timeout` support behind this env var.

**Effort:** Trivial
**Source:** https://github.com/tobi/qmd/pull/711

---

### Ticket 3: Add context-aware AI command palette (Cmd+J)

**Title:** Add AI command palette with context-aware actions

**Description:** Implement a keyboard-triggered overlay (Cmd+J) that inspects the current UI context and presents relevant AI actions:
- **Note selected:** summarize, extract tasks/dates/people, find related notes, ask a question about it
- **Text highlighted:** rewrite, translate, explain, create link
- **Database row focused:** auto-fill empty fields, classify, suggest tags
- **No selection:** create new note from prompt, search knowledge base

Include a free-form prompt `TextField` as the first element so power users can type custom instructions. The action list filters as the user types (like Spotlight). The context inspector examines `@FocusState`, selection ranges, and the active view's type to determine which actions to surface.

Inspired by Exo's Cmd+J agent palette which adapts its action list based on whether an email, draft, or nothing is selected, with suggested actions derived from AI analysis metadata.

**Effort:** Low
**Source:** https://github.com/ankitvgupta/mail-app/pull/169
