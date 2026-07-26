# Weekly Research Scan — 2026-07-26

Repos monitored: **OpenOats**, **QMD**, **AppFlowy**, **Exo (mail-app)**
Period: July 19–26, 2026

---

## 1. OpenOats (yazinsai/OpenOats)

> Native macOS (Swift 6.2/SwiftUI) meeting note-taker with on-device WhisperKit transcription, local knowledge-base search via embeddings, and LLM-powered suggestions. ~2.5k stars, MIT.

### Activity: Light (1 merged PR, 1 open draft, 3 issues)

| PR | What shipped | Why it matters |
|----|-------------|----------------|
| #687 | **Bluetooth audio reconnect fix** — watchdog checks `hasCapturedFrames` after restart, retries up to 2× if no frames arrive | Error recovery pattern: verify expected state after recovery, bounded retries with reset |
| #686 | **SpeechAnalyzer engine** (open) — on-device macOS 26+ transcription via conditional compilation and dual-session streaming | Shows how to adopt new platform APIs alongside existing engines using `#if` guards |
| #688 | **Cloud credentials for audio imports** (draft) — fixing AssemblyAI import flow | Import pipeline hardening |

### Architecture Deep-Dive (low-activity week)

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Actor-based SessionRepository** | Swift actor wraps all file I/O. Thread-safe persistence without explicit locking. Directory-per-entity bundles on filesystem. | Med | High |
| **YAML frontmatter schema versioning** | `openoats/v1` schema field in frontmatter, `x_` prefixed extension fields for forward compatibility. Enables non-breaking migrations. | **Low** | Med |
| **Header-aware markdown chunker** | Parses H1-H6 hierarchy, maintains header context stack, generates breadcrumb paths (e.g., "sales > pricing"). Merges small sections (<80 words), splits large (>500 words) with 20% overlap. | Med | High |
| **Content-hash embedding cache** | Cache keyed by `filename:sha256`. Only re-embeds changed files. Full invalidation if embedding config fingerprint changes (provider/model/URL). | **Low** | Med |
| **Delayed write aggregation** | Batches remote utterances with 5-second delay to capture enrichment data before persisting. Avoids write amplification. | **Low** | Med |
| **JSONL for streaming writes** | Append-only transcript log, one JSON record per line. Independently parseable, no full-file rewrite needed. | **Low** | Low–Med |

---

## 2. QMD (tobi/qmd)

> On-device hybrid search engine for markdown files. BM25 (FTS5) + vector similarity (sqlite-vec) + LLM reranking — all local via node-llama-cpp with GGUF models. ~17k stars, MIT. Current version: v2.6.3 (June 24).

### Activity: No merges to main, but 8 open PRs and 8 new issues in the window

#### Open Pull Requests (July 19–26)

| PR | What it does | Bugbook relevance |
|----|-------------|-------------------|
| #784 | **Fix legacy path migration evicting live files** — filenames differing only by separators (dash/underscore/space) collide under slugification | **CRITICAL** — Bugbook's `Fix auth bug (a1b2c3).md` filenames contain spaces; collision risk |
| #786 | **Fix `--full-path` silent degradation** — moved/deleted files cause docid to silently drop, emitting `qmd://` URI instead | **HIGH** — breaks any parser expecting consistent output columns |
| #781 | **Collection filter for `qmd update`** — adds `-c` flag for selective re-indexing | **HIGH** — performance win if Bugbook manages multiple QMD collections |
| #782 | **Surface real error on rerank context failure** — better diagnostics | Medium |
| #777 | **Fix UTF-16 surrogate pair splitting at chunk boundaries** — emoji in markdown permanently fails to embed | Medium — PKM users use emoji |
| #788 | Fix `--version` build commit stamping | Low |
| #780 | Env var override for CI kill-switch | Low |
| #779 | Cross-platform prepare script (Windows) | Low |

#### Notable Issues (July 19–26)

| Issue | What it reports | Bugbook relevance |
|-------|----------------|-------------------|
| #791 | **Vector search returns nothing for small collections** — global top-k retrieval happens before collection filtering, crowding out small collections | **CRITICAL** — if Bugbook partitions data into per-database QMD collections |
| #792 | **SQLiteError in CJK normalization on Bun 1.3.14** — fresh install breakage | **HIGH** — new user onboarding |
| #785 | `--full-path` drops docid silently (companion to PR #786) | HIGH |
| #775 | Scoped/multi-collection search returns false-empty results | CRITICAL |

### Upstream Risk Assessment

QMD is Bugbook's search/indexing dependency. Three issues warrant immediate attention in Bugbook's own code:

1. **Filename collision risk** (PR #784): QMD's slugification treats dashes, underscores, and spaces as equivalent. Bugbook filenames like `Fix auth bug (a1b2c3).md` could collide with hypothetical `Fix-auth-bug-(a1b2c3).md`. Audit Bugbook's `RowSerializer` to ensure generated filenames won't collide under QMD's normalization.

2. **Small-collection empty results** (Issue #791): If Bugbook creates separate QMD collections per database, smaller databases will return zero results from `qmd query`. Mitigation: fall back to `qmd search` (BM25-only) when hybrid returns empty, or avoid collection scoping and filter application-side.

3. **`--full-path` output breakage** (PR #786): If Bugbook parses QMD output with `--full-path`, add defensive handling for `qmd://` fallback URIs and missing `docid` fields.

---

## 3. AppFlowy (AppFlowy-IO/AppFlowy)

> Open-source AI collaborative workspace (Flutter + Rust), 74.3k stars, AGPLv3. Notion alternative emphasizing data privacy and local-first architecture.

### Activity: v0.13.0 released July 24 — major feature release

#### v0.13.0 Highlights

| Feature | Detail | Bugbook relevance |
|---------|--------|-------------------|
| **Database rows as pages** | Rows can be favorited, @-mentioned, and shared individually. Deleted rows go to Trash. | **HIGH** — validates Bugbook's "row file = page" architecture. Add soft-delete and cross-referencing. |
| **Per-page collaborator permissions** | Individual access levels per page | Medium — relevant if Bugbook adds sharing |
| **On-premises Qwen model support** | Self-hosted LLM for enterprises | Medium — local AI trend continues |
| **Multi-block selection & drag** | Select and drag multiple blocks to reorder | Medium — power-user editor feature |
| **Draggable database view tabs** | Reorder view tabs within databases | **Low effort, nice UX** — add to Bugbook's view switcher |
| **Mobile:** comment viewing on row pages, trash/restore, sync fixes | Parity push for mobile | Medium — if BugbookMobile is active |

#### Issues Bulk-Closed with v0.13.0 (selected)

| Issue | What resolved | Age |
|-------|--------------|-----|
| #2418 | Deleted rows go to Trash (soft delete) | **3+ years open** |
| #5899 | Row records can be @-mentioned from documents | 2+ years |
| #7120 | "Link to page" property type for grids | 1+ year |
| #6088 | Add database rows to Favorites | 1+ year |
| #4924 | Checklist subtasks visible on kanban cards | 2+ years |
| #6988 | Item count per kanban column | 1+ year |
| #8834 | Kanban column color persistence | Months |
| #6525 | Per-page sharing/permission controls | 2+ years |
| #7291 | Dates before 1979-01-01 not supported | 1+ year |

#### Q3 2026 Roadmap (Open)

| Issue | Feature | Category |
|-------|---------|----------|
| #5892 | Cross-reference objects in grid cells | database |
| #7704 | Grid calculations on mobile (iOS) | mobile |
| #3331 | Reorder views | views |
| #7978 | Subpage auto-show as block in documents | organization |

### Patterns worth adapting for Bugbook

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Soft delete with Trash** | Move deleted row .md files to `.bugbook/trash/` with timestamp prefix. Add `bugbook trash list` and `bugbook trash restore <id>`. | **Low** | **High** |
| **Row @-mentioning** | Extend reverse index to track row-to-document references. Store backlinks. Render mentions as clickable links with row title preview. | Med | **High** |
| **Draggable view tabs** | Allow reordering database view tabs. Store order in `_schema.json` views array. | **Low** | Med |
| **Kanban column enhancements** | Item count per column header, persistent column colors, checklist progress on cards. | Med | Med–High |
| **Calendar scroll fix** | Use `.simultaneousGesture()` instead of `.gesture()` in SwiftUI for scroll regions containing interactive cards. Prevents card interaction from swallowing scroll events. | **Low** | Med |
| **Inline database auto-naming** | When creating an embedded database, default its name from the parent page title instead of "Untitled". | **Trivial** | Low–Med |

---

## 4. Exo / mail-app (ankitvgupta/mail-app)

> Open-source AI-native desktop email client — "Claude Code for your Inbox." Electron + React + TypeScript + SQLite. LLM-powered triage, draft generation, sender research, interactive agent sidebar. 487 stars.

### Activity: Light (no merges to main; 3 active PRs)

| PR | What it does | Why it matters |
|----|-------------|----------------|
| #189 | **Performance fix** — strip oversized inline images at write boundary + covering indexes. 1.6GB → 569MB database, 12s → 55ms queries. | Critical SQLite performance lesson |
| #191 | Fix packaged OpenCode binary resolution (70 files, draft) | Bundling third-party agent runtimes |
| #190 | Fix email detail pane height after resume | UI state restoration |

### Architecture Deep-Dive (low-activity week)

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Staged AI analysis pipeline** | `prefetch-service.ts` orchestrates: analyze → classify priority → look up sender → auto-draft. Background processing of unanalyzed items. | Med | **High** |
| **Correction-learning memory system** | `memory-context.ts` + `analysis-edit-learner.ts` track user overrides to improve future classifications. Scoped by sender/topic. | Med | **High** |
| **Multi-provider LLM resolver** | `resolveBackgroundAgentProviderId()` validates prerequisites per provider, graceful fallback. Separate config for background (auto-draft) vs interactive (sidebar) AI. | **Low** | **High** |
| **Covering indexes for primary views** | Design indexes that include all columns needed by list queries to avoid table lookups. PR #189's 200× speedup. | **Low** | High |
| **LLM call tracking table** | `llm_calls` table logs model, tokens, cost, caller attribution. Essential for API cost management. | **Low** | Med |
| **Hybrid cloud/local agent execution** | Hostler pattern: cloud runs reasoning harness, all tool calls execute locally against real data. Preserves data sovereignty. | High | Med |
| **Extension manifest system** | Three tiers: bundled (static imports), private (build-time), runtime-installable. Zod schema validation. | High | Med |

---

## Top 3 This Week

The three highest-impact, lowest-effort items to act on first — all are changes to Bugbook's own codebase:

### 1. Soft Delete with Trash for Database Rows (from AppFlowy v0.13.0)
**Effort: Low | Impact: High**
AppFlowy finally shipped issue #2418 after 3+ years — deleted database rows now go to Trash instead of being hard-deleted. Bugbook should do the same: move deleted row `.md` files to `.bugbook/trash/<database-id>/` with an ISO timestamp prefix on the filename. Add `bugbook trash list [--db <name>]` and `bugbook trash restore <row-id>` CLI commands. Update `MutationEngine.deleteRow` to move instead of unlink. This is ~1–2 days of work and prevents irreversible data loss — a trust-building feature for any local-first tool.

### 2. Multi-Provider LLM Resolver for Agent Workspace (from Exo)
**Effort: Low | Impact: High**
Exo's `resolveBackgroundAgentProviderId()` pattern is a clean abstraction Bugbook can adopt for its agent workspace. Define a `AgentProvider` protocol with `isAvailable()`, `validate()`, and `execute()`. Implement concrete providers for Ollama (local), Claude API, and OpenAI. The resolver checks prerequisites in priority order (is Ollama running? is the API key valid?) and falls back gracefully. Store the preferred provider in `bugbook.json` workspace config. This unlocks AI features without vendor lock-in and aligns with AppFlowy's simultaneous move toward on-premises model support.

### 3. Defensive QMD Output Parsing (from QMD PRs #784, #786, Issue #791)
**Effort: Low | Impact: High**
Three active QMD issues directly affect Bugbook's search integration. Add defensive handling in Bugbook's QMD output parser: (a) handle `qmd://` fallback URIs when `--full-path` can't resolve a filesystem path (PR #786), (b) fall back to BM25-only search (`qmd search`) when hybrid search (`qmd query`) returns zero results for a small collection (Issue #791), and (c) log a warning if QMD's filename slugification could collide with Bugbook's row filenames containing mixed separators (PR #784). These are small guard clauses in existing code — 2–4 hours total — that prevent silent search failures and potential data loss in the index.

---

## Proposed Tickets

### Ticket 1: Add soft-delete Trash for database rows

**Title:** Add soft-delete Trash system for database row deletion

**Description:** When a user or CLI agent deletes a database row, move the `.md` file to `.bugbook/trash/<database-id>/` with an ISO-8601 timestamp prefix instead of hard-deleting it. Update `MutationEngine`'s `.deleteRow` operation to perform a move rather than an unlink. Patch `IndexManager.removeRow` to also record the trash path for potential restore. Add two new CLI commands:
- `bugbook trash list [--db <name>]` — list trashed rows with deletion timestamps
- `bugbook trash restore <row-id>` — move the file back, re-patch the index

Optionally add a `bugbook trash purge [--older-than 30d]` for permanent cleanup.

AppFlowy shipped this in v0.13.0 after issue #2418 was open for 3+ years — it's the most requested safety feature in Notion-like tools.

**Effort:** Low (1–2 days)

**Source:** [AppFlowy v0.13.0 release](https://github.com/AppFlowy-IO/AppFlowy/releases/tag/0.13.0), resolving [issue #2418](https://github.com/AppFlowy-IO/AppFlowy/issues/2418)

---

### Ticket 2: Add multi-provider LLM resolver to agent workspace

**Title:** Add pluggable LLM provider resolver for agent workspace

**Description:** Introduce an `AgentProvider` protocol in `BugbookCore/Model/Agent.swift` with methods `isAvailable() -> Bool`, `validate() -> Result<Void, ProviderError>`, and `execute(prompt:) async throws -> String`. Implement three concrete providers:
- `OllamaProvider` — checks if Ollama is running locally, validates model availability
- `ClaudeProvider` — validates API key from environment or keychain
- `OpenAIProvider` — validates API key, supports compatible endpoints

Add a `resolveProvider()` function that checks providers in user-configured priority order (stored in `bugbook.json` as `"agent_provider_priority": ["ollama", "claude", "openai"]`), returning the first that passes validation. Fall back gracefully with a clear error if none are available.

Wire into `AgentCommand.swift` so all agent operations use the resolved provider. This mirrors Exo's `resolveBackgroundAgentProviderId()` pattern and aligns with AppFlowy's v0.13.0 addition of on-premises Qwen model support — the trend is toward local-first AI with cloud fallback.

**Effort:** Low (1–2 days for protocol + resolver; providers are thin wrappers)

**Source:** [Exo's provider resolver pattern](https://github.com/ankitvgupta/mail-app) in `src/main/ai/providers/`, and [AppFlowy v0.13.0](https://github.com/AppFlowy-IO/AppFlowy/releases/tag/0.13.0) on-premises Qwen support

---

### Ticket 3: Add defensive parsing for QMD CLI output

**Title:** Harden QMD output parsing against upstream edge cases

**Description:** Three active QMD issues affect Bugbook's search integration. Add defensive handling in the code that invokes and parses QMD CLI output:

1. **`qmd://` URI fallback** (QMD PR #786): When parsing `--full-path` output, detect rows where the `docid` field is missing or replaced with a `qmd://` URI. Log a warning and fall back to the URI for display, or skip the result gracefully. Don't crash on unexpected output shape.

2. **Empty hybrid search fallback** (QMD Issue #791): When `qmd query` returns zero results for a collection that is known to contain documents, automatically retry with `qmd search` (BM25-only) as a fallback. This works around the vector search bug where small collections get crowded out by global top-k retrieval.

3. **Filename collision audit** (QMD PR #784): Add a diagnostic check (callable via `bugbook db check <name>`) that scans row filenames for potential collisions under QMD's slugification rules (dashes, underscores, and spaces treated as equivalent). Warn if any two filenames would collide.

**Effort:** Low (2–4 hours for items 1–2, half day for item 3)

**Source:** [QMD PR #786](https://github.com/tobi/qmd/pull/786), [QMD Issue #791](https://github.com/tobi/qmd/issues/791), [QMD PR #784](https://github.com/tobi/qmd/pull/784)
