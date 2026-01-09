## 1. Default Done Criteria

- [x] 1.1 Change `DEFAULT_DONE_CRITERIA` from `"manual"` to `"tasks"` in `bin/wt-loop` (line 12).
- [x] 1.2 In `cmd_start()`, if done_criteria is "tasks" and no `tasks.md` exists in the worktree or change directory, fall back to "manual" with a warning message.
- [x] 1.3 Store `done_criteria` in `loop-state.json` at start.

## 2. Stall Threshold

- [x] 2.1 Change `DEFAULT_STALL_THRESHOLD` from 1 to 2 in `bin/wt-loop` (line 14).
- [x] 2.2 Add `--stall-threshold N` CLI flag to `cmd_start()`, passed through to state and `cmd_run()`.
- [x] 2.3 Store `stall_threshold` in `loop-state.json` at start. Read it back in `cmd_run()`.

## 3. Per-Iteration Timeout

- [x] 3.1 Add `--iteration-timeout N` CLI flag (minutes, default 45). Store as `iteration_timeout_min` in state.
- [x] 3.2 Wrap the claude invocation in `cmd_run()` with the `timeout` command: `timeout --signal=TERM ${timeout_seconds} claude ...`.
- [x] 3.3 Detect timeout exit code (124) and record iteration with `"timed_out": true`. Continue to next iteration.
- [x] 3.4 Log timeout event to stderr and ralph-loop.log.

## 4. Signal Trap for State Recording

- [x] 4.1 Add `trap 'cleanup_on_exit' EXIT SIGTERM SIGINT` at the start of `cmd_run()`.
- [x] 4.2 Implement `cleanup_on_exit()`: record current iteration's `ended` timestamp if iteration is active, detect commits, update status to "stopped", flush state file.
- [x] 4.3 Track `current_iter_started` variable so the trap knows if an iteration is in progress.
- [x] 4.4 Verify that double-trap (EXIT + SIGTERM) doesn't corrupt state by using a guard variable.

## 5. Token Tracking Fix

- [x] 5.1 Diagnose why `wt-usage --since` returns 0: run manually in a worktree with known activity and check output.
- [x] 5.2 Fix the root cause in `get_current_tokens()` or `wt-usage`.
- [x] 5.3 Add stderr warning in `get_current_tokens()` when result is 0 after a claude invocation.
- [x] 5.4 Add fallback: if tokens = 0 after claude ran, estimate from session file size growth (delta bytes / 4 as rough token estimate). Mark with `"tokens_estimated": true`.

## 6. Terminal Title Updates

- [x] 6.1 Add `update_terminal_title()` helper function using ANSI escape: `printf '\033]0;%s\007' "$title"`.
- [x] 6.2 Call at iteration start: `"Ralph: ${change_id} [${iteration}/${max_iter}]"`.
- [x] 6.3 Call on loop completion: `"Ralph: ${change_id} [${final_status}]"`.

## 7. GUI Start Loop Dialog

- [x] 7.1 In `menus.py` Start Loop dialog: default done criteria combo to "tasks" instead of "manual".
- [x] 7.2 Check if `tasks.md` exists for the worktree's change; if found, show "tasks.md: found" label. If not, show "tasks.md: not found" and default to "manual".
- [x] 7.3 When user selects "manual", show inline warning label: "Loop won't auto-stop".
- [x] 7.4 Add stall threshold spinner to the dialog (default 2, range 1-10).
- [x] 7.5 Add iteration timeout spinner to the dialog (default 45 min, range 5-120).
- [x] 7.6 Pass stall-threshold and iteration-timeout values to the `wt-loop start` command.

## 8. GUI Loop Status Display

- [x] 8.1 Update Ralph button tooltip in `table.py` to include: elapsed time since start, current iteration elapsed time, last commit timestamp.
- [x] 8.2 Add "stalled" status color (orange) distinct from "stuck" (red) in Ralph button rendering.
- [x] 8.3 Show iteration timeout and stall threshold in tooltip when available from state.

## 9. GUI Ralph Settings

- [x] 9.1 Add "Default stall threshold" spinner to Ralph settings tab (default 2, range 1-10).
- [x] 9.2 Add "Default iteration timeout (min)" spinner to Ralph settings tab (default 45, range 5-120).
- [x] 9.3 Wire new settings to Start Loop dialog defaults.

## 10. Tests

- [x] 10.1 Add test for Start Loop dialog: verify default done criteria is "tasks" when tasks.md exists.
- [x] 10.2 Add test for Start Loop dialog: verify "manual" warning label appears when manual selected.
- [x] 10.3 Add test for Ralph button tooltip: verify elapsed time and iteration details are shown.
- [x] 10.4 Add test for Ralph button colors: verify "stalled" gets orange, "stuck" gets red.
- [x] 10.5 Run full GUI test suite and fix any failures.

## 11. Integration Verification

- [x] 11.1 Start a loop with default settings (no `--done` flag), verify it uses "tasks" criteria and stops when tasks.md is fully checked.
- [x] 11.2 Verify iteration timeout works: start a loop, simulate a long iteration, confirm timeout fires and next iteration starts.
- [x] 11.3 Verify signal trap: kill a running loop with SIGTERM, check that state file has proper `ended` timestamp and "stopped" status.

## 12. CWD Auto-Detect for change-id

- [x] 12.1 Make change-id optional in `wt-loop start`: if not provided, detect from CWD using `resolve_project()` and worktree path → change-id extraction (strip project prefix from basename, or read branch `change/xxx`).
- [x] 12.2 Make change-id optional in `wt-loop stop`, `wt-loop status`, `wt-loop history`, `wt-loop monitor`: auto-detect from CWD.
- [x] 12.3 Update usage text to show change-id as `[change-id]` (optional) in all subcommands.
- [x] 12.4 If CWD is not inside a worktree and no change-id given, show clear error: "Not inside a worktree. Provide change-id explicitly."

## 13. Fix check_done syntax error

- [x] 13.1 Investigate and fix the `syntax error in expression (error token is "0\n0")` in check_tasks_done() or check_done() — likely a grep output parsing issue where newlines leak into arithmetic expression. Ensure `count` variable is sanitized before `$((...))`.
- [x] 13.2 Test check_done with edge cases: empty tasks.md, tasks.md with only completed tasks, multiple tasks.md files.
