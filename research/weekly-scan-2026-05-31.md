# Weekly Research Scan — 2026-05-31

Repos monitored: **OpenOats**, **QMD**, **AppFlowy**, **Exo (mail-app)**
Period: May 24–31, 2026

---

## 1. OpenOats (yazinsai/OpenOats)

> Native macOS (Swift/SwiftUI) meeting note-taker with on-device WhisperKit transcription, local knowledge-base search via embeddings, and LLM-powered suggestions. MIT.

### Activity: Low (8 PRs, mostly UI polish)

The project is in a UI-stabilization phase. Merged PRs were all cosmetic: tap targets, layout alignment, duplicate UI elements, mic-capture retry, and auto-pause on silence. No architectural changes this week.

| Item | What happened | Bugbook relevance |
|------|--------------|-------------------|
| UI polish PRs | Tap targets, layout fixes, auto-pause | Low — confirms stable phase |
| Issue #641 | CLI-based note generation via Codex CLI requested | Medium — validates Bugbook's CLI-for-agents design |
| Issue #638 | Google Calendar sync for meeting detection | Low — calendar integration pattern |

### Architecture Patterns (deep dive since low activity)

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Cache fingerprinting for index invalidation** | Composite fingerprint (`provider\|baseURL\|model\|normVersion`) detects when the full index needs rebuilding vs incremental updates. Individual files keyed by `filename:sha256`. | Low | Medium |
| **File-based session repository** | `sessions/<id>/` directory layout with JSON metadata, JSONL transcripts, markdown notes. Atomic writes via temp-file-then-rename. Lazy loading. Legacy format migration via fallback readers. Sidecar `.meta.json` pattern alongside `.md` files. | Medium | High |
| **Markdown chunking + embedding** | `KnowledgeBase.swift` chunks by heading (80–500 words, 20% overlap, header-context breadcrumbs). SHA256-based invalidation, vDSP-accelerated cosine similarity. Pre-normalized embeddings reduce search to dot products. | High | High |
| **Pluggable embedding providers** | Common interface over Voyage AI, Ollama, and OpenAI-compatible backends. | Medium | High |

---

## 2. QMD (tobi/qmd)

> On-device hybrid search engine for markdown files. Combines BM25 (SQLite FTS5), vector similarity (sqlite-vec), and LLM reranking. Bugbook delegates all search/indexing to this tool.

### Activity: Medium (5 commits, 3 open PRs, several new issues)

| Date | Change | Bugbook relevance |
|------|--------|-------------------|
| May 29 | **v2.5.3 release** + fix CLI exit so node-llama-cpp cleanup fires | Medium — pin to v2.5.3; prevents orphaned GPU resources when Bugbook spawns `qmd` as a subprocess |
| May 28 | **`--full-path` flag** on search/query/get/multi-get; new `--format` flag | **High** — Bugbook currently parses `qmd://` URIs; `--full-path` returns real disk paths, simplifying result parsing |
| May 28 | **Line-numbered output + line ranges** on `get`/`multi-get` | Medium — enables Bugbook to request specific line ranges for preview snippets |
| May 28 | Fix Metal residency sets crash on macOS | Low — upstream-only fix, reduces crashes on Apple Silicon |
| May 28 | Prefer Node+tsx over Bun when both lockfiles exist | Low — launcher detail |

### Notable Open PRs

| PR | Issue | Bugbook relevance |
|----|-------|-------------------|
| #690 | Embedding model dimension mismatch — `searchVector()` ignores store's pinned model | Medium — vector search silently breaks with non-default `QMD_EMBED_MODEL` |
| #686 | **`PRAGMA busy_timeout` for concurrent access** — multiple parallel `qmd` processes crash with `SQLITE_BUSY` | **High** — Bugbook's CLI agent mode likely fans out concurrent queries. Until this merges, Bugbook should serialize or retry |
| #677 | `--host` flag for MCP HTTP server | Low — only relevant if Bugbook moves to MCP transport |

### Notable Issues

| Issue | Summary | Bugbook relevance |
|-------|---------|-------------------|
| #685 | Multiple results per file requested | Medium — relevant for long markdown files with multiple matching sections |
| #682 | Reranker "Object disposed" error on first `query` call | Medium — Bugbook should handle gracefully (retry or fallback to `search`) |
| #683 | `--no-hyde` flag request | Medium — would let Bugbook skip query expansion for exact lookups, reducing latency |

### Actionable Items for Bugbook's Codebase

| Item | Effort | Impact |
|------|--------|--------|
| Adopt `--full-path` flag in QMD result parsing code | Low | High |
| Add retry/serialization for concurrent QMD calls (mitigate `SQLITE_BUSY` until PR #686 lands) | Low | High |
| Handle reranker "Object disposed" error (#682) with fallback to `search` | Low | Medium |

---

## 3. AppFlowy (AppFlowy-IO/AppFlowy)

> Open-source Notion alternative with database views, document editor, and AI features. Flutter/Rust. 65k+ stars.

### Activity: Low (no merged PRs to main in the last week; active issue tracker)

Main branch had no new commits this week. Activity concentrated in the issue tracker.

### Notable Issues (updated May 24–31)

| Issue | Title | Bugbook relevance |
|-------|-------|-------------------|
| #8707 | **Agentic AI Workspace Assistant for Databases, Tasks, Calendars** | **High** — detailed spec for natural-language database creation, auto-tagging, cross-database reasoning, agent-style execution with human confirmation. Validates Bugbook's agent architecture and maps directly to the `AgentCommand` system. |
| #8767 | **CJK full-text search broken** — Tantivy tokenizer doesn't handle languages without word-boundary spaces | **Medium** — Bugbook delegates search to QMD (which uses SQLite FTS5, not Tantivy), but this is a good test case. Ensure QMD handles CJK properly via ICU tokenization. |
| #8778 | Multi-instance login across devices | Low — local-first Bugbook doesn't have auth, but multi-device sync will need identity |
| #8777 | Web-UI & Markdown-File integration request | Medium — validates demand for markdown-as-source-of-truth + web view |
| #8775 | Stale profile data on initial load | Low — cache invalidation pattern |
| #8774 | Loading indicator visible when no spaces exist | Low — empty state UX consideration |

### Architecture Takeaways from Issue #8707

The agentic AI proposal describes capabilities Bugbook already partially has via `AgentCommand`:

| AppFlowy wish | Bugbook status | Gap |
|---------------|---------------|-----|
| Natural language → database creation | Not implemented | Could pipe LLM output through `bugbook db create` |
| Cross-database reasoning | `RelationResolver` exists | Need LLM layer on top |
| Agent-style execution with human confirmation | CLI has validation but no confirm step | Add `--dry-run` flag to mutation commands |
| Auto-tagging and categorization | Not implemented | LLM-powered `multi_select` tag suggestion |
| Permission-aware operations | No permission model | Could add role-based access to `AgentCommand` |

---

## 4. Exo / mail-app (ankitvgupta/mail-app)

> AI-native desktop email client built with Electron + React + TypeScript. Deep Claude integration for triage, drafting, and an agentic command palette.

### Activity: Very High (18 commits in 7 days)

| Change | Detail | Bugbook relevance | Effort / Impact |
|--------|--------|-------------------|-----------------|
| Unified inbox view (#145) | Merges multiple accounts into one stream. Single query layer fans out across partitioned data stores. | **High** — maps to Bugbook's multi-database view concept (table/kanban/list over one data set) | Medium / High |
| OpenCode agent provider (#164) | Pluggable alternative to Claude Agent SDK | Medium — validates provider abstraction for AI backends | Low / High |
| Exa search backend (#156) | Configurable search provider for sender lookup. `SearchProvider` protocol with swap-in backends. | Medium — mirrors Bugbook's pluggable search via QMD | Low / Medium |
| Ollama Cloud LLM (#111) | Local/open-source model support alongside Claude | Medium — relevant if Bugbook adds on-device ML | Medium / Medium |
| Priority collapse (#144) | Simplified triage from 3 levels to 2 | Low — UX lesson: simpler categorization wins | Low / Low |

### Architecture Patterns Worth Adopting

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Schema + migrations** | `db/schema.ts` + `db/migrations.ts` — versioned data schema with forward migrations even for a local-first app | Medium | High |
| **Agent permission gate + audit log** | `permission-gate.ts` prevents destructive agent operations; `audit-log.ts` tracks what agents changed | Medium | High |
| **Optimistic reads** | UI reads data optimistically before writes confirm. Database views feel instant while index files update in background. | Low | Medium |
| **Unified query fan-out** | Single query interface that fans out across multiple data stores and merges results | Medium | High |

---

## Top 3 This Week

The three highest-impact, lowest-effort items — all changes to Bugbook's own codebase.

### 1. Add `--dry-run` flag to CLI mutation commands

AppFlowy's #8707 and Exo's `permission-gate.ts` both converge on the same insight: agents need a preview step before making changes. Adding `--dry-run` to `create`, `update`, `delete`, and `batch` commands would print what would change without writing to disk. This is trivial to implement since `MutationEngine` already validates before executing — just return after validation + generate a diff preview.

### 2. Add retry logic for concurrent QMD calls

QMD's open PR #686 reveals that parallel `qmd` processes crash with `SQLITE_BUSY`. Since Bugbook's CLI agent mode can fan out concurrent queries, add a simple retry-with-backoff wrapper around QMD subprocess calls. This is a small change in whatever layer spawns `qmd` processes.

### 3. Add optimistic UI updates to database views

Exo's `optimistic-reads.ts` pattern applies directly: when a user edits a cell in table/kanban view, update the local `rows` array immediately and refresh from the index asynchronously. Currently `DatabaseViewModel.updateProperty()` calls `mutation.execute()` then `refresh()` synchronously — the view freezes during disk I/O. Swap to: update in-memory state → render → mutate in background → reconcile.

---

## Proposed Tickets

### Ticket 1: Add `--dry-run` flag to CLI mutation commands

**Title:** Add `--dry-run` flag to CLI mutation commands

**Description:** Add a `--dry-run` option to `create`, `update`, `delete`, and `batch` CLI commands. When set, the command validates inputs against the schema and prints a JSON diff of what would change (rows created/updated/deleted, index patches) without writing to disk. This enables safe agent workflows where an LLM proposes changes that a human reviews before committing. The `MutationEngine` already separates validation from execution, so the implementation is: run validation, generate a preview struct, serialize it, and exit before the write step.

**Effort:** Low

**Source:** [AppFlowy #8707 — Agentic AI Workspace Assistant](https://github.com/AppFlowy-IO/AppFlowy/issues/8707) (agent-style execution with human confirmation) and [Exo `permission-gate.ts`](https://github.com/ankitvgupta/mail-app) (agent permission gating pattern)

---

### Ticket 2: Add retry wrapper for concurrent QMD subprocess calls

**Title:** Add retry wrapper for concurrent QMD subprocess calls

**Description:** Wrap QMD subprocess invocations with retry-on-failure logic (3 retries, exponential backoff starting at 200ms). QMD's SQLite backend crashes with `SQLITE_BUSY` when multiple processes query simultaneously (tracked upstream as [QMD PR #686](https://github.com/tobi/qmd/pull/686)). Bugbook's agent mode fans out concurrent queries, making this a real crash vector. The fix is a small wrapper around the process-spawning code — catch non-zero exit codes that contain "SQLITE_BUSY" in stderr and retry. Remove the wrapper once QMD #686 ships and Bugbook upgrades.

**Effort:** Low

**Source:** [QMD PR #686 — PRAGMA busy_timeout for concurrent access](https://github.com/tobi/qmd/pull/686)

---

### Ticket 3: Add optimistic UI updates to DatabaseViewModel

**Title:** Add optimistic UI updates to DatabaseViewModel

**Description:** In `DatabaseViewModel.updateProperty()`, apply the property change to the in-memory `rows` array and trigger a SwiftUI render immediately, then perform the `MutationEngine.execute()` and `refresh()` on a background task. If the mutation fails, roll back the optimistic update and show an error. This eliminates the perceived freeze when editing cells in table and kanban views, especially on large databases where index writes take noticeable time. The pattern is proven in Exo's `optimistic-reads.ts` and maps cleanly to SwiftUI's `@Observable` — mutate the published property first, then reconcile.

**Effort:** Low

**Source:** [Exo optimistic-reads.ts](https://github.com/ankitvgupta/mail-app) (optimistic read pattern for responsive database views)
