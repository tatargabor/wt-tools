## MODIFIED Requirements

### Requirement: Post-merge build verification
After a successful merge to main, the orchestrator SHALL verify that the main branch still builds correctly.

#### Scenario: Build verification after merge
- **WHEN** `merge_change()` succeeds via `wt-merge`
- **AND** a test_command or build script exists
- **THEN** the orchestrator SHALL run the build command on the main worktree
- **AND** log the result (pass/fail)

#### Scenario: Post-merge build failure with auto-fix
- **WHEN** post-merge build verification fails
- **THEN** the orchestrator SHALL attempt automatic build fix via `fix_base_build_with_llm`
- **AND** if auto-fix fails, send a critical notification: "Post-merge build broken after {change_name} merge! Auto-fix failed."
- **AND** save a Decision memory: "Post-merge build failed after merging {change_name}"
- **AND** the merge SHALL NOT be reverted (manual intervention required)

#### Scenario: Post-merge build success
- **WHEN** post-merge build verification passes
- **THEN** the orchestrator SHALL log "Post-merge: build passed on main"

## ADDED Requirements

### Requirement: Post-merge pipeline ordering
The post-merge pipeline steps SHALL execute in a defined order after a successful merge.

#### Scenario: Full post-merge pipeline execution
- **WHEN** `merge_change()` succeeds
- **THEN** the pipeline steps SHALL execute in this order:
  1. Base build cache invalidation
  2. Dependency install (if package.json changed)
  3. Custom post-merge command (if `post_merge_command` directive is set)
  4. Scope verification (check implementation files landed)
  5. Build verification (if test_command exists)
  6. Memory logging
  7. Worktree cleanup
  8. Change archive
  9. Deploy smoke test (if configured)
