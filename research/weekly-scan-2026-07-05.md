# Weekly Research Scan — 2026-07-05

Repos monitored: **OpenOats**, **QMD**, **AppFlowy**, **Exo (mail-app)**
Period: June 28 – July 5, 2026

---

## 1. OpenOats (yazinsai/OpenOats)

> Native macOS (Swift/SwiftUI) meeting note-taker with on-device WhisperKit transcription, local knowledge-base search via embeddings, and LLM-powered suggestions. 2.5k stars, MIT.

### Activity: Moderate (maintenance-focused — bug fixes, no new features)

**Release:** v1.82.1 (June 28) — AirPods input-switch crash fix.

| PR | What shipped | Why it matters |
|----|-------------|----------------|
| #669 | **AVAudioEngine route-change crash fix** — retains recently-stopped engine instances during CoreAudio route changes; prevents double tap removal | Essential pattern for any macOS app with real-time audio capture |
| #672 | **Calendar permission race fix** — moved `updateCalendarIntegration` before first `await` in startup task | Classic Swift concurrency pitfall: synchronous state must be set before first suspension point |
| #670 | Homebrew cask update for v1.82.1 | Routine |

**Notable open PRs:**

| PR | What's proposed | Why it matters |
|----|----------------|----------------|
| #675 | **Adaptive silence floor** — replaces fixed 0.01 threshold with per-mic asymmetric EMA; falls fast (~5s), rises slow (~60s); activity requires 2.5× floor | Proven signal-processing technique for voice activity detection. Reusable in any voice-triggered feature. |
| #673 | **Sidecast token truncation fix** — raises max tokens from 700→1500; parses `finish_reason: "length"` from SSE to append ellipsis | Any streaming LLM integration needs to handle truncation gracefully |
| #676 | **Audio pipeline hardening** (closed, 19 validated findings) — PCMFileWriter tail-flush, AirPods A2DP/HFP re-resolution, checkpoint writes for crash recovery | Checkpoint-write pattern for crash recovery is broadly applicable |

### Patterns worth adapting for Bugbook

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Async initialization ordering** | Permission-gated features must populate state before first `await`. Directly applies to Bugbook's app launch sequence if checking workspace access. | Trivial | Med |
| **Adaptive EMA noise floor** | Asymmetric time constants (fast fall, slow rise) for robust threshold detection. Could apply to "activity detection" in note editing (auto-save frequency, AI suggestions timing). | Med | Med |
| **SSE `finish_reason` handling** | Parse streaming LLM responses for `"length"` truncation and display visual indicator. Critical for Bugbook's AI features (summarization, draft generation). | Low | Med |
| **Checkpoint writes for crash recovery** | Periodic data snapshots during long operations. Applicable to large batch mutations or index rebuilds in Bugbook. | Med | High |

---

## 2. QMD (tobi/qmd)

> On-device hybrid search engine for markdown files. BM25 (SQLite FTS5) + vector similarity (sqlite-vec) + LLM reranking. All local via node-llama-cpp with GGUF models. 19.4k stars, MIT. By Tobi Lütke.

### Activity: Moderate (no main merges; 6 PRs opened/active, 1 critical issue)

No new releases. Latest: **v2.6.3** (June 24).

| PR | What's proposed | Why it matters |
|----|----------------|----------------|
| #755 | **node-llama-cpp v3.19.0 update** — fixes Metal crash on exit with Node v26 (#674), npm install failures on Apple Silicon (#699), Qwen3 reranker score compression (#747). Adds `withLock` concurrency utility. npm→pnpm. | Fixes real macOS ARM64 crash-on-exit bugs |
| #754 | **Cache bug fix** — `insertContext` queried dropped table; `getCachedResult` used `\|\|` instead of `??` (treats empty string as miss) | `\|\|` vs `??` nullish coalescing is a common caching bug to audit for |
| #753 | **Multi-get docid resolution** — `multi_get` didn't resolve short hash docids even though `get` did | Fixes broken batch retrieval when using docid references from search results |
| #752 | **Reranker score in explain output** — adds `explain: true` param exposing raw `rerankScore` per result; blended display score mixes position signals, raw score is pure semantic relevance | **Highly relevant.** Enables relevance-based filtering in Bugbook UI (e.g., only show results above 0.7) |
| #750 | **Per-collection `allowDotDirs`** — index specific hidden directories (e.g., `.aidocs`) while excluding `.git` | Useful if Bugbook stores metadata in dot-directories |
| #468 | **`--follow-symlinks` for collections** (updated Jul 2) | Needed if document store uses symlinks |

**Critical issue:**

| Issue | What | Impact |
|-------|------|--------|
| #751 | **QMD MCP stdio doesn't exit on stdin EOF** — orphans to PID 1, leaks RAM (SQLite + embedding model memory) after parent dies. Multiple instances accumulate hundreds of MB. | **Direct operational concern.** If Bugbook spawns QMD via stdio MCP, users will hit this. **Workaround: use HTTP transport instead.** |

### Patterns worth adapting for Bugbook

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Use HTTP transport for QMD** | Issue #751 means stdio transport leaks memory on macOS. Switch Bugbook's QMD integration to `--host` HTTP mode. | Low | High |
| **`explain: true` for relevance scores** | PR #752 exposes raw reranker scores. Use for confidence indicators or relevance thresholds in search UI. | Low | High |
| **Embedding fingerprinting** | SHA256 of (model version + query format + chunk params). Detects when re-embedding is needed after config changes. | Low | High |
| **Search short-circuit heuristic** | If top BM25 result scores >0.85 with >0.15 gap from #2, skip expensive LLM reranking. Saves significant compute. | Low | Med |
| **`withLock` concurrency pattern** | From PR #755. Prevents concurrent model loads. Applicable to any Swift code managing shared ML resources. | Low | Med |

---

## 3. AppFlowy (AppFlowy-IO/AppFlowy)

> Open-source AI-powered collaborative workspace (Flutter + Rust), 68.9k stars. Notion alternative emphasizing data privacy and local-first architecture.

### Activity: Low (between-release quiet period)

Latest release: **v0.12.5** (June 23) — critical WebSocket/write-to-disk data-loss fix. No new release during this window. The 0.12.x cycle focuses on inline collaboration primitives and data integrity hardening.

**Recent 0.12.x highlights (for context):**

| Version | Key Feature |
|---------|-------------|
| 0.12.5 | Stale WebSocket detection preventing disk-write failures |
| 0.12.4 | Revamped row page comments (UI + notifications); find-and-replace improvements; Kanban column color persistence |
| 0.12.2 | Tab management revamp with shortcuts; inline row comments |
| 0.12.0 | Document version history + restore; inline page comments; AI auto-summarize for YouTube/files |

### Patterns worth adapting for Bugbook

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Document version history** | View/restore previous versions. Essential for trust in local-first apps. Could leverage git-style snapshots of row .md files. | Med–High | High |
| **Inline comments anchored to text** | Threaded comments on specific text ranges with notification support. Applicable to Bugbook row bodies. | Med | Med–High |
| **Stale connection detection + write queue** | Heartbeat + retry with buffered writes. Pattern for any sync layer: detect staleness before writes fail silently. | Med | High |
| **Local AI routing** | Ollama (local) + cloud (GPT-5, Gemini, Claude) behind a unified interface. Users choose privacy vs. capability per-task. | Med | High |
| **Tab management with keyboard shortcuts** | Workspace-aware tab state with Cmd+1-9 switching. Low-hanging UX fruit for Bugbook's tab strip (PR #33). | Low | Med |

---

## 4. Exo / mail-app (ankitvgupta/mail-app)

> AI-native desktop email client — "Claude Code for your Inbox." Electron + React + TypeScript + Claude API. Pre-analyzes every email, prioritizes, and drafts replies. 478 stars, BSL-1.1.

### Activity: Low (no main commits; 2 PRs active)

Latest release: **v0.15.0-beta.1** (June 25). No new release this window.

| PR | What's proposed | Why it matters |
|----|----------------|----------------|
| #180 | **Cmd+O links/attachments palette** — fuzzy search, keyboard nav, image/PDF preview for all links in current item | Command palette for contextual actions — directly applicable UX pattern |
| #169 | **AI calendar invite editor** — press `i` on scheduling emails → Claude extracts event details → review/edit form → create Google Calendar event | AI-powered structured extraction from unstructured content. Pattern applicable to extracting tasks/dates from note text. |

### Architecture deep-dive (low activity week → patterns worth adapting)

| Pattern | Detail | Effort | Impact |
|---------|--------|--------|--------|
| **Hierarchical memory scoping** | 4-tier: item → domain → category → global. Per-scope caps prevent high-volume scopes from drowning out others. Separate context builders for drafting vs. analysis. Adapt for PKM: per-note → per-project → per-topic → global AI context. | Med | High |
| **Background prefetch pipeline** | Priority-based task queue with per-type concurrency limits (analysis=10, drafts=3, profiles=3). Deduplication by key. Throttled progress (max 1/sec). Adapt for background note analysis, tag suggestion, link extraction. | Med | High |
| **Centralized AI service** | Single `createMessage()` entry point with exponential backoff, caller attribution, cost tracking per call (`llm_calls` table with model-aware pricing), injectable test client. | Low | High |
| **Agent permission gate + audit log** | Every agent tool call validated by `PermissionGate`. Full audit trail in `agent_audit_log` table. Critical for user trust in any agent-powered app. | Med | High |
| **Build-time extension inlining** | Extensions discovered at compile time via static imports + glob. No runtime filesystem scanning. Extension-scoped KV storage table. | Med | High |
| **Draft memory voting** | Low-confidence AI observations stored in `draft_memories` with voting before promotion. Prevents noise in the memory system. | Med | Med |
| **Undo-action toast** | Optimistic actions with undo window. Good UX for destructive PKM operations. | Trivial | Med |

---

## Top 3 This Week

The three highest-impact, lowest-effort items to act on first:

### 1. Switch QMD integration to HTTP transport (from QMD issue #751)
**Effort: Low | Impact: High**
The stdio MCP transport leaks memory when the parent process dies — QMD processes orphan to PID 1 and accumulate hundreds of MB. This is a ticking time bomb for any app spawning QMD as a subprocess. Switch to HTTP transport (`qmd mcp --host`) which doesn't have this lifecycle issue. One config change in Bugbook's QMD integration layer.

### 2. Add relevance score threshold to search results UI (from QMD PR #752)
**Effort: Low | Impact: High**
QMD's new `explain: true` parameter exposes raw reranker scores per search result — a pure semantic relevance measure (unlike the blended display score). Use this to show confidence indicators in Bugbook's search UI and filter out low-relevance noise (e.g., hide results below 0.5). Requires passing one extra parameter in MCP calls and reading one additional field from results.

### 3. Hierarchical AI context scoping (from Exo architecture)
**Effort: Medium | Impact: High**
Exo's 4-tier memory system (item → domain → category → global) with per-scope caps is the right architecture for AI-powered features in a PKM. Adapt as: per-note → per-database → per-tag/project → global. Each scope independently capped so prolific databases don't drown out sparse but important ones. This is the foundation for personalized AI summaries, smart suggestions, and contextual search boosting.

---

## Proposed Tickets

### Ticket 1: Use HTTP transport for QMD MCP integration

**Title:** Switch QMD subprocess to HTTP transport to prevent orphan process leaks

**Description:** Bugbook currently spawns QMD via stdio MCP transport. Issue [tobi/qmd#751](https://github.com/tobi/qmd/issues/751) documents that QMD's stdio mode doesn't detect parent death (stdin EOF is never fired by the MCP SDK's `StdioServerTransport`). This causes orphaned processes that leak hundreds of MB (SQLite + embedding model memory).

Change Bugbook's QMD integration to use HTTP transport (`qmd mcp --host 127.0.0.1:PORT`) instead. HTTP transport has clean lifecycle management — the server exits when the socket closes. Add a health-check ping on app launch and graceful shutdown on app quit.

**Effort:** Low
**Source:** https://github.com/tobi/qmd/issues/751

---

### Ticket 2: Display relevance confidence in search results

**Title:** Add relevance score indicator to search results using QMD explain mode

**Description:** QMD PR [#752](https://github.com/tobi/qmd/pull/752) adds an `explain: true` parameter to MCP `query` calls that returns raw `rerankScore` per result. The blended display score mixes ranking position signals; the raw score is a pure semantic relevance measure (0.0–1.0).

In Bugbook's search results view:
1. Pass `explain: true` in QMD MCP queries
2. Read `rerankScore` from results
3. Display a subtle confidence indicator (e.g., opacity/dot color) based on score
4. Add a user-configurable threshold to filter out low-relevance results (default: show all, advanced setting to hide below 0.5)

This gives users immediate signal about which results are strong matches vs. tangential.

**Effort:** Low
**Source:** https://github.com/tobi/qmd/pull/752

---

### Ticket 3: Implement hierarchical AI context scoping

**Title:** Add 4-tier scoped memory system for AI context assembly

**Description:** Inspired by [Exo's memory-context architecture](https://github.com/ankitvgupta/mail-app), implement a hierarchical scoping system for AI context in Bugbook. When assembling context for AI features (summarization, suggestions, search boosting), draw from four tiers:

1. **Note-level** — memories specific to one row/page (most specific)
2. **Database-level** — patterns observed across a database (e.g., "Tasks in this project use story points")
3. **Tag/project-level** — cross-database context for a topic
4. **Global** — account-wide preferences and style

Each tier has independent capacity caps so high-volume databases don't crowd out sparse but important context. Implement separate context builders for different AI call types (generation vs. analysis vs. search).

Store in a new `_memories.json` file per database (tiers 1-2) and a workspace-level `.bugbook/memories.json` (tiers 3-4). This is the foundation for all personalized AI features.

**Effort:** Medium
**Source:** `src/main/services/memory-context.ts` in [ankitvgupta/mail-app](https://github.com/ankitvgupta/mail-app)
