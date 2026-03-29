# Weekly Open Source Scan — 2026-03-29

Tracking recent activity in open-source projects relevant to Bugbook (Swift-based PKM).

---

## 1. yazinsai/OpenOats

**What it is:** Swift/macOS meeting note-taker using on-device speech-to-text (WhisperKit) and local LLMs (Ollama). ~2k stars, MIT license, one month old and shipping fast (~6 releases this week alone, mostly authored by an AI coding agent with human review).

### Key changes (Mar 22–29)

- **Multi-persona AI sidebar ("Sidecast", #228):** A sidebar where multiple AI personas participate in real time. For Bugbook, this pattern could power a research assistant panel with specialized agents (summarizer, fact-checker, linker).
- **Real-time suggestion engine (#208):** Streams AI suggestions inline while content is being produced. Directly applicable to an editor offering writing assistance, link suggestions, or knowledge graph connections as the user types.
- **Local LLM model discovery (#221, #223):** Dynamically lists locally-running Ollama models in settings, with download progress/ETA UX (#222, #224). Solid reference for integrating local LLMs without a cloud backend.
- **Webhook automation (#205):** Lightweight webhook notifications on lifecycle events (meeting ends). Minimal plugin/automation pattern — a PKM app could use the same approach for triggers like "note saved" or "tag added."
- **Concurrency fix (#203):** Moved LaunchAtLogin check off the main thread. Reminder to audit startup-time checks in Swift apps.

### Takeaways for Bugbook

| Idea | Effort | Impact |
|---|---|---|
| Local LLM discovery + download UX | Medium | High — differentiator for local-first AI |
| Inline AI suggestion engine | High | High — real-time writing assistance |
| Event-driven webhook/plugin system | Low | Medium — extensibility without complexity |
| Multi-persona AI sidebar | High | Medium — advanced but compelling |

---

## 2. tobi/qmd

**What it is:** Local-first CLI search engine for personal documents. TypeScript/Bun, uses SQLite FTS5, sqlite-vec for vector search, BM25 ranking, and LLM reranking. 17.2k stars, MIT license, by Tobias Lutke.

### Key changes (Mar 22–29)

- **AST-aware chunking via tree-sitter (#449):** Opt-in chunking that respects function/class boundaries instead of naive text splitting. 42% reduction in split function bodies. Tree-sitter has Swift bindings.
- **BM25 field weight fix (#462):** Now properly weights `title=4.0, filepath=1.5, body=1.0`. Previously only weighting 1 of 3 FTS columns. One-line fix, outsized impact on search quality.
- **Hyphenated token fix (#463):** Terms like "gpt-4" were parsed as negation operators in FTS5. Converted to quoted phrase queries. Critical if using SQLite FTS5.
- **FTS5 + collection filter CTE performance fix:** Wrapping FTS5 matches in a CTE before joining with collection filters improved query time from **19.8s to 0.4s**. Directly applicable to any SQLite FTS5 usage filtered by folder/tag/notebook.
- **vec0 upsert workaround (#456):** SQLite vec0 doesn't support `INSERT OR REPLACE`. Must use `DELETE` + `INSERT`. Important for local vector search on Apple platforms.
- **Circuit breaker for embedding jobs (#458):** AbortSignal propagation and error-rate circuit breaker to prevent embedding tasks from hanging. Relevant for background indexing pipelines.
- **Rerank toggle on MCP tool (#478):** Lets callers skip expensive LLM reranking when speed matters. Good API design pattern.
- **Rerank context size increase (#453):** 2048 -> 4096 tokens, now configurable via env var. Long documents were being truncated.

### Takeaways for Bugbook

| Idea | Effort | Impact |
|---|---|---|
| FTS5 field weighting (title 4x body) | Trivial | High — instant search quality boost |
| CTE wrapping for filtered FTS5 queries | Trivial | High — prevents catastrophic perf regression |
| Hyphenated token handling in FTS5 | Low | Medium — correctness fix |
| AST-aware chunking for code notes | Medium | High — much better code search |
| vec0 DELETE+INSERT upsert pattern | Low | Medium — required for local vector search |
| Circuit breaker on background indexing | Low | Medium — prevents UI hangs |

---

## 3. AppFlowy-IO/AppFlowy

**What it is:** Open-source Notion alternative. Dart/Flutter frontend, Rust collaboration engine. 68.8k stars, AGPL-3.0. Development velocity on the Flutter client was **low** this week — mostly issue tracker activity.

### Key changes & discussions (Mar 22–29)

- **Cloud sync status indicator requested (#8608):** Users want a persistent visual indicator (connected/disconnected/syncing). Known pain point in local-first apps. Cheap to implement, high trust impact.
- **Formula fields & status properties requested (#8470):** Power users want formula fields in database views — the feature that separates "table" from "spreadsheet-lite." AppFlowy hasn't shipped it, which is an opportunity for competitors.
- **Block-level comments design (#3899):** Proposed architecture for document comments with semantic types (question, suggestion, info). Real-time comments are hard because position tracking within a CRDT document is architecturally complex.
- **Autofill hints on text fields (#8594):** Even Flutter is investing in platform-native autofill integration. In Swift, leverage `NSTextField`/`UITextField` autofill natively.
- **Chinese search + inline actions (#8591):** Open PR improving CJK search in related pages — relevant if Bugbook supports multilingual content.

### Takeaways for Bugbook

| Idea | Effort | Impact |
|---|---|---|
| Sync status indicator (green/yellow/red dot) | Low | High — builds user trust in local-first sync |
| Formula fields in structured data views | High | High — major differentiator |
| Block-level comments with semantic types | Medium | Medium — useful for annotation workflows |
| Rust core for CRDT/sync via Swift FFI | High | High — proven architecture pattern |

---

## Cross-Cutting Themes

1. **SQLite FTS5 is the local search foundation.** QMD's fixes this week (field weighting, CTE filtering, hyphen handling) are all directly applicable to Bugbook's search. These are small changes with large quality and performance impact.

2. **Local-first AI is maturing fast.** Both OpenOats and QMD are building sophisticated local AI pipelines (model discovery, streaming suggestions, vector search, reranking) without cloud dependencies. The patterns are ready to adopt.

3. **Sync trust UX matters.** AppFlowy's most upvoted issue this week is just a sync status dot. Users of local-first apps need visible confirmation that their data is safe.

4. **AST-aware document processing.** QMD's tree-sitter chunking is a significant advance for code-heavy knowledge bases. Tree-sitter has Swift bindings and could power better code block indexing in Bugbook.

5. **AI-assisted development velocity.** OpenOats shipped 6 releases in 7 days using an AI coding agent. Worth considering for Bugbook's own development workflow.
