## ADDED Requirements

### Requirement: Stall count reset on fresh activity
The orchestrator SHALL reset a change's `stall_count` when the Ralph loop shows fresh activity, not upon resume.

#### Scenario: Fresh loop-state mtime resets stall count
- **WHEN** `poll_change()` detects the change has status `running`
- **AND** `loop-state.json` mtime is within 300 seconds (5 minutes)
- **AND** the change has `stall_count > 0`
- **THEN** the orchestrator SHALL reset `stall_count` to 0
- **AND** log "Change {name} recovered — stall_count reset to 0"

#### Scenario: Resume does NOT reset stall count
- **WHEN** `resume_change()` restarts a Ralph loop
- **THEN** it SHALL NOT reset `stall_count`
- **AND** the stall_count SHALL only be reset by `poll_change()` observing fresh activity

### Requirement: Stale loop-state with live process
The orchestrator SHALL distinguish between a truly stalled agent and one in a long iteration.

#### Scenario: Stale mtime but process alive — skip stall handling
- **WHEN** `poll_change()` detects loop-state.json mtime > 300 seconds
- **AND** the terminal PID is still alive (`kill -0` succeeds)
- **THEN** the orchestrator SHALL log "loop-state stale but PID still alive — long iteration, skipping"
- **AND** SHALL NOT increment stall_count or attempt resume

#### Scenario: Stale mtime and process dead — trigger stall handling
- **WHEN** `poll_change()` detects loop-state.json mtime > 300 seconds
- **AND** the terminal PID is dead
- **THEN** the orchestrator SHALL increment stall_count
- **AND** if stall_count <= 3: set status to `stalled`, call `resume_change()`
- **AND** if stall_count > 3: set status to `failed`, send critical notification, save Learning memory
