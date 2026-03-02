## Context

The orchestrator's post-merge pipeline has three gaps exposed by production use: (1) no hook point for project-specific commands between dep install and build, (2) no validation that implementation code actually landed in a merge (only artifacts may have been committed), (3) sentinel overstepping its supervisor role by modifying quality gate configs.

The `post_merge_command` directive and directives persistence fix are already implemented in code but need spec coverage and testing. The scope verification and sentinel hardening are new work.

## Goals / Non-Goals

**Goals:**
- Add `post_merge_command` directive with full 4-level precedence parsing and state persistence
- Add scope verification to detect "merged but no implementation" scenarios
- Codify sentinel role boundary in both the guide and spec
- Ensure all three fixes work together in the post-merge pipeline

**Non-Goals:**
- Automatic rollback of bad merges (too risky for automated tooling)
- Changing the verify gate behavior in worktrees (scope-verify is post-merge on main only)
- Adding new sentinel capabilities (only constraining existing ones)

## Decisions

1. **Directives in state.json, not positional args**: The merge function already takes 12 positional parameters. Rather than adding more, we persist the entire directives object in `orchestration-state.json` under `.directives`. Post-merge functions read from state via jq. This is already the pattern used by the existing `test_command` read at line 4340.

2. **Scope verification uses diff, not task file parsing**: Instead of complex extraction of file paths from tasks.md, the primary check is: "does the merge diff contain at least one file outside `openspec/changes/`?" This catches the exact failure mode (only artifacts merged) without brittle path parsing. The tasks.md-based extraction is a secondary enhancement.

3. **Scope verify is non-blocking**: A scope verification failure logs an error and sends a notification but does NOT revert the merge or block the pipeline. The user decides what to do. This matches the existing post-merge build failure behavior.

4. **Sentinel guide is the authoritative source**: The sentinel is an LLM skill (not bash code), so the `.claude/commands/wt/sentinel.md` guide is the implementation. The spec defines the contract; the guide provides the detailed instructions the LLM follows.

5. **post_merge_command failure is non-blocking**: Like dependency install failures, a custom command failure logs a warning but does not halt the pipeline. The subsequent build verification will catch any actual breakage.

## Risks / Trade-offs

- **False positives on scope verify**: A change that legitimately only modifies openspec files (e.g., documentation-only changes) would trigger a scope failure warning. Mitigation: the warning is non-blocking, and purely-documentation changes are rare in orchestrated runs.
- **Custom command security**: `post_merge_command` runs arbitrary bash in the project directory. Mitigation: it comes from `.claude/orchestration.yaml` which is user-controlled, and has a 300s timeout.
- **State.json size increase**: Adding the full directives object (~500 bytes JSON) to state is negligible.
