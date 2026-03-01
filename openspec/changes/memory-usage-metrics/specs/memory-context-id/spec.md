## ADDED Requirements

### Requirement: Context ID generation for injected memories
Each memory fragment injected by hook output SHALL be prefixed with a unique context ID in the format `[MEM#xxxx]` where `xxxx` is a 4-character lowercase hex string.

#### Scenario: Proactive recall with multiple results
- **WHEN** `proactive_and_format()` returns 3 memory lines for a UserPromptSubmit hook
- **THEN** each line SHALL be prefixed with a unique context ID: `[MEM#a1b2] memory content...`, `[MEM#c3d4] memory content...`, `[MEM#e5f6] memory content...`

#### Scenario: Recall with single result
- **WHEN** `recall_and_format()` returns 1 memory line for a PostToolUse hook
- **THEN** the line SHALL be prefixed with a context ID: `[MEM#xxxx] memory content...`

#### Scenario: ID uniqueness within session
- **WHEN** multiple hook invocations occur within a single session
- **THEN** all generated context IDs SHALL be unique within that session (no reuse across invocations)

### Requirement: Context ID recorded in metrics
Each injection metrics record SHALL include the list of context IDs that were injected.

#### Scenario: Metrics record with context IDs
- **WHEN** a hook injects 3 memories with IDs `a1b2`, `c3d4`, `e5f6`
- **THEN** the metrics record `_metrics` entry SHALL include `"context_ids": ["a1b2", "c3d4", "e5f6"]`

#### Scenario: Empty injection metrics
- **WHEN** a hook produces no results (dedup hit or no matches)
- **THEN** the metrics record SHALL include `"context_ids": []`

### Requirement: CLAUDE.md cite rule deployment
The `wt-project init` command SHALL add a managed section to target project CLAUDE.md instructing the agent to emit `[MEM_CITE:xxxx]` when a memory influences its response.

#### Scenario: Fresh project init
- **WHEN** `wt-project init` runs on a project without the cite rule section
- **THEN** a managed section with marker `<!-- wt-tools:managed:mem-cite -->` SHALL be added to CLAUDE.md containing the cite instruction

#### Scenario: Re-run updates content
- **WHEN** `wt-project init` runs on a project that already has the cite rule section
- **THEN** the managed section content SHALL be replaced with the latest version

#### Scenario: Cite rule content
- **WHEN** the managed section is deployed
- **THEN** it SHALL instruct: "When information from a `[MEM#xxxx]` tagged memory in a system-reminder directly influences your response, include `[MEM_CITE:xxxx]` in your output (inline, not as a separate line). This is optional — only cite when a memory actually changed what you would have done."

### Requirement: Transcript cite scanning
The Stop hook SHALL scan the session transcript for `[MEM_CITE:xxxx]` patterns and record matched citations.

#### Scenario: Agent cites a memory
- **WHEN** the transcript contains assistant text with `[MEM_CITE:a1b2]`
- **THEN** the Stop hook SHALL record a citation with `context_id=a1b2` and `session_id` in the SQLite `mem_cites` table

#### Scenario: Multiple cites in one message
- **WHEN** the transcript contains assistant text with `[MEM_CITE:a1b2]` and `[MEM_CITE:c3d4]`
- **THEN** both citations SHALL be recorded as separate rows

#### Scenario: No cites in session
- **WHEN** the transcript contains no `[MEM_CITE:xxxx]` patterns
- **THEN** no rows SHALL be inserted into `mem_cites` and the session's `cite_count` SHALL be 0

#### Scenario: Duplicate cite IDs
- **WHEN** the same `[MEM_CITE:a1b2]` appears multiple times in a transcript
- **THEN** only one citation row SHALL be recorded per unique context_id per session

### Requirement: Usage rate calculation
The metrics system SHALL calculate a usage rate as `cited_ids / injected_ids` per session and across sessions.

#### Scenario: Session with 15 injected IDs and 3 cited
- **WHEN** a session injected 15 unique context IDs and the transcript contains 3 unique MEM_CITE matches
- **THEN** the session usage rate SHALL be `3/15 = 20.0%`

#### Scenario: Session with no injections
- **WHEN** a session had zero memory injections
- **THEN** the usage rate SHALL be reported as `N/A` (not 0%)

#### Scenario: Aggregate usage rate
- **WHEN** reporting across multiple sessions
- **THEN** the aggregate usage rate SHALL be `total_cited_ids / total_injected_ids` across all sessions in the time range
