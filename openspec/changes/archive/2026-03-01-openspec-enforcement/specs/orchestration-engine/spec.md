## ADDED Requirements

### Requirement: Pre-dispatch artifact validation
The orchestrator SHALL check for OpenSpec artifact completeness before dispatching an agent.

#### Scenario: Change has no tasks.md
- **WHEN** `dispatch_change()` is about to start a Ralph loop
- **AND** `openspec/changes/<name>/tasks.md` does not exist in the worktree
- **THEN** the orchestrator SHALL log that the first iteration will create artifacts
- **AND** the Ralph loop SHALL naturally detect the missing tasks.md and run `/opsx:ff`

#### Scenario: Change has tasks.md
- **WHEN** `dispatch_change()` is about to start a Ralph loop
- **AND** `openspec/changes/<name>/tasks.md` exists in the worktree
- **THEN** the orchestrator SHALL log that artifacts are ready for implementation

### Requirement: Stale change detection at startup
The orchestrator SHALL warn about orphan change directories at startup.

#### Scenario: Orphan change detected
- **WHEN** `cmd_start()` initializes
- **AND** a directory exists in `openspec/changes/` (excluding `archive/`)
- **AND** the directory name is not in the current plan's change list
- **AND** no active worktree exists for that change name
- **THEN** the orchestrator SHALL emit a `log_warn` with the orphan change name

#### Scenario: All changes accounted for
- **WHEN** every directory in `openspec/changes/` matches a plan change or has an active worktree
- **THEN** no warning SHALL be emitted

#### Scenario: Scan excludes archive and metadata
- **WHEN** scanning `openspec/changes/`
- **THEN** the scan SHALL exclude `archive/`, `.openspec.yaml`, and any hidden files/directories
