## MODIFIED Requirements

### Requirement: TUI metrics report command
The `wt-memory metrics` command SHALL read the SQLite database and print a formatted text report to stdout, including usage rate from context_id tracking.

#### Scenario: Default report (last 7 days)
- **WHEN** `wt-memory metrics` is run without arguments
- **THEN** it SHALL display metrics for the last 7 days including: session count, total injections, total tokens burned, per-layer breakdown (count, avg tokens, avg relevance), relevance distribution (strong >0.7, partial 0.3-0.7, filtered <0.3), usage rate (cited/injected), legacy citation rate, dedup hit rate, empty injection rate

#### Scenario: Custom time range
- **WHEN** `wt-memory metrics --since 30d` is run
- **THEN** it SHALL display metrics for the last 30 days

#### Scenario: JSON output
- **WHEN** `wt-memory metrics --json` is run
- **THEN** it SHALL output the same data as structured JSON including `usage_rate`, `total_injected_ids`, `total_cited_ids` fields

#### Scenario: No data available
- **WHEN** `wt-memory metrics` is run and the database is empty or does not exist
- **THEN** it SHALL print "No metrics data. Enable with: wt-memory metrics --enable" and exit 0

## ADDED Requirements

### Requirement: SQLite schema migration for context IDs
The metrics SQLite schema SHALL add support for context_id storage when first accessed after upgrade.

#### Scenario: Schema migration on existing DB
- **WHEN** `_get_db()` opens an existing metrics.db that lacks the `context_ids` column in `injections`
- **THEN** it SHALL run `ALTER TABLE injections ADD COLUMN context_ids TEXT DEFAULT '[]'` without data loss

#### Scenario: New mem_cites table creation
- **WHEN** `_get_db()` opens the database
- **THEN** it SHALL ensure a `mem_cites` table exists with columns: `id` (autoincrement), `session_id` (text), `context_id` (text, 4-char hex), `UNIQUE(session_id, context_id)`

#### Scenario: Sessions table cite_count column
- **WHEN** `_get_db()` opens an existing metrics.db that lacks `cite_count` in `sessions`
- **THEN** it SHALL add `cite_count INTEGER DEFAULT 0` and `injected_id_count INTEGER DEFAULT 0` columns

### Requirement: Flush session with context ID data
The `flush_session()` function SHALL accept and store context_id injection counts and citation counts.

#### Scenario: Session flush with context IDs
- **WHEN** `flush_session()` is called with metrics records containing `context_ids` arrays
- **THEN** it SHALL compute `injected_id_count` as the total number of unique context IDs across all records and store it in the sessions table

#### Scenario: Session flush with citations
- **WHEN** `flush_session()` is called with a `mem_cites` list of `{context_id}` dicts
- **THEN** it SHALL insert each into `mem_cites` table and set `cite_count` in the sessions table

### Requirement: Usage rate in query_report
The `query_report()` function SHALL include usage rate data in its return value.

#### Scenario: Report with context_id data
- **WHEN** `query_report()` runs and sessions have `injected_id_count` > 0
- **THEN** the returned dict SHALL include `usage_rate` (float, 0-100), `total_injected_ids` (int), `total_cited_ids` (int)

#### Scenario: Report without context_id data
- **WHEN** `query_report()` runs and all sessions have `injected_id_count = 0`
- **THEN** the returned dict SHALL include `usage_rate: null`, `total_injected_ids: 0`, `total_cited_ids: 0`

### Requirement: Cite scanning for MEM_CITE pattern
The `scan_transcript_citations()` function SHALL detect `[MEM_CITE:xxxx]` patterns in addition to legacy string patterns.

#### Scenario: MEM_CITE pattern found
- **WHEN** transcript scanning finds `[MEM_CITE:a1b2]` in an assistant message
- **THEN** it SHALL include `{"text": "[MEM_CITE:a1b2]", "type": "context_id", "context_id": "a1b2"}` in the returned list

#### Scenario: Legacy citation pattern found
- **WHEN** transcript scanning finds "From memory:" in an assistant message
- **THEN** it SHALL include `{"text": "...snippet...", "type": "explicit"}` as before (backward compatible)

#### Scenario: Both patterns in same transcript
- **WHEN** a transcript contains both `[MEM_CITE:xxxx]` and "From memory:" patterns
- **THEN** both SHALL be returned, each with their respective type
