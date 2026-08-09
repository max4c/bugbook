# Weekly Research Scan — August 9, 2026

Repos monitored: [OpenOats](https://github.com/yazinsai/OpenOats), [QMD](https://github.com/tobi/qmd), [AppFlowy](https://github.com/AppFlowy-IO/AppFlowy), [Exo (mail-app)](https://github.com/ankitvgupta/mail-app)

---

## OpenOats (yazinsai/OpenOats)

**Activity level:** Low — 4 housekeeping commits on Aug 2 (Homebrew bump to v1.84.2, AssemblyAI model update, cloud credentials fix, phi3.5 tag fix). No commits since.

**Notable open work:**
- **PR #686 — On-device SpeechAnalyzer (macOS 26+):** Adds Apple's new `SpeechAnalyzer` framework as a transcription engine with dual streaming sessions and backward-compatible fallback to Parakeet. CI green, awaiting maintainer review.
- **Issue #638 — Google Calendar sync:** OAuth-based calendar integration to detect meetings beyond mic/camera heuristics. No assignee yet.

**Architecture highlights (relevant to Bugbook):**
- Swift 6.2 / SwiftUI macOS app with clean modular SPM layout (Audio, Transcription, Intelligence, Domain, Models, Storage)
- **Pluggable provider pattern:** Transcription engines behind protocols, swappable at runtime. Applicable to Bugbook for editor backends, sync engines, or AI providers.
- **Local markdown RAG:** Indexes local markdown files, retrieves contextually relevant content. Directly applicable to a PKM app.
- **Ollama integration:** Fully offline AI mode using local LLMs — privacy differentiator.
- Auto-saved sessions as plain-text + structured logs, no proprietary format.

| Actionable Idea | Effort | Impact |
|---|---|---|
| Pluggable provider pattern for subsystems | Medium | High |
| Local markdown RAG for contextual note surfacing | Medium | High |
| Ollama/local LLM integration for offline AI | Low | Medium |
| Watch PR #686 for SpeechAnalyzer patterns (voice notes) | Medium | Medium |

---

## QMD (tobi/qmd)

**Activity level:** Medium — No new releases (last: v2.6.3, June 24), but 10+ open PRs and 4 new issues filed this week. Active development in-flight.

**Key PRs (Aug 2–6):**
- **#818** — Fix query expansion cache pollution (caller intent leaking into expansion). Search quality fix for CLI consumers.
- **#819** — Graceful fallback when reranker context creation fails. Prevents hangs/crashes.
- **#817** — Prefetch model files at HTTP server start, eliminating cold-start latency for MCP/REST mode.
- **#816** — Expire idle HTTP sessions with configurable TTL (memory leak prevention).
- **#814** — Index `content_vectors` for embedding-status scan (performance fix for large collections).
- **#752** — Expose reranker score in MCP/REST explain output.

**Key Issues:**
- **#809** — `--timeout` flag for CLI queries. Directly relevant: Bugbook should adopt this to prevent QMD subprocess hangs.
- **#813** — ColBERT late-interaction rerank stage (future quality improvement).

**Takeaways:**
- No breaking API changes — QMD CLI interface remains stable.
- PRs #818 and #819 fix reliability/quality issues. When they land in a release, update the dependency.
- The `--timeout` flag (#809) is worth watching — once landed, add timeout args to Bugbook's QMD subprocess calls.
- MCP server mode (#815/#816/#817) is maturing if Bugbook needs lower-latency repeated queries.

| Actionable Idea | Effort | Impact |
|---|---|---|
| Add QMD subprocess timeout (once #809 lands) | Low | High |
| Update QMD dependency when #818/#819 ship | Trivial | High |
| Evaluate MCP server mode for repeated queries | Medium | Medium |

*Note: QMD items are dependency updates, not Bugbook code changes, except for adding timeout handling to subprocess calls.*

---

## AppFlowy (AppFlowy-IO/AppFlowy)

**Activity level:** Low on commits (last merge June 26), but 20+ issues updated this week — all community bug reports and feature requests.

**Key Issues:**
- **#8924** — Grid view misalignment: column headers and row content scroll out of sync. Classic table-view bug.
- **#8922** — Kanban "add card at bottom" broken. Card insertion UX in board views.
- **#8908** (Closed) — Empty kanban groups always hidden. Fixed with a visibility toggle.
- **#8921** — Trash fails silently for database views. Items permanently stuck — deletion lifecycle needs special handling vs. plain docs.
- **#8927** (Closed) — Linked grid in database row template causes internal error. Embedding one DB view inside another's row template.
- **#8807** — Number/currency formatting corrupts values on focus loss.
- **#3878** — Formula support in Grids. Long-requested computed columns, on AppFlowy's 2026 roadmap.
- **#8929** — Setting to open links in mobile vs. desktop app (deep-link routing).

| Actionable Idea | Effort | Impact |
|---|---|---|
| Table view scroll sync (headers + rows coordinated) | Low | High |
| Kanban empty-group visibility toggle per view | Trivial | Medium |
| Kanban card insertion at top or bottom of column | Low | Medium |
| Database view deletion lifecycle (separate from page deletion) | Medium | High |
| `bugbook://` URL scheme for CLI-to-app deep links | Low | Medium |
| Computed/formula columns in database views | High | High |

---

## Exo / mail-app (ankitvgupta/mail-app)

**Activity level:** Medium — 6 PRs touched, 1 merged to main. Focused on performance and reliability.

**Key PRs:**
- **#189 (Merged)** — Strip oversized inline images at write time + covering index. Cut database from 1.8GB to 569MB; inbox queries from ~1s to ~60ms. Included ReDoS fix.
- **#195 (Open)** — Fix window resume speed. macOS window hides instead of destroying on close; coalesces duplicate sync calls; persists navigation state.
- **#194 (Draft)** — Persist undo-send timer in main process with DB persistence, surviving window close/crash/quit. Fixes send-later attachment loss.
- **#196 (Open)** — Refresh Hostler SDK integration (agent backend). Client-side session IDs for idempotent recovery.
- **#172 (Open)** — Retry transient Gmail 500s when creating block-sender filters.

| Actionable Idea | Effort | Impact |
|---|---|---|
| Write-time content sanitization in RowStore | Low | High |
| Persist navigation state across app relaunch | Low | Medium |
| Crash-resilient pending operations (sync queue, drafts) | Medium | High |
| Sync call coalescing with actor isolation | Low | Medium |

---

## Top 3 This Week

The three highest-impact, lowest-effort items — all changes to Bugbook's own codebase:

### 1. Write-time content sanitization in RowStore
Row markdown bodies can accumulate bloated base64-encoded images and large embedded content over time. Add a sanitization pass in `RowStore.swift` (or `MutationEngine.swift`) that detects and compresses or externalizes oversized inline content before writing `.md` files to disk. This prevents silent workspace bloat — the same pattern that caused Exo's database to balloon to 1.8GB before their fix.

**Effort:** Low | **Impact:** High

### 2. Kanban empty-group visibility toggle
Add a boolean `show_empty_groups` field to `ViewConfig` for kanban views. When false (default), hide columns with zero cards. When true, show all option values from the `group_by` select property. AppFlowy shipped this fix after #8908 showed users were confused by disappearing empty columns.

**Effort:** Trivial | **Impact:** Medium

### 3. Persist and restore navigation state
Save the active database ID, view ID, selected row ID, and scroll offset to a workspace state file (e.g., `.bugbook/ui_state.json`) or `UserDefaults`. Restore on app launch so users resume exactly where they left off. Exo's PR #195 demonstrated this dramatically improves perceived responsiveness on macOS.

**Effort:** Low | **Impact:** Medium

---

## Proposed Tickets

### Ticket 1: Sanitize oversized inline content at write time

**Title:** Add write-time content sanitization to RowStore

**Description:** Add a sanitization step in `RowStore.swift` (called from `MutationEngine.execute()`) that scans markdown body content before writing row `.md` files. Detect base64-encoded images and other inline blobs exceeding a configurable threshold (e.g., 256KB). For oversized content: either compress it, strip it with a placeholder comment, or externalize it to a companion file (`<row-folder>/attachments/`). Log a warning when content is sanitized. This prevents workspace bloat that silently degrades query performance as the knowledge base grows — the same issue that caused Exo's 70% database reduction in PR #189.

**Effort:** Low

**Source:** https://github.com/ankitvgupta/mail-app/pull/189

---

### Ticket 2: Add empty-group visibility toggle to kanban views

**Title:** Add show/hide empty groups toggle for kanban board view

**Description:** Add a `show_empty_groups: Bool` field to `ViewConfig` (defaulting to `true`). In the kanban board view, when `false`, only render columns that contain at least one card. The toggle should be accessible from the view's toolbar/settings popover. Update `_schema.json` serialization to persist the new field. This addresses a common UX confusion where empty status columns either clutter the board or silently disappear — AppFlowy resolved this same issue in #8908.

**Effort:** Trivial

**Source:** https://github.com/AppFlowy-IO/AppFlowy/issues/8908

---

### Ticket 3: Persist and restore navigation state across app sessions

**Title:** Save and restore active view and selection on app relaunch

**Description:** On app backgrounding/quit, write the current navigation state to `.bugbook/ui_state.json`: `{ "active_database": "db_tasks", "active_view": "view_board", "selected_row": "row_a1b2c3", "scroll_offset": 320 }`. On app launch, read this file and restore the navigation stack so the user resumes exactly where they left off. Use SwiftUI's `@SceneStorage` for lightweight state or write directly via `JSONEncoder` for more control. Exo's PR #195 showed this pattern dramatically improves perceived app responsiveness on macOS — users don't have to re-navigate after every restart.

**Effort:** Low

**Source:** https://github.com/ankitvgupta/mail-app/pull/195
