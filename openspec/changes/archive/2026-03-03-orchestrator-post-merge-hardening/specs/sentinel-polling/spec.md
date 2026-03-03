## MODIFIED Requirements

### Requirement: Sentinel poll loop SHALL use non-blocking background polls
The sentinel skill SHALL use single-shot background bash commands for polling instead of a long-running foreground while-loop.

#### Scenario: Normal polling cycle
- **WHEN** the sentinel starts monitoring an orchestrator
- **THEN** each poll cycle SHALL be a single bash command run with `run_in_background: true`
- **AND** the command SHALL sleep for 30 seconds, then read orchestration-state.json, then output a single EVENT line
- **AND** the LLM SHALL remain responsive to user input between polls

#### Scenario: Running state event
- **WHEN** the poll returns `EVENT:running`
- **THEN** the sentinel SHALL start the next background poll immediately
- **AND** SHALL NOT perform extended analysis or thinking

#### Scenario: Terminal state event
- **WHEN** the poll returns `EVENT:terminal`
- **THEN** the sentinel SHALL produce the completion report
- **AND** SHALL stop polling

#### Scenario: Process exit event
- **WHEN** the poll returns `EVENT:process_exit`
- **THEN** the sentinel SHALL read logs, diagnose the error, and decide whether to restart
- **AND** SHALL follow the existing crash recovery decision tree

#### Scenario: Checkpoint event
- **WHEN** the poll returns `EVENT:checkpoint`
- **THEN** the sentinel SHALL handle it according to the checkpoint reason (auto-approve periodic, ask user for others)

#### Scenario: Stale state event
- **WHEN** the poll returns `EVENT:stale`
- **THEN** the sentinel SHALL check PID liveness and log activity before deciding next action

## ADDED Requirements

### Requirement: Sentinel role boundary
The sentinel is a supervisor — it SHALL observe, diagnose, and restart, but MUST NOT modify project files or orchestration configuration.

#### Scenario: Transient failure recovery
- **WHEN** the orchestrator crashes due to a transient error (JSON parse, network, rate limit)
- **THEN** the sentinel SHALL restart the orchestrator after a cooldown period
- **AND** SHALL NOT modify any project files to work around the error

#### Scenario: Non-transient failure
- **WHEN** the orchestrator crashes due to an error that requires code changes, config modifications, or manual intervention
- **THEN** the sentinel SHALL stop monitoring
- **AND** SHALL report the error details and a suggested fix to the user
- **AND** SHALL NOT attempt to fix the problem itself

#### Scenario: Quality gate failures
- **WHEN** smoke tests, unit tests, or build verification fail persistently
- **THEN** the sentinel MUST NOT remove, disable, or weaken any quality gate directive (`smoke_command`, `test_command`, `merge_policy`, `review_before_merge`, `max_verify_retries`)
- **AND** SHALL report the failure pattern to the user

#### Scenario: Sentinel permitted actions
- **WHEN** the sentinel needs to take action
- **THEN** the following actions are permitted: restart orchestrator, reset stale state to "stopped", auto-approve periodic checkpoints, read logs and state files, produce reports
- **AND** the following actions are forbidden: modify `.claude/orchestration.yaml`, modify project source code, run build/generate/install commands, merge branches, create/delete worktrees, make architectural decisions
