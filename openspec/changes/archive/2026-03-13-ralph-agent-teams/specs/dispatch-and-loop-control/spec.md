## MODIFIED Requirements

### Requirement: ff→apply same-iteration chaining
When an ff iteration successfully creates tasks.md, the loop SHALL chain the apply phase within the same iteration instead of ending and starting a new one.

#### Scenario: ff creates tasks.md — chain apply
- **WHEN** a loop iteration runs `opsx:ff` for a change
- **AND** after the Claude invocation, `tasks.md` exists in the change directory
- **AND** `detect_next_change_action()` returns `apply:*`
- **THEN** the loop SHALL NOT end the current iteration
- **AND** SHALL build a new prompt with the `/opsx:apply` instruction
- **AND** the chained apply prompt SHALL respect `execution_mode` (parallel or single)
- **AND** SHALL pipe it to a second `claude` invocation in the same iteration
- **AND** the iteration record SHALL include both the ff and apply phases

#### Scenario: ff fails to create tasks.md — no chaining
- **WHEN** a loop iteration runs `opsx:ff`
- **AND** after the Claude invocation, `tasks.md` does NOT exist
- **THEN** the loop SHALL end the iteration normally (existing ff retry logic applies)
- **AND** no apply chaining SHALL be attempted

#### Scenario: Chained apply fails or times out
- **WHEN** the chained apply invocation fails (non-zero exit) or exceeds the iteration timeout
- **THEN** the iteration SHALL end normally
- **AND** the next iteration SHALL pick up `apply:*` from `detect_next_change_action()` as before
- **AND** this SHALL NOT be counted as a stall

#### Scenario: Chained apply produces commits
- **WHEN** the chained apply invocation produces commits
- **THEN** those commits SHALL be recorded in the same iteration's metadata
- **AND** the stall counter SHALL be reset (progress was made)

#### Scenario: Iteration counter not incremented for chain
- **WHEN** ff chains to apply within the same iteration
- **THEN** the iteration counter SHALL NOT be incremented
- **AND** the max_iterations limit SHALL count this as one iteration, not two

## ADDED Requirements

### Requirement: Parallel CLI flag
The `wt-loop start` command SHALL accept a `--parallel` flag to enable parallel subagent execution.

#### Scenario: Start with parallel flag
- **WHEN** user runs `wt-loop start "task" --parallel`
- **THEN** `execution_mode` in loop-state.json SHALL be set to `"parallel"`
- **AND** `parallel_workers` SHALL default to 2

#### Scenario: Start with parallel and workers
- **WHEN** user runs `wt-loop start "task" --parallel --workers 3`
- **THEN** `execution_mode` SHALL be `"parallel"`
- **AND** `parallel_workers` SHALL be 3

#### Scenario: Start without parallel flag
- **WHEN** user runs `wt-loop start "task"` (no --parallel)
- **THEN** `execution_mode` SHALL be `"single"`
- **AND** `parallel_workers` SHALL NOT be set (or default to 1)

### Requirement: Orchestrator parallel dispatch
The orchestrator SHALL pass parallel configuration to Ralph loops when configured.

#### Scenario: Per-change parallel config
- **WHEN** `orchestration.yaml` has `execution_mode: parallel` for a specific change
- **THEN** the dispatcher SHALL pass `--parallel` to `wt-loop start`
- **AND** SHALL pass `--workers N` if `parallel_workers` is specified

#### Scenario: Global parallel config
- **WHEN** `orchestration.yaml` has `execution_mode: parallel` at the global level
- **AND** the specific change does not override it
- **THEN** the dispatcher SHALL pass `--parallel` to `wt-loop start`

#### Scenario: No parallel config
- **WHEN** `orchestration.yaml` does not specify `execution_mode`
- **THEN** the dispatcher SHALL NOT pass `--parallel`
- **AND** Ralph SHALL run in single mode (backward compatible)
