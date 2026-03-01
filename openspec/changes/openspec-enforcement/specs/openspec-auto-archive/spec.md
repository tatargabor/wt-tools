## ADDED Requirements

### Requirement: Auto-archive merged changes
After a successful merge in the orchestrator, the change directory SHALL be archived automatically.

#### Scenario: Successful merge triggers archive
- **WHEN** `merge_change()` completes successfully (status set to `merged`)
- **THEN** the orchestrator SHALL move `openspec/changes/<name>/` to `openspec/changes/archive/<YYYY-MM-DD>-<name>/`
- **AND** commit the move with message `chore: archive <name> change`

#### Scenario: Archive uses skip-specs
- **WHEN** auto-archiving a merged change
- **THEN** the orchestrator SHALL NOT attempt delta spec sync during archive
- **AND** the archive operation SHALL use `--skip-specs` semantics (filesystem move only)

#### Scenario: Archive failure is non-blocking
- **WHEN** the archive operation fails (e.g., directory already exists, git commit fails)
- **THEN** the orchestrator SHALL log a warning
- **AND** SHALL NOT revert the merge or change the merge status
- **AND** orchestration SHALL continue normally

#### Scenario: Change directory does not exist
- **WHEN** the change has no corresponding directory in `openspec/changes/`
- **THEN** the archive step SHALL be skipped silently (no warning)
