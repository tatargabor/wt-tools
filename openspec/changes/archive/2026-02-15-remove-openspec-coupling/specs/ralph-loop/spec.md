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
  - `worktree_name`: string - the basename of the worktree directory
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
- **AND** a `tasks.md` file exists in the worktree (at root or discoverable via find)
- **THEN** done criteria SHALL be "tasks"

#### Scenario: Default done criteria without tasks.md
- **WHEN** user starts a loop without `--done` flag
- **AND** no `tasks.md` file exists
- **THEN** done criteria SHALL fall back to "manual"
- **AND** a warning SHALL be displayed: "No tasks.md found, using manual done criteria"

#### Scenario: Explicit manual override
- **WHEN** user starts a loop with `--done manual`
- **THEN** done criteria SHALL be "manual" regardless of tasks.md presence

### Requirement: Terminal title progress updates
The Ralph loop terminal SHALL display current progress in the window title.

#### Scenario: Title updates per iteration
- **WHEN** a new iteration starts
- **THEN** the terminal title SHALL be updated to: "Ralph: {worktree_name} [{iteration}/{max}]"

#### Scenario: Title on completion
- **WHEN** the loop completes (done/stuck/stalled)
- **THEN** the terminal title SHALL be updated to: "Ralph: {worktree_name} [{status}]"

### Requirement: CWD-based worktree detection
The Ralph loop SHALL derive the worktree path from the current working directory instead of requiring an explicit identifier parameter.

#### Scenario: Detect worktree from CWD
- **WHEN** any wt-loop subcommand runs (start, stop, status, history, monitor)
- **THEN** the worktree path SHALL be resolved via `git rev-parse --show-toplevel`
- **AND** no positional identifier argument is required

#### Scenario: Not inside a git worktree
- **WHEN** wt-loop runs outside a git repository
- **THEN** an error SHALL be displayed: "Not inside a git worktree. Run from within a worktree directory."

#### Scenario: Run subcommand uses CWD
- **WHEN** wt-loop run is invoked (by the spawned terminal)
- **THEN** it derives worktree path from CWD
- **AND** no identifier argument is passed

### Requirement: Generic tasks.md lookup
The Ralph loop SHALL search for tasks.md without assuming any specific directory structure.

#### Scenario: tasks.md at worktree root
- **WHEN** checking for tasks.md
- **AND** `$wt_path/tasks.md` exists
- **THEN** that file SHALL be used

#### Scenario: tasks.md in subdirectory
- **WHEN** checking for tasks.md
- **AND** no `$wt_path/tasks.md` exists
- **THEN** the system SHALL search with `find $wt_path -maxdepth 3 -name tasks.md` excluding `archive/` and `node_modules/`
- **AND** use the first result found

#### Scenario: No tasks.md found
- **WHEN** checking for tasks.md
- **AND** no tasks.md exists anywhere in the worktree
- **THEN** a warning SHALL be displayed
- **AND** done criteria SHALL fall back to "manual"
