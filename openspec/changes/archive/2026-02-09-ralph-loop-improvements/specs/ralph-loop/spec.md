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

#### Scenario: Iteration history entry
- **WHEN** Ralph completes an iteration
- **THEN** adds entry to `iterations` array with:
  - `n`: number - iteration number
  - `started`: string - ISO timestamp
  - `ended`: string - ISO timestamp
  - `done_check`: boolean - whether done criteria met
  - `commits`: array - commit hashes made
  - `tokens_used`: number - tokens consumed this iteration
  - `timed_out`: boolean - whether iteration was killed by timeout (optional, only if true)

### Requirement: Default done criteria
The Ralph loop SHALL default to `tasks` done criteria instead of `manual`.

#### Scenario: Default done criteria with tasks.md present
- **WHEN** user starts a loop without `--done` flag
- **AND** a `tasks.md` file exists in the change directory or worktree
- **THEN** done criteria SHALL be "tasks"

#### Scenario: Default done criteria without tasks.md
- **WHEN** user starts a loop without `--done` flag
- **AND** no `tasks.md` file exists
- **THEN** done criteria SHALL fall back to "manual"
- **AND** a warning SHALL be displayed: "No tasks.md found, using manual done criteria"

#### Scenario: Explicit manual override
- **WHEN** user starts a loop with `--done manual`
- **THEN** done criteria SHALL be "manual" regardless of tasks.md presence

### Requirement: Robust state recording on termination
The Ralph loop SHALL record iteration state even on abnormal termination.

#### Scenario: Loop killed by SIGTERM
- **WHEN** the loop process receives SIGTERM during an iteration
- **THEN** the current iteration SHALL be recorded with an `ended` timestamp
- **AND** any commits detected so far SHALL be included
- **AND** loop status SHALL be updated to "stopped"

#### Scenario: Loop killed by SIGINT
- **WHEN** the loop process receives SIGINT (Ctrl+C)
- **THEN** the same cleanup as SIGTERM SHALL occur

#### Scenario: Partial iteration on exit
- **WHEN** the loop exits for any reason during an active iteration
- **THEN** the EXIT trap SHALL ensure the iteration is recorded in the state file

### Requirement: Token tracking reliability
The Ralph loop SHALL reliably track token usage per iteration.

#### Scenario: Token counting via wt-usage
- **WHEN** an iteration completes
- **THEN** token count SHALL be calculated as the difference between pre- and post-iteration `wt-usage --since` values
- **AND** if the result is 0 or negative, the system SHALL log a warning to stderr

#### Scenario: Token tracking failure fallback
- **WHEN** `wt-usage` fails or returns 0
- **THEN** the system SHALL estimate tokens from session file size growth
- **AND** mark the value as estimated in the iteration record: `"tokens_estimated": true`

### Requirement: Terminal title progress updates
The Ralph loop terminal SHALL display current progress in the window title.

#### Scenario: Title updates per iteration
- **WHEN** a new iteration starts
- **THEN** the terminal title SHALL be updated to: "Ralph: {change_id} [{iteration}/{max}]"

#### Scenario: Title on completion
- **WHEN** the loop completes (done/stuck/stalled)
- **THEN** the terminal title SHALL be updated to: "Ralph: {change_id} [{status}]"
