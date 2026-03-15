## Why

The review retry mechanism is **architecturally broken**: when the review gate detects critical issues and triggers a retry, the agent loop is started with `done_criteria = "test"` — but **`is_done()` has no implementation for the "test" criteria**. This means the agent applies the security fix, commits it, but the loop never signals completion. After `max_iter` iterations, the change is marked "failed" even though the fix was correctly applied.

This is the direct cause of agents "failing to fix security issues" in E2E run #13. The review gate correctly catches IDOR and missing auth middleware. The retry prompt correctly tells the agent what to fix (with FILE:LINE:FIX format). The agent applies the fix. But the **orchestration loop can never exit successfully**.

### Evidence from E2E run #13

| Change | Review finding | Agent action | Result | Real cause |
|--------|---------------|--------------|--------|------------|
| cart-feature | IDOR on removeFromCart/updateCartQuantity | Applied fix (partial) | FAILED after 2 retries | is_done("test") always returns False |
| admin-auth | Missing middleware.ts for /admin redirect | Created middleware (partial) | FAILED after 2 retries | is_done("test") always returns False |

### Root cause trace

```
verifier.py:1405-1449  → review finds CRITICAL → sets retry_context
dispatcher.py:1207-1221 → resume_change() sets done_criteria = "test"
wt-loop start ... --done test
loop_tasks.py:155-186   → is_done() switch:
                           "tasks" → check_completion()  ✓
                           "openspec" → detect_next_change_action()  ✓
                           "manual" → manual_done flag  ✓
                           "build" → _check_build_done()  ✓
                           "merge" → _check_merge_done()  ✓
                           "test" → ??? → return False  ← BUG
```

### Bug #20 connection

Bug #20 fix (131d7d0ec) changed `done_criteria` from `"build"` to `"test"` to prevent empty changes from passing verification. But the "test" implementation was never added to `is_done()`. The fix solved one problem (empty builds passing) but introduced another (retry loops never completing).

### Modular architecture context (post-`planning-quality-profiles`)

- **Test command detection**: `profile.detect_test_command()` is now the primary source (via `config.auto_detect_test_command()` which tries profile first, then legacy). Use `config.auto_detect_test_command()` for test command resolution, not inline PM detection.
- **Security rules for retry context**: `verifier._load_security_rules()` now uses `profile.security_rules_paths()` with legacy fallback. No changes needed here.
- All implementation stays in **wt-tools** — no wt-project-web/base changes needed.

### Current code locations

- `lib/wt_orch/loop_tasks.py:155-186` — `is_done()` missing "test" case
- `lib/wt_orch/dispatcher.py:1207-1221` — sets `done_criteria = "test"` for retries
- `lib/wt_orch/verifier.py:1405-1449` — review retry trigger with `_extract_review_fixes()`
- `lib/wt_orch/verifier.py:87-133` — `_extract_review_fixes()` parsing
- `lib/wt_orch/verifier.py:136-174` — `_load_security_rules()` (profile-aware, with legacy fallback)

## What Changes

### 1. Implement `is_done("test")` in loop_tasks.py
- Add "test" case to `is_done()` that runs the project's test command
- Test command source: `directives.test_command` from orchestration state, or auto-detected via `config.auto_detect_test_command()` (which uses `profile.detect_test_command()` first, then legacy fallback)
- Returns True if tests pass (exit code 0), False otherwise
- Must handle: test command not configured (fall back to build check)

### 2. Pass Test Command to Loop
- `resume_change()` must pass the test command to `wt-loop start` via a new flag or environment variable
- Loop state (`loop-state.json`) stores the test command for `is_done()` to read
- Alternative: `is_done()` reads orchestration state directly (simpler but couples loop to orchestrator)

### 3. Review Retry Timeout
- Review retries currently use `max_iter = 5` (dispatcher.py:1212)
- Add `max_review_retries` directive (default: 3) — separate from `max_verify_retries` which controls how many times verification triggers, not how many loop iterations the agent gets
- If agent hasn't fixed the issue after `max_review_retries` iterations in the loop, exit with clear failure message

### 4. Retry Completion Signal
- When `is_done("test")` returns True (tests pass), the loop exits cleanly
- Change returns to verification pipeline for re-review
- If re-review passes → merge; if re-review finds new issues → another retry cycle (up to `max_verify_retries`)

## Capabilities

### New Capabilities
- `test-done-criteria`: `is_done("test")` runs test command and returns pass/fail
- `review-retry-timeout`: Configurable max iterations for review retry loops

### Modified Capabilities
- `retry-loop-completion`: Loop can now exit successfully when tests pass during review retry
- `change-resume`: Passes test command to loop for done criteria evaluation

## Impact

- **Modified**: `lib/wt_orch/loop_tasks.py` — add "test" case to `is_done()`
- **Modified**: `lib/wt_orch/dispatcher.py` — pass test command to loop on resume
- **Modified**: `lib/wt_orch/loop_state.py` — store test_command in loop state
- **New directive**: `max_review_retries` (default: 3)
- **Critical fix**: Review retry loops can now complete successfully, making the review gate actually usable
- **No breaking changes**: New done criteria is only used when explicitly set by retry logic
- **Expected impact**: Run #14 should see review-failed changes self-heal without sentinel intervention
