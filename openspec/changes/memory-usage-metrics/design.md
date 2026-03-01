## Context

Memory hooks inject context into Claude Code sessions across 4 layers (L1-L4), totaling ~3,761 tokens/session on average. We already have injection-side metrics in SQLite (26K+ records across 530 sessions) — but no way to measure whether injected memories actually changed agent behavior. The current "citation rate" (0.59%) uses crude string matching for patterns like "From memory:" which vastly undercounts actual usage.

Key files:
- `bin/wt-hook-memory` — unified hook handler, dispatches by event type
- `lib/metrics.py` — SQLite metrics storage and reporting
- `bin/wt-memory` — CLI with existing `metrics` and `dashboard` subcommands
- `bin/wt-project` — manages CLAUDE.md sections per project

## Goals / Non-Goals

**Goals:**
- Measure true memory usage rate with context_id inject+cite tracking
- Provide a unified `wt-memory tui` dashboard showing DB stats, hook overhead, and usage signals
- Keep hook latency impact near zero (ID generation is cheap)

**Non-Goals:**
- Real-time polling of active sessions (session-end analysis is sufficient)
- Changing memory recall algorithms or relevance thresholds
- Replacing the existing HTML dashboard (TUI supplements it)

## Decisions

### Decision 1: Context ID format — `[MEM#xxxx]`

**Choice**: 4-char hex ID prefix on each injected memory line: `[MEM#a3f2] memory content...`

**Alternatives considered:**
- UUID: too long, wastes tokens
- Sequential counter: doesn't survive across hook invocations within a turn
- 8-char hash: 4 chars is enough (only needs uniqueness within a session, ~65K namespace)

**Rationale**: 4 hex chars = 16 bits = 65,536 unique IDs per session. Average session has ~50 injections with ~3 results each = ~150 IDs needed. Collision probability negligible. Adds only 10 chars overhead per memory line.

### Decision 2: Cite tracking via CLAUDE.md managed section

**Choice**: `wt-project init` adds a managed section to CLAUDE.md instructing the agent to emit `[MEM_CITE:xxxx]` when a memory influences its response.

**Alternatives considered:**
- rules.yaml topic match: too narrow, only fires on keyword match
- Inline in hook output: LLM might not see instructions buried in system-reminder
- SKILL.md hooks: only covers skill invocations, not general prompts

**Rationale**: CLAUDE.md is always in context. The managed section approach (already used for "Persistent Memory" and "Auto-Commit") ensures the rule is present and survives updates. The LLM can choose not to cite — that's signal too (injected but not useful = waste).

### Decision 3: Store inject+cite pairs in existing SQLite

**Choice**: Add `context_id` column to existing `injections` table + new `mem_cites` table for transcript-scanned cites.

**Alternatives considered:**
- Separate SQLite DB: unnecessarily complex, existing DB works fine
- JSON file: no query capability

**Rationale**: The injections table already has session_id and per-injection records. Adding context_id is a simple ALTER TABLE. The cites table links back to session_id + context_id for join queries.

### Decision 4: TUI as single `wt-memory tui` command

**Choice**: New subcommand that combines three data sources in one view: (1) memory DB stats via `wt-memory stats`, (2) hook metrics from SQLite, (3) usage signals from inject/cite ratio.

**Alternatives considered:**
- Interactive curses TUI: over-engineered for this use case
- Extend existing `wt-memory metrics`: already has output, but cramming more makes it unreadable

**Rationale**: Plain text output (like current `metrics` command) but structured into clear sections. Can be piped, redirected, or read in terminal. No external dependencies needed.

## Risks / Trade-offs

- **[Risk] LLM ignores MEM_CITE rule** → Mitigation: the cite-rate metric itself measures compliance. If consistently low, we know the CLAUDE.md rule isn't effective and can iterate. Even partial compliance gives signal.
- **[Risk] Context ID adds token overhead** → Mitigation: 10 chars per memory line × ~3 results per injection = 30 chars = ~8 tokens per injection. Negligible vs. 622 avg tokens per L2 injection.
- **[Risk] ALTER TABLE on live metrics.db** → Mitigation: SQLite handles ALTER TABLE ADD COLUMN safely. Schema migration runs on first access after update.
- **[Risk] TUI data staleness** → Mitigation: TUI reads from SQLite which is flushed at session end. Clearly label "Last updated: <timestamp>" in output.

## Open Questions

- Should we add a `--live` mode to TUI later that reads the session cache JSON for in-progress sessions? (deferred — not in this change)
