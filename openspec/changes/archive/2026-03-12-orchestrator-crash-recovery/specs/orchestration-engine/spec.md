## ADDED Requirements

### Requirement: Orphaned running change recovery on startup
The orchestrator SHALL detect and recover changes that were left in "running" status after a crash, when their worktree no longer exists and their Ralph process is dead.

#### Scenario: Orphaned change detected and recovered
- **WHEN** `cmd_start()` resumes from a crashed state
- **AND** a change has status "running" (or "verifying" or "stalled")
- **AND** the change's `worktree_path` does not exist on disk (or is null/empty)
- **AND** the change's `ralph_pid` is dead (`kill -0` fails) or is null/0
- **THEN** the orchestrator SHALL reset the change to status "pending" with worktree_path=null, ralph_pid=null, verify_retry_count=0
- **AND** emit a `CHANGE_RECOVERED` event with the change name

#### Scenario: Live process prevents recovery
- **WHEN** a change has status "running"
- **AND** the change's `ralph_pid` is still alive (`kill -0` succeeds)
- **THEN** the orchestrator SHALL NOT reset the change
- **AND** SHALL log a warning: "Change {name} has live process PID {pid}, skipping recovery"

#### Scenario: Existing worktree prevents recovery
- **WHEN** a change has status "running"
- **AND** the change's `worktree_path` exists on disk
- **THEN** the orchestrator SHALL NOT reset the change (existing resume logic handles it)

#### Scenario: Multiple orphaned changes recovered
- **WHEN** multiple changes are orphaned after a crash
- **THEN** the orchestrator SHALL recover ALL of them in a single pass
- **AND** log the total count: "Recovered {N} orphaned changes"

#### Scenario: Recovery runs before dispatch
- **WHEN** `cmd_start()` enters the resume path
- **THEN** `recover_orphaned_changes()` SHALL run BEFORE `resume_stopped_changes()` and `dispatch_ready_changes()`
