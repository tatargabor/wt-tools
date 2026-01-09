## ADDED Requirements

### Requirement: Query Ralph status via MCP
The system SHALL expose a `get_ralph_status()` MCP tool that returns Ralph loop state for any worktree.

#### Scenario: Query specific change
- **WHEN** agent calls `get_ralph_status(change_id="fix-bug")`
- **THEN** returns status for that specific Ralph loop
- **AND** includes: status, iteration, max_iterations, duration, task

#### Scenario: Query all loops
- **WHEN** agent calls `get_ralph_status()` without change_id
- **THEN** returns status for ALL active Ralph loops across all projects
- **AND** each entry includes project name and change_id

#### Scenario: No active loop
- **WHEN** agent queries Ralph status for non-existent loop
- **THEN** returns message "No Ralph loop found for: <change-id>"

### Requirement: Ralph status includes timing
The system SHALL include timing information in Ralph status responses.

#### Scenario: Duration calculation
- **WHEN** Ralph loop is running
- **THEN** status includes duration since `started_at` timestamp
- **AND** format is human-readable (e.g., "1h 23m" or "45m")

#### Scenario: Iteration timing
- **WHEN** Ralph status is queried
- **THEN** response includes current iteration and max iterations
- **AND** format is "iteration X/Y"

### Requirement: Status line shows current worktree Ralph
The system SHALL support status line integration showing Ralph status for the current worktree only.

#### Scenario: Status line context detection
- **WHEN** status line hook runs
- **THEN** detects current worktree from pwd
- **AND** extracts change-id from path pattern `<project>-wt-<change-id>`

#### Scenario: Status line format
- **WHEN** Ralph is running in current worktree
- **THEN** status line shows: `🔄 Ralph: 3/10 (12m)`
- **AND** includes emoji, iteration count, and duration

#### Scenario: No Ralph running
- **WHEN** no Ralph loop in current worktree
- **THEN** status line shows nothing (empty)
