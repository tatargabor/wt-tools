### Requirement: Post-merge build verification
After a successful merge to main, the orchestrator SHALL verify that the main branch still builds correctly.

#### Scenario: Build verification after merge
- **WHEN** `merge_change()` succeeds via `wt-merge`
- **AND** a test_command or build script exists
- **THEN** the orchestrator SHALL run the build command on the main worktree
- **AND** log the result (pass/fail)

#### Scenario: Post-merge build failure
- **WHEN** post-merge build verification fails
- **THEN** the orchestrator SHALL send a critical notification: "Post-merge build broken after {change_name} merge! Manual fix needed."
- **AND** save a Decision memory: "Post-merge build failed after merging {change_name}"
- **AND** the merge SHALL NOT be reverted (manual intervention required)

#### Scenario: Post-merge build success
- **WHEN** post-merge build verification passes
- **THEN** the orchestrator SHALL log "Post-merge: build passed on main"

### Requirement: Post-merge dependency install
After a successful merge, the orchestrator SHALL install dependencies if package.json changed.

#### Scenario: Package.json changed in merge
- **WHEN** `merge_change()` succeeds
- **AND** `git diff HEAD~1 --name-only` includes `package.json`
- **THEN** the orchestrator SHALL detect the package manager (pnpm/yarn/npm via lockfile)
- **AND** run the appropriate install command
- **AND** log success or failure (non-blocking)

#### Scenario: Package.json unchanged
- **WHEN** `merge_change()` succeeds
- **AND** package.json was not modified
- **THEN** no dependency install SHALL be triggered

### Requirement: Base build cache invalidation
The orchestrator SHALL invalidate the cached base build status after each successful merge, since main has changed.

#### Scenario: Cache invalidated on merge
- **WHEN** `merge_change()` succeeds
- **THEN** `BASE_BUILD_STATUS` and `BASE_BUILD_OUTPUT` SHALL be set to empty strings
- **AND** the next build verification SHALL run a fresh check
## Requirements
### Requirement: Post-merge build verification
After a successful merge to main, the orchestrator SHALL verify that the main branch still builds correctly.

#### Scenario: Build verification after merge
- **WHEN** `merge_change()` succeeds via `wt-merge`
- **AND** a test_command or build script exists
- **THEN** the orchestrator SHALL run the build command on the main worktree
- **AND** log the result (pass/fail)

#### Scenario: Post-merge build failure
- **WHEN** post-merge build verification fails
- **THEN** the orchestrator SHALL send a critical notification: "Post-merge build broken after {change_name} merge! Manual fix needed."
- **AND** save a Decision memory: "Post-merge build failed after merging {change_name}"
- **AND** the merge SHALL NOT be reverted (manual intervention required)

#### Scenario: Post-merge build success
- **WHEN** post-merge build verification passes
- **THEN** the orchestrator SHALL log "Post-merge: build passed on main"

### Requirement: Post-merge dependency install
After a successful merge, the orchestrator SHALL install dependencies if package.json changed.

#### Scenario: Package.json changed in merge
- **WHEN** `merge_change()` succeeds
- **AND** `git diff HEAD~1 --name-only` includes `package.json`
- **THEN** the orchestrator SHALL detect the package manager (pnpm/yarn/npm via lockfile)
- **AND** run the appropriate install command
- **AND** log success or failure (non-blocking)

#### Scenario: Package.json unchanged
- **WHEN** `merge_change()` succeeds
- **AND** package.json was not modified
- **THEN** no dependency install SHALL be triggered

### Requirement: Base build cache invalidation
The orchestrator SHALL invalidate the cached base build status after each successful merge, since main has changed.

#### Scenario: Cache invalidated on merge
- **WHEN** `merge_change()` succeeds
- **THEN** `BASE_BUILD_STATUS` and `BASE_BUILD_OUTPUT` SHALL be set to empty strings
- **AND** the next build verification SHALL run a fresh check

