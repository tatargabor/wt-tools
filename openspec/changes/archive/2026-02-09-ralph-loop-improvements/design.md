## Context

The Ralph loop (`bin/wt-loop`) runs Claude Code iteratively in a spawned terminal. State is tracked in `.claude/loop-state.json`. The GUI displays loop status via the "R" button in the extra column. Current defaults: `done_criteria=manual`, `stall_threshold=1`. Token tracking uses `wt-usage --since` which returns 0 in practice. The loop was designed for short runs but is now used for multi-hour autonomous sessions — exposing reliability gaps.

Key code locations:
- `bin/wt-loop` lines 333-570: main loop (`cmd_run`)
- `bin/wt-loop` line 12: `DEFAULT_DONE_CRITERIA="manual"`
- `bin/wt-loop` line 14: `DEFAULT_STALL_THRESHOLD=1`
- `gui/control_center/mixins/menus.py` lines 391-457: Start Loop dialog
- `gui/control_center/mixins/table.py` lines 293-329, 426-472: loop status display

## Goals / Non-Goals

**Goals:**
- Loop stops automatically when all tasks are done (default behavior)
- Long-running stuck iterations are detected and terminated
- Token tracking works reliably
- State is always complete even on crashes/stops
- GUI provides better loop management UX
- Terminal shows progress at a glance

**Non-Goals:**
- Changing the core loop architecture (iterate → claude → check → repeat)
- Adding parallel iteration support
- Changing how Claude Code is invoked (`--dangerously-skip-permissions -p`)
- Adding web dashboard for loop monitoring

## Decisions

### Decision 1: Default done_criteria = "tasks"

**Choice:** Change `DEFAULT_DONE_CRITERIA` from `"manual"` to `"tasks"`. When `tasks` is selected and no `tasks.md` exists, fall back to `manual` with a warning.

**Rationale:** Every real-world loop run targets a tasks.md. The `manual` default is a footgun — users forget to set `--done tasks` and the loop runs forever. The `/wt:loop` skill already passes `--done tasks`, but GUI-started and CLI-started loops use the default.

**Alternative considered:** Auto-detect tasks.md presence at start. Rejected — simpler to just change the default and let users explicitly opt into manual when needed.

### Decision 2: Two-tier stall detection

**Choice:**
1. **Time-based (within iteration):** If current iteration exceeds `ITERATION_TIMEOUT` (default 45 min), kill the claude process, record partial iteration, continue to next iteration with fresh context.
2. **Commit-based (across iterations):** If `stall_threshold` consecutive iterations produce no commits, stop loop as "stalled". Change default from 1 to 2.

**Implementation:**
- Track iteration start time. In a background subshell or via periodic check, compare elapsed time against timeout.
- Use `timeout` command wrapper around claude invocation: `timeout --signal=TERM $ITERATION_TIMEOUT claude ...`
- On timeout, record iteration with `"timed_out": true` flag.

**Rationale:** The current stall detection only works between iterations. A stuck iteration (context limit loop, infinite tool retries) runs forever. The `timeout` command is the simplest cross-platform solution.

**Alternative considered:** Monitor session file mtime in background loop. Rejected — adds complexity, `timeout` is simpler and sufficient.

### Decision 3: Signal trap for state recording

**Choice:** Add `trap` handlers for SIGTERM, SIGINT, EXIT in `cmd_run()`. On trap:
1. Record current iteration's `ended` timestamp
2. Update status to "stopped"
3. Write any detected commits
4. Flush log

**Implementation:**
```bash
trap 'cleanup_on_exit' EXIT SIGTERM SIGINT
cleanup_on_exit() {
    if [[ -n "$current_iter_started" ]]; then
        add_iteration ... "ended=$(date -Iseconds)" ...
    fi
    update_loop_state "$state_file" "status" '"stopped"'
}
```

**Rationale:** Currently if the loop is killed mid-iteration, that iteration's data is lost. The trap ensures state is always consistent.

### Decision 4: Token tracking fix

**Choice:** Investigate `wt-usage --since` failure. The likely issue is that `--since` timestamp format doesn't match session file timestamps, or the session file paths don't match. Fix the root cause. Add stderr logging when token extraction returns 0 for debugging.

**Fallback:** If `wt-usage` returns 0, estimate tokens from session file size growth (rough heuristic: ~4 tokens per byte of JSONL).

### Decision 5: GUI Start Loop dialog improvements

**Choice:**
- Default done criteria combo to "tasks" (matching new default)
- If user selects "manual", show inline warning: "Loop won't auto-stop. Use 'Stop Loop' to end."
- Add read-only "tasks.md found: yes/no" indicator
- Add stall threshold spinner (default 2, range 1-10)

**Rationale:** The dialog should guide users toward the right defaults. Most users want task-based completion.

### Decision 6: Terminal title with iteration progress

**Choice:** Update terminal title during loop execution using ANSI escape: `printf '\033]0;Ralph: %s [%d/%d]\007' "$change_id" "$iteration" "$max_iter"`

**Rationale:** When multiple Ralph loops run simultaneously, terminal titles are the only way to identify which is which at a glance. Current title is static: "Ralph: change-id".

### Decision 7: Stall threshold configurable

**Choice:** Add `--stall-threshold N` CLI flag, default 2. Store in loop-state.json. GUI dialog gets a spinner for it.

**Rationale:** Current hardcoded threshold of 1 is too aggressive — some iterations legitimately produce no commits (e.g., running tests, reading code). 2 gives one "thinking" iteration before declaring stall.

## Risks / Trade-offs

- **[timeout kills mid-work]** → SIGTERM allows claude to save state. The next iteration starts fresh, which is the desired recovery behavior for context-limit situations.
- **[Default change breaks existing scripts]** → Scripts using `--done manual` explicitly are unaffected. Only scripts relying on the default change. Low risk since most usage is interactive.
- **[Token estimation inaccurate]** → The session file size heuristic is approximate. Labeled as "~estimated" in output. Better than showing 0.
- **[Signal trap race condition]** → `trap` and `add_iteration` both write to state file. Mitigated by atomic write pattern already in place (temp file + mv).
