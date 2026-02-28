## ADDED Requirements

### Requirement: Verify gate step order
The verify gate SHALL execute quality checks in a fixed order, with fail-fast semantics to avoid wasting resources on code that fails earlier gates.

#### Scenario: Full gate pipeline execution order
- **WHEN** a change completes (Ralph done)
- **THEN** the verify gate SHALL execute in this order:
  1. **Test execution** — run `test_command` if configured. Fail → retry agent with test output
  2. **Build verification** — run `build` or `build:ci` from package.json. Fail → retry agent with build output
  3. **Test file existence check** — check if diff contains `.test.` or `.spec.` files. Missing → WARNING notification only (non-blocking)
  4. **LLM code review** — if `review_before_merge: true`, run Sonnet review. CRITICAL → retry agent with review feedback
  5. **OpenSpec verify** — run `/opsx:verify {change_name}`. Fail → retry agent with verify output

#### Scenario: Build failure skips review and verify
- **WHEN** build verification fails
- **THEN** the gate SHALL NOT proceed to LLM review or OpenSpec verify
- **AND** SHALL retry the agent with build error context (saving LLM tokens)

#### Scenario: Test failure skips all subsequent gates
- **WHEN** test execution fails
- **THEN** the gate SHALL NOT proceed to build, review, or verify
- **AND** SHALL retry the agent with test failure context

### Requirement: Base build health check before agent retry
When a worktree build fails, the orchestrator SHALL check if the main branch also fails before blaming the agent.

#### Scenario: Main branch also broken
- **WHEN** worktree build fails
- **AND** main branch build also fails
- **THEN** the orchestrator SHALL attempt `fix_base_build_with_llm()` on main
- **AND** if main is fixed, sync the worktree and re-run build without consuming a retry

#### Scenario: Main branch builds OK
- **WHEN** worktree build fails
- **AND** main branch builds successfully
- **THEN** the orchestrator SHALL sync the worktree with latest main
- **AND** re-run the build to see if inherited fixes resolve it
- **AND** if still failing, attribute to agent code and proceed with normal retry

### Requirement: Merge-rebase fast path in verify gate
Changes returning from agent-assisted merge rebase SHALL skip the full verify gate.

#### Scenario: Merge rebase pending flag
- **WHEN** `handle_change_done()` detects `merge_rebase_pending = true`
- **THEN** it SHALL clear the flag
- **AND** skip test/build/review/verify gates
- **AND** perform a dry-run merge test directly
- **AND** proceed to merge or enter merge-blocked queue
