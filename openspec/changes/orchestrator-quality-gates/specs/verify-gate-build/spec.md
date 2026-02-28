## ADDED Requirements

### Requirement: Build verification before merge
The verify gate SHALL detect the project's build command from `package.json` scripts (`build:ci` or `build`) and execute it before allowing merge.

#### Scenario: Build passes
- **WHEN** the worktree has `package.json` with a `build` script and the build succeeds
- **THEN** `build_result` is set to `"pass"` in state and the gate continues to merge

#### Scenario: Build fails with retries remaining
- **WHEN** the build fails and `verify_retry_count < max_verify_retries`
- **THEN** the agent is resumed with build error context (last 2000 chars of output)
- **AND** `verify_retry_count` is incremented

#### Scenario: Build fails permanently
- **WHEN** the build fails and all retries are exhausted
- **THEN** the change status is set to `"failed"`
- **AND** a critical notification is sent

#### Scenario: No build command detected
- **WHEN** the worktree has no `package.json` or no `build`/`build:ci` script
- **THEN** the build step is skipped entirely
