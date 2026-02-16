## MODIFIED Requirements

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
  - `status`: string - one of "starting", "running", "done", "stuck", "stalled", "stopped"
  - `current_iteration`: number - current iteration (1-based)
  - `max_iterations`: number - configured maximum
  - `started_at`: string - ISO 8601 timestamp
  - `task`: string - the task description
  - `iterations`: array - history of completed iterations
  - `done_criteria`: string - "tasks" or "manual"
  - `stall_threshold`: number - consecutive commit-less iterations before stall
  - `iteration_timeout_min`: number - per-iteration timeout in minutes
  - `total_tokens`: number - cumulative token count across all iterations
  - `label`: string or null - optional user-provided label for loop identification

### Requirement: Terminal title progress updates
The Ralph loop terminal SHALL display current progress in the window title.

#### Scenario: Title updates per iteration
- **WHEN** a new iteration starts
- **AND** a label is set
- **THEN** the terminal title SHALL be updated to: "Ralph: {change_id} ({label}) [{iteration}/{max}]"

#### Scenario: Title updates per iteration without label
- **WHEN** a new iteration starts
- **AND** no label is set
- **THEN** the terminal title SHALL be updated to: "Ralph: {change_id} [{iteration}/{max}]"

#### Scenario: Title on completion
- **WHEN** the loop completes (done/stuck/stalled)
- **AND** a label is set
- **THEN** the terminal title SHALL be updated to: "Ralph: {change_id} ({label}) [{status}]"

#### Scenario: Title on completion without label
- **WHEN** the loop completes (done/stuck/stalled)
- **AND** no label is set
- **THEN** the terminal title SHALL be updated to: "Ralph: {change_id} [{status}]"
