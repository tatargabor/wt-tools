## ADDED Requirements

### Requirement: Monitor loop poll interval
The orchestrator monitor loop SHALL poll active changes every 15 seconds.

#### Scenario: Poll interval timing
- **WHEN** the monitor loop is running
- **THEN** it SHALL sleep for 15 seconds between poll cycles
- **AND** the constant `POLL_INTERVAL` SHALL be set to 15

### Requirement: Dispatch creates proposal.md
The orchestrator SHALL pre-create `proposal.md` (not `brief-context.md`) in the change directory during dispatch, providing Ralph with structured scope context.

#### Scenario: Proposal pre-creation on dispatch
- **WHEN** `dispatch_change()` creates a new change in a worktree
- **AND** no `proposal.md` exists yet
- **THEN** the orchestrator SHALL create `openspec/changes/{name}/proposal.md` with:
  - `## Why` section containing the roadmap item
  - `## What Changes` section containing the scope text
  - `## Capabilities` section with the change name
  - `## Impact` section (placeholder)
- **AND** if dispatch memories are available, append a `## Context from Memory` section (max 1000 chars)

### Requirement: State initialization with integer verify retry count
The `init_state()` function SHALL initialize `verify_retry_count` as an integer (0), not a boolean.

#### Scenario: New state initialization
- **WHEN** `init_state()` creates the orchestration state from a plan
- **THEN** each change object SHALL include `verify_retry_count: 0` (integer)
- **AND** SHALL NOT include `verify_retried` (boolean)

### Requirement: Stalled change cooldown resume
The monitor loop SHALL automatically resume stalled changes after a 5-minute cooldown period.

#### Scenario: Stalled change resume after cooldown
- **WHEN** a change has status `stalled`
- **AND** at least 300 seconds have elapsed since `stalled_at`
- **THEN** the orchestrator SHALL call `resume_change()` for that change

#### Scenario: Stalled change within cooldown
- **WHEN** a change has status `stalled`
- **AND** less than 300 seconds have elapsed since `stalled_at`
- **THEN** the orchestrator SHALL skip the change (wait for cooldown)

### Requirement: Failed build retry in monitor loop
The monitor loop SHALL attempt lightweight retries for changes that failed build verification before triggering a full replan cycle.

#### Scenario: Build failure retry
- **WHEN** a change has status `failed` and `build_result: "fail"`
- **AND** `gate_retry_count` is less than `max_verify_retries`
- **THEN** the orchestrator SHALL increment `gate_retry_count`
- **AND** set `retry_context` with the build error output
- **AND** set status to `pending` and call `resume_change()`

#### Scenario: Build failure retry exhausted
- **WHEN** a change has status `failed` and `build_result: "fail"`
- **AND** `gate_retry_count` >= `max_verify_retries`
- **THEN** the orchestrator SHALL skip the change (remain in `failed`)

### Requirement: Auto-detect test command (DEFERRED — not wired)
The function `auto_detect_test_command()` exists but is NOT currently called. It is dead code from the original VG-3 spec. Wiring it in would change behavior for projects that previously had no test gate, potentially breaking stable orchestration runs. A future change should introduce this as an opt-in directive (e.g., `auto_detect_tests: true`).

#### Scenario: Current behavior — no auto-detection
- **WHEN** no `test_command` is set via CLI, config file, or in-document directives
- **THEN** the verify gate SHALL skip test execution entirely
- **AND** `auto_detect_test_command()` SHALL NOT be called
