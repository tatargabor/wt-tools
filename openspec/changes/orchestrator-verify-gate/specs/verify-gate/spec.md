# Verify Gate

Test execution and optional code review gate between Ralph completion and merge.

## Requirements

### VG-1: Test execution after Ralph completion
- When a change status becomes "done", run `test_command` in the change's worktree before proceeding to merge
- If `test_command` is empty/unset, skip test execution and proceed to merge
- Test execution runs in the worktree directory (`cd $wt_path && $test_command`)
- Capture both exit code and output (stdout+stderr)
- Timeout: 5 minutes (configurable via `test_timeout` directive, default 300s)

### VG-2: Test failure retry
- On test failure (non-zero exit), restart Ralph with context: "Tests failed. Fix these failures:\n<test output>"
- Set `verify_retried` flag on the change to prevent infinite retry loops
- Maximum 1 retry (configurable via `max_verify_retries` directive)
- If retry also fails, mark change as `verify-failed` status and send critical notification
- `verify-failed` changes do NOT block other changes or replan

### VG-3: test_command auto-detection
- If no explicit `test_command` is configured (CLI, yaml, or in-document directive), auto-detect:
  1. Read `package.json` in the project root
  2. Check `scripts` object for keys in order: `test`, `test:unit`, `test:ci`
  3. Use the first found as: `npm run <script-name>` (or `yarn`/`pnpm` based on lockfile)
  4. If no test script found, `test_command` remains empty (skip verify gate)
- Auto-detection runs once at orchestrator start, result logged
- Log message: "Auto-detected test command: <cmd>" or "No test command found, verify gate disabled"

### VG-4: Optional LLM code review before merge
- When `review_before_merge: true` directive is set, run an LLM code review after tests pass
- Review prompt includes: git diff of the change branch vs target, original change scope from plan
- Review model configurable via `review_model` directive (default: sonnet)
- Review output parsed for severity: if "CRITICAL" issues found → treat as test failure (retry Ralph)
- If no critical issues → proceed to merge
- Review is skipped if `review_before_merge` is false/unset (default)

### VG-5: Verify gate state tracking
- New change statuses: `verifying`, `verify-failed`
- State transitions: `done` → `verifying` → `merged` (pass) or `verify-failed` (fail after retries)
- `tokens_used` for review/fix charged to the change's token count
- Test results stored in change state: `test_result: "pass"|"fail"`, `test_output: "<truncated>"`
