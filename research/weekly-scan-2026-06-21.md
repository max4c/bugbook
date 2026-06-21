# Weekly Research Scan — 2026-06-21

Repos monitored: **OpenOats**, **QMD**, **AppFlowy**, **Exo (mail-app)**
Period: June 14–21, 2026

---

## 1. OpenOats (yazinsai/OpenOats)

> Native macOS (Swift/SwiftUI) meeting note-taker with on-device WhisperKit transcription, local knowledge-base search via embeddings, and LLM-powered suggestions. 2.5k stars, MIT.

### Activity: High (8 commits, 6 PRs merged, 12 issues closed)

| PR | What shipped | Why it matters |
|----|-------------|----------------|
| #661 | **LM Studio + diarization + transcript Q&A** — LM Studio as first-class provider, ElevenLabs Scribe diarization, new "Ask" tab for Q&A over saved transcripts | Three major features in one PR: pluggable local-LLM provider, speaker attribution, and "chat with your notes" |
| #658 | **Live echo handling + diarization timing** — consolidated acoustic echo matcher, suppresses mic echo against remote partials, preserves segment timing | Single source of truth for dedup across live/batch processing |
| #657 | Fix camera-triggered detection notification showing wrong app name | Bug fix |
| #656 | Fix meeting detail panel recording, silence timeout, rename UX, wizard hint | 4-issue omnibus: direct `startSession` bypass, silence-monitoring loop, pencil icon for rename, cloud transcription note |

### Patterns worth adapting for Bugbook

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Pluggable LLM provider abstraction** | Common interface over OpenRouter, Ollama, LM Studio, native OpenAI, and Anthropic. Per-provider config (API keys, base URLs, model selection). Streaming support. | Med | High |
| **"Ask" tab — Q&A over stored content** | LLM-powered Q&A over saved transcripts using active provider. Directly applicable to "chat with your notes" in a PKM. | Med | High |
| **Burst-decay throttle for real-time AI** | `BurstDecayThrottle.swift` + `RealtimeGate.swift` rate-limit AI calls during rapid input to balance responsiveness and cost. | Low | Med |
| **Template-based content generation** | `TemplateStore.swift` with category fallback logic (meeting family → generic). Maps to note type templates (daily notes, project briefs). | Med | Med |
| **Import from competing tools** | `GranolaImporter.swift` — paginated fetch, speaker mapping, tag-based dedup (`source:"granola"` + `granola:{noteId}`). Idempotent re-import pattern works for any source. | Med | Med |
| **Modular Swift Package structure** | Clean separation: `Domain/`, `Intelligence/`, `Storage/`, `Views/` as distinct concerns within a single SPM package. 28 view files, testable layers. | Low | Med |

---

## 2. QMD (tobi/qmd)

> On-device hybrid search engine for markdown files. BM25 (SQLite FTS5) + vector similarity (sqlite-vec) + LLM reranking via node-llama-cpp with GGUF models. 26.8k stars, MIT. By Tobi Lütke.

### Activity: Low (1 merged PR, 6 active issues, 6 open PRs)

| PR | What shipped | Why it matters |
|----|-------------|----------------|
| #740 | **Guard `ensureLlama` against concurrent init** — serialization guard via `llamaLoadPromise` prevents race condition creating multiple Llama runtime instances. Graceful fallback on `InsufficientMemoryError`. | Fixes intermittent crashes when multiple concurrent searches trigger query expansion |

### Notable open PRs and issues

| Item | Detail | Bugbook action |
|------|--------|----------------|
| PR #737 | Stream-batch CJK FTS rebuild to prevent OOM on large indexes | Watch for merge → dep bump (high impact for multilingual users) |
| PR #733 | Make node-llama-cpp optional with graceful degradation | Watch for merge → broadens install compatibility |
| Issue #735 | `qmd embed` deadlocks at 0% CPU on Apple M5 Max | Monitor — directly affects Apple Silicon users |
| Issue #724 | 30-min timeout prevents completing large collection embeds | Relevant for large knowledge bases |

### Dependency update action

**Update `@tobilu/qmd` to include commit `62b3a67`** (or wait for v2.5.4). The concurrent init race condition (PR #740) can cause grammar/model binding errors under concurrent `store.search()` calls with hybrid queries. This is a version bump, not a Bugbook code change.

---

## 3. AppFlowy (AppFlowy-IO/AppFlowy)

> Open-source AI-powered collaborative workspace (Flutter + Rust), 69k+ stars. Notion alternative emphasizing data privacy and local-first architecture.

### Activity: Moderate (0 commits to main, 6 PRs, 12 issues, 2 releases)

**v0.12.4 (June 20)** and **v0.12.3 (June 18)** shipped:
- Row page comments revamp with notification support
- Kanban board column color persistence
- Tab management fixes (new tab button, workspace switching, back/forward navigation)
- Database visibility sync, filter refresh, row deletion fixes
- PDF embed fallback to links when preview unavailable

| PR/Issue | What's notable | Why it matters |
|----------|---------------|----------------|
| PR #8819 | Copy text action for toggle/list blocks | Block-level context menu pattern — enum of actions per block type |
| PR #5747 | Time field type with stopwatch/timer modes | New database property type: plain time, stopwatch (count up), timer (countdown) |
| #8636 | Duplicating linked views copies same reference | Critical: view duplication must deep-copy filters/sorts/config, not share references |
| #8824 | Grid horizontal scroll misalignment after fullscreen toggle | Sticky headers must survive window resize/mode changes |
| #8823 | Recurring tasks + multi-day calendar spans | Calendar view needs multi-day rendering and RRULE support |
| #8820 | Typing stops after ESC on colon suggestions | Suggestion popover dismissal must restore editor focus |
| #8822 | Arrow key navigation gaps across block types | Every block type must define arrow-key entry/exit behavior |

### Patterns worth adapting for Bugbook

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **View duplication must deep-copy** | AppFlowy bug #8636: linked views share reference. Bugbook must deep-copy filters/sorts/visibility when duplicating views or creating from templates. | Med | High |
| **Row-as-page with inline comments** | v0.12.4 revamped row page comments with notifications. Each database row is a full document page. | High | High |
| **Sticky headers resilient to resize** | Table headers lose fixed positioning after window mode changes (#8824). Preventive fix is cheap. | Low | High |
| **Popover dismiss restores focus** | ESC from suggestion/autocomplete must return first-responder to editor (#8820). Common bug pattern. | Low | High |
| **Arrow-key navigation contract** | Define enter/exit behavior for every block type (#8822). Plan from the start. | Med | High |
| **Kanban column color customization** | v0.12.2 added persistent column colors. Visual customization for board views. | Low | Med |

---

## 4. Exo / mail-app (ankitvgupta/mail-app)

> Open-source AI-native desktop email client — "Claude Code for your inbox." Electron + React + TypeScript. 472 stars, MIT.

### Activity: Moderate (1 merged commit, 4 active open PRs, 1 new issue)

| PR | What shipped / in progress | Why it matters |
|----|---------------------------|----------------|
| #173 | **Agentic verification harness hardening** — real-account-first routing, classification-based rubrics (A–F), anti-pattern detection for false-pass verdicts | Sophisticated CI pattern for validating AI-powered features actually work |
| #178 | Resolve high-severity prod audit advisories (hono, protobufjs) | Security hygiene — zero `npm audit` vulns, net -316 lines |
| #170 | Fix snooze in All Inboxes — cross-account batch snooze + per-thread undo | Per-item account ownership pattern: each thread knows its owning account |
| #171 | Split tab keyboard shortcut (Superhuman-style Tab cycling) | Dual-mode keyboard system with mode guards |
| #166 | Ollama Cloud model-picker dropdown in settings | Curated dropdown + "Custom..." escape hatch |
| #169 | AI calendar invite editor — press `i` to extract meeting details via LLM | LLM-powered structured data extraction from unstructured content |

### Patterns worth adapting for Bugbook

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Scoped AI memory system** | Per-sender, per-topic memories with configurable limits. Priority memory from user overrides. Writing style extraction. Maps to per-project/per-tag context in a PKM. | Med | High |
| **Keyboard-first with mode presets** | Gmail-style and Superhuman-style shortcut modes (user-selectable). Mode guards prevent interference during compose/search. | Low | High |
| **Per-item AI agent with tool access** | Cmd+J spawns Claude scoped to a single email with tool access (read, draft, search, forward). Maps to per-note agent with contextual tools. | Med–High | Very High |
| **Extension/plugin system** | Bundled + runtime-installable dual model. Extensions provide agent providers, sidebar panels (per-item context), and MCP tools. | Med | High |
| **NL draft refinement** | "Make this shorter", "more formal" — natural language commands for text editing. Directly applicable to note editing. | Low | High |
| **Optimistic UI with undo** | SQLite + FTS5 local storage, 30s incremental sync, offline queue, optimistic updates with undo. Gold standard for local-first. | Med | Very High |
| **Multi-workspace account architecture** | Per-account sync state, instant switching, cross-account isolation. Maps to multi-vault support. | Low–Med | Med |

---

## Top 3 This Week

The three highest-impact, lowest-effort items to act on first — all changes to Bugbook's own codebase:

### 1. Add keyboard shortcut mode system with mode guards
**Effort: Low | Impact: High**
Exo (PR #171) implements dual shortcut presets (Gmail-style / Superhuman-style) with mode guards that disable shortcuts during compose, search, or popover states. A PKM app lives or dies by keyboard efficiency. Implement a `KeyboardMode` enum and a `ShortcutRouter` that checks the current mode before dispatching. Start with one preset; the architecture makes adding more trivial. This also prevents the popover-focus-loss bug AppFlowy hit (#8820) — the mode guard pattern naturally handles it.

### 2. Add natural-language text refinement commands to the editor
**Effort: Low | Impact: High**
Exo's NL draft refinement ("make this shorter", "more formal") and OpenOats' "Ask" tab (#661) both demonstrate lightweight AI text actions that don't require a full agent system. In Bugbook: select text → invoke a refinement command → stream LLM response inline. This needs only a text selection handler, a prompt template, and a streaming LLM call. No new UI chrome required — it can live in the existing context menu or a keyboard shortcut.

### 3. Ensure view duplication deep-copies filters, sorts, and visibility config
**Effort: Low | Impact: High**
AppFlowy's #8636 bug reveals that duplicating a linked database view can silently share mutable state — modifications or deletions cascade to all copies. In Bugbook's `ViewConfig` model, ensure that any view copy (whether from duplication, template instantiation, or embed creation) gets freshly generated IDs for the view and its filter/sort rules. This is a preventive fix: audit `ViewConfig` copy semantics now, before users hit the bug. A few lines in the model layer.

---

## Proposed Tickets

### Ticket 1: Add keyboard shortcut mode system with context-aware guards

**Title:** Add keyboard shortcut mode system with context-aware guards

**Description:**
Implement a `KeyboardMode` enum (`normal`, `editing`, `search`, `popoverOpen`) and a `ShortcutRouter` that gates shortcut dispatch on the current mode. When a popover, search field, or inline editor is active, non-relevant shortcuts are suppressed — preventing the focus-loss bug AppFlowy hit (#8820) and enabling future multi-preset support (e.g., Vim-style vs. standard shortcuts).

Start with a single shortcut preset covering navigation (arrow keys, J/K for next/prev row), view switching (1/2/3 for table/kanban/calendar), and editing (Enter to open row, E to edit inline). The mode-guard architecture makes adding alternative presets a data change, not a code change.

Inspired by Exo's dual-mode keyboard system (PR #171) which uses mode guards to prevent shortcut interference during compose/search states, and AppFlowy issue #8822 which highlights the need for a per-block-type arrow-key navigation contract.

**Effort:** Low

**Source:** https://github.com/ankitvgupta/mail-app/pull/171, https://github.com/AppFlowy-IO/AppFlowy/issues/8820, https://github.com/AppFlowy-IO/AppFlowy/issues/8822

---

### Ticket 2: Add natural-language text refinement commands to the editor

**Title:** Add natural-language text refinement commands to editor

**Description:**
Add a text refinement action triggered via context menu or keyboard shortcut (e.g., Cmd+Shift+R) when text is selected in a row body. The user types a natural-language instruction ("make this shorter", "fix grammar", "translate to Spanish") and the selected text is replaced with the LLM's streaming response.

Implementation: add a `TextRefinementService` that takes `(selectedText: String, instruction: String)` and returns an `AsyncStream<String>`. Wire it to the existing row body editor's selection handler. Use a minimal inline prompt sheet — no new panel or sidebar needed. The service calls whichever LLM provider is configured (same abstraction Bugbook already uses for agent tasks).

This is the simplest useful AI editing feature — it doesn't require embeddings, RAG, or agent infrastructure. Both Exo's NL draft refinement and OpenOats' "Ask" tab (PR #661) validate the UX pattern.

**Effort:** Low

**Source:** https://github.com/ankitvgupta/mail-app (NL refinement pattern in ProseMirror editor), https://github.com/yazinsai/OpenOats/pull/661

---

### Ticket 3: Audit and fix ViewConfig copy semantics to deep-copy on duplication

**Title:** Audit ViewConfig copy semantics — deep-copy on duplication

**Description:**
Audit `ViewConfig` (in `BugbookCore/Model/View.swift`) to ensure that copying a view — whether through explicit duplication, template instantiation, or database embed creation — produces a fully independent copy with new IDs for the view itself and all its filter/sort rules.

AppFlowy's #8636 bug demonstrates what happens when view copies share mutable references: modifying filters in one copy cascades to all others, and deleting one view breaks all linked copies. This is a silent data corruption bug that's hard to diagnose after the fact.

The fix: ensure `ViewConfig`'s copy/clone path generates fresh `id` values (via `UUID().uuidString` or Bugbook's ID scheme) for the view and each `Filter`/`Sort` entry. Add a unit test that duplicates a view, modifies the copy's filters, and asserts the original is unchanged.

**Effort:** Low

**Source:** https://github.com/AppFlowy-IO/AppFlowy/issues/8636
