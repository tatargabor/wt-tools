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
  - `status`: string - one of "starting", "running", "done", "stuck", "stalled", "stopped", "waiting:human", "waiting:budget"
  - `current_iteration`: number - current iteration (1-based)
  - `max_iterations`: number - configured maximum
  - `started_at`: string - ISO 8601 timestamp
  - `task`: string - the task description
  - `iterations`: array - history of completed iterations
  - `done_criteria`: string - "tasks", "openspec", or "manual"
  - `stall_threshold`: number - consecutive commit-less iterations before stall
  - `iteration_timeout_min`: number - per-iteration timeout in minutes
  - `total_tokens`: number - cumulative token count across all iterations
  - `label`: string or null - optional user-provided label for loop identification
  - `session_id`: string or null - Claude session UUID for resume
  - `resume_failures`: number - count of `--resume` failures (default 0)
  - `execution_mode`: string - "single" (default) or "parallel"
  - `parallel_workers`: number - worker count for parallel mode (default 2)

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
  - `no_op`: boolean - whether iteration produced no meaningful work (optional, only if true)
  - `ff_exhausted`: boolean - whether ff retry limit was exceeded (optional, only if true)
  - `ff_recovered`: boolean - whether fallback tasks.md was generated (optional, only if true)
  - `log_file`: string - path to per-iteration log file
  - `resumed`: boolean - whether this iteration used `--resume` (optional, only if true)

## ADDED Requirements

### Requirement: Parallel prompt selection
The prompt builder SHALL select the parallel prompt template when execution_mode is parallel and the current action is apply.

#### Scenario: Parallel mode with apply action
- **WHEN** `build_prompt()` is called
- **AND** `execution_mode` in state file is `"parallel"`
- **AND** `detect_next_change_action()` returns `apply:*`
- **THEN** the prompt SHALL include parallel subagent instructions
- **AND** SHALL specify `parallel_workers` from state as the worker count

#### Scenario: Parallel mode with ff action
- **WHEN** `build_prompt()` is called
- **AND** `execution_mode` is `"parallel"`
- **AND** `detect_next_change_action()` returns `ff:*`
- **THEN** the prompt SHALL use the standard single-agent ff prompt
- **AND** SHALL NOT include parallel subagent instructions

#### Scenario: Single mode unchanged
- **WHEN** `execution_mode` is `"single"` or absent
- **THEN** `build_prompt()` SHALL produce the exact same prompt as today
- **AND** no parallel instructions SHALL be included

### Requirement: Resume prompt parallel awareness
The session resume prompt SHALL re-apply parallel mode instructions when the state indicates parallel execution.

#### Scenario: Resume in parallel mode
- **WHEN** the loop resumes a session (`--resume`)
- **AND** `execution_mode` is `"parallel"`
- **AND** the current action is `apply:*`
- **THEN** the resume prompt SHALL include "Use parallel Agent tool calls to continue implementing tasks"
- **AND** SHALL specify the worker count

#### Scenario: Resume in single mode
- **WHEN** the loop resumes a session
- **AND** `execution_mode` is `"single"` or absent
- **THEN** the resume prompt SHALL be the standard continuation message
