## ADDED Requirements

### Requirement: Post-merge scope verification
After a successful merge, the orchestrator SHALL verify that the change's implementation files actually landed in the merge diff, not just metadata/artifact files.

#### Scenario: Implementation files present in diff
- **WHEN** a change is merged to main
- **AND** the merge diff contains modifications to files listed in the change's task scope (from `tasks.md`)
- **THEN** scope verification SHALL pass
- **AND** the orchestrator SHALL log "Post-merge: scope verification passed for {change_name}"

#### Scenario: Only artifact files in diff
- **WHEN** a change is merged to main
- **AND** the merge diff contains ONLY openspec artifact files (files under `openspec/changes/`)
- **AND** no implementation source files are present in the diff
- **THEN** scope verification SHALL fail
- **AND** the orchestrator SHALL log an error "Post-merge: scope verification FAILED — only artifact files merged, no implementation"
- **AND** SHALL send a critical notification

#### Scenario: Scope file not found
- **WHEN** a change is merged to main
- **AND** no `tasks.md` exists for the change (in the worktree or openspec/changes/)
- **THEN** scope verification SHALL be skipped with a warning
- **AND** the merge SHALL NOT be reverted

### Requirement: Scope extraction from tasks
The orchestrator SHALL extract expected implementation file paths from the change's task artifacts.

#### Scenario: Tasks file has file references
- **WHEN** `tasks.md` contains file paths in task descriptions (e.g., `src/lib/email/smtp.ts`)
- **THEN** the orchestrator SHALL extract these as the expected scope
- **AND** compare against `git diff --name-only HEAD~1`

#### Scenario: Fallback to non-artifact diff check
- **WHEN** file paths cannot be extracted from tasks.md
- **THEN** the orchestrator SHALL fall back to checking that at least one non-openspec file was modified in the merge diff
