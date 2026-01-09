## ADDED Requirements

### Requirement: Ralph loop state file format
The Ralph loop SHALL write state to `<worktree>/.claude/loop-state.json` with a documented, stable format for MCP consumption.

#### Scenario: State file location
- **WHEN** Ralph loop starts
- **THEN** creates/updates `.claude/loop-state.json` in worktree root
- **AND** file is worktree-scoped (not global)

#### Scenario: State file schema
- **WHEN** Ralph writes loop-state.json
- **THEN** JSON includes required fields:
  - `change_id`: string - the change identifier
  - `status`: string - one of "starting", "running", "done", "stuck", "stopped"
  - `current_iteration`: number - current iteration (0-based)
  - `max_iterations`: number - configured maximum
  - `started_at`: string - ISO 8601 timestamp
  - `task`: string - the task description
  - `iterations`: array - history of completed iterations

#### Scenario: Iteration history entry
- **WHEN** Ralph completes an iteration
- **THEN** adds entry to `iterations` array with:
  - `n`: number - iteration number
  - `started`: string - ISO timestamp
  - `ended`: string - ISO timestamp
  - `done_check`: boolean - whether done criteria met
  - `commits`: array - commit hashes made

### Requirement: State file atomic updates
The Ralph loop SHALL update state file atomically to prevent partial reads.

#### Scenario: Concurrent read safety
- **WHEN** MCP reads loop-state.json while Ralph writes
- **THEN** MCP receives complete valid JSON
- **AND** no partial/corrupted data

#### Scenario: Write with temp file
- **WHEN** Ralph updates state
- **THEN** writes to temp file first
- **AND** atomically moves to loop-state.json
