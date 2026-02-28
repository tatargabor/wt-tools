### Requirement: TUI launch
The orchestrator SHALL provide a terminal dashboard via `wt-orchestrate tui`.

#### Scenario: Launch with state file
- **WHEN** `wt-orchestrate tui` is invoked
- **AND** `orchestration-state.json` exists
- **THEN** the orchestrator SHALL launch a Textual-based Python TUI app
- **AND** pass the state file path and log file path as arguments

#### Scenario: Launch without state file
- **WHEN** `wt-orchestrate tui` is invoked
- **AND** no `orchestration-state.json` exists
- **THEN** the orchestrator SHALL exit with: "No orchestration state found."

#### Scenario: Textual dependency check
- **WHEN** launching the TUI
- **THEN** the orchestrator SHALL verify the `textual` Python package is importable
- **AND** try conda python as fallback if system python lacks textual
- **AND** exit with install instructions if textual is not available

### Requirement: Header status display
The TUI SHALL display orchestrator status in a header bar.

#### Scenario: Running state header
- **WHEN** the orchestrator status is `running`
- **THEN** the header SHALL show: status indicator, plan version (with replan cycle if >0), progress ratio (merged+done/total), cumulative tokens, active time / time limit with remaining

#### Scenario: Checkpoint state header
- **WHEN** the orchestrator status is `checkpoint`
- **THEN** the header SHALL display a highlighted/blinking checkpoint indicator

#### Scenario: Time limit exceeded header
- **WHEN** the orchestrator status is `time_limit`
- **THEN** the header SHALL display a yellow time limit indicator

### Requirement: Change table display
The TUI SHALL display a table of all changes with their status and metrics.

#### Scenario: Table columns
- **WHEN** rendering the change table
- **THEN** columns SHALL include: Name (25 chars), Status (colored), Iteration (from loop-state.json), Tokens, Gates (T/B/R/V indicators)

#### Scenario: Status coloring
- **WHEN** rendering change status
- **THEN** colors SHALL be: green=running, blue=done, bright_green=merged, red=failed, yellow=pending/dispatched

#### Scenario: Gate display
- **WHEN** all gates passed
- **THEN** display "T✓ B✓ R✓ V✓" in green
- **WHEN** a gate failed
- **THEN** display the failed gate with ✗ in red, omit subsequent gates

### Requirement: Live log tail
The TUI SHALL display the orchestration log with auto-scroll.

#### Scenario: Log display
- **WHEN** `.claude/orchestration.log` exists
- **THEN** the TUI SHALL display the last ~200 lines with color by level: INFO=default, WARN=yellow, ERROR=red
- **AND** update within 3-5 seconds

#### Scenario: Missing log
- **WHEN** the log file does not exist
- **THEN** the TUI SHALL display "No log file yet" dimmed

### Requirement: Checkpoint approval via TUI
The TUI SHALL allow approving checkpoints via keyboard shortcut.

#### Scenario: Approve checkpoint
- **WHEN** the user presses `a` during a checkpoint
- **THEN** the TUI SHALL atomically write approval to orchestration-state.json (temp file + rename)
- **AND** set `checkpoints[-1].approved = true` and `approved_at` timestamp

#### Scenario: Approve outside checkpoint
- **WHEN** the user presses `a` and status is NOT `checkpoint`
- **THEN** the keypress SHALL be ignored

### Requirement: Auto-refresh
The TUI SHALL automatically refresh data from state and log files.

#### Scenario: Periodic refresh
- **WHEN** the TUI is running
- **THEN** it SHALL re-read state + log every 3 seconds without flicker

#### Scenario: Manual refresh
- **WHEN** the user presses `r`
- **THEN** the TUI SHALL immediately refresh all data

### Requirement: Keyboard navigation
The TUI SHALL support keyboard shortcuts for common actions.

#### Scenario: Keyboard bindings
- **WHEN** the TUI is running
- **THEN** the following keys SHALL be active:
  - `q`: quit the TUI
  - `a`: approve checkpoint
  - `r`: force refresh
  - `l`: toggle between split view (table+log) and full log view
- **AND** a footer bar SHALL display the available keybindings
