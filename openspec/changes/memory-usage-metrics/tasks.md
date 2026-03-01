## 1. SQLite Schema Migration

- [ ] 1.1 Add `context_ids TEXT DEFAULT '[]'` column to `injections` table in `lib/metrics.py` SCHEMA_SQL and add migration logic in `_get_db()` for existing DBs
- [ ] 1.2 Create `mem_cites` table with columns: `id` (autoincrement), `session_id` (text), `context_id` (text), `UNIQUE(session_id, context_id)` in SCHEMA_SQL
- [ ] 1.3 Add `cite_count INTEGER DEFAULT 0` and `injected_id_count INTEGER DEFAULT 0` columns to `sessions` table in SCHEMA_SQL with migration for existing DBs

## 2. Context ID Generation in Hook

- [ ] 2.1 Add `_gen_context_id()` function to `bin/wt-hook-memory` that generates a 4-char hex ID unique within the session (use session-level counter or random with collision check via dedup cache)
- [ ] 2.2 Modify `proactive_and_format()` to prefix each output line with `[MEM#xxxx]` and return the list of generated IDs
- [ ] 2.3 Modify `recall_and_format()` to prefix each output line with `[MEM#xxxx]` and return the list of generated IDs
- [ ] 2.4 Update `_metrics_append()` to accept and store a `context_ids` array parameter
- [ ] 2.5 Update all call sites of `_metrics_append()` across all event handlers (SessionStart, UserPromptSubmit, PostToolUse, PostToolUseFailure, SubagentStart) to pass the generated context_ids

## 3. Transcript Cite Scanning

- [ ] 3.1 Extend `scan_transcript_citations()` in `lib/metrics.py` to detect `[MEM_CITE:xxxx]` regex pattern and return entries with `type: "context_id"` and `context_id` field
- [ ] 3.2 Deduplicate MEM_CITE matches by context_id within a session (only one row per unique ID)
- [ ] 3.3 Update `flush_session()` to accept `mem_cites` list, insert into `mem_cites` table, compute `injected_id_count` from metrics records' `context_ids` arrays, and set `cite_count` on session

## 4. CLAUDE.md Cite Rule

- [ ] 4.1 Add managed section deployment in `bin/wt-project` for `<!-- wt-tools:managed:mem-cite -->` marker with the MEM_CITE instruction text
- [ ] 4.2 Ensure `wt-project init` deploys the cite rule section (insert if missing, update if present)

## 5. Stop Hook Integration

- [ ] 5.1 Update `_stop_flush_metrics()` in `bin/wt-hook-memory` to pass context_id citation data from transcript scan to `flush_session()`
- [ ] 5.2 Extract `context_ids` from session cache `_metrics` array and pass to `flush_session()` for `injected_id_count` calculation

## 6. Usage Rate Reporting

- [ ] 6.1 Add usage rate queries to `query_report()` in `lib/metrics.py`: compute `total_injected_ids`, `total_cited_ids`, `usage_rate` from sessions table
- [ ] 6.2 Update `format_tui_report()` to display usage rate in the USAGE SIGNALS section
- [ ] 6.3 Update existing `wt-memory metrics` JSON output to include `usage_rate`, `total_injected_ids`, `total_cited_ids`

## 7. TUI Dashboard Command

- [ ] 7.1 Add `cmd_tui()` function to `bin/wt-memory` with `--since` and `--json` argument parsing
- [ ] 7.2 Implement Memory Database section: call `wt-memory stats --json` and format total count, type distribution, noise ratio, top tags
- [ ] 7.3 Implement Hook Overhead section: read from `query_report()` and format per-layer breakdown with count, avg tokens, avg relevance, avg duration
- [ ] 7.4 Implement Usage Signals section: display usage rate (cited/injected), legacy citation rate, relevance distribution histogram (ASCII bars), empty injection rate
- [ ] 7.5 Implement Daily Trend section: ASCII sparklines for token burn, relevance, and usage rate using block characters (▁▂▃▄▅▆▇█)
- [ ] 7.6 Add `tui` to the command dispatch case statement in `bin/wt-memory`
- [ ] 7.7 Implement JSON output mode for `wt-memory tui --json` combining all section data

## 8. Testing

- [ ] 8.1 Test schema migration: verify ALTER TABLE runs cleanly on existing metrics.db with data
- [ ] 8.2 Test context ID generation: verify uniqueness across multiple invocations within a session
- [ ] 8.3 Test MEM_CITE transcript scanning: verify regex finds `[MEM_CITE:xxxx]` patterns and deduplicates
- [ ] 8.4 Test TUI output: verify all sections render with both real data and empty/missing data
- [ ] 8.5 Test backward compatibility: verify sessions without context_id data display gracefully (N/A usage rate)
