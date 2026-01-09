## Why

Real-world Ralph loop usage exposed several reliability issues. A loop ran with `manual` done criteria (the default) instead of `tasks`, meaning it didn't stop when all 22 tasks were completed. Iteration 2 ran for 160 minutes producing nothing — likely hitting context limits with no stall detection. Token tracking showed 0 for all iterations. The iteration 2 commit was not recorded in state, and no `ended` timestamp was written when the loop stopped mid-iteration. These issues make the loop unreliable for unattended autonomous operation, which is its core use case.

## What Changes

- **Default done criteria**: Change from `manual` to `tasks` when a `tasks.md` exists in the change directory. Explicit `--done manual` required for manual mode.
- **Time-based stall detection**: If a single iteration exceeds 30 minutes with no commits, mark as stuck and stop. Current stall detection only counts consecutive commit-less iterations across boundaries, missing long-running stuck iterations.
- **Graceful iteration timeout**: Add per-iteration timeout (configurable, default 45 min). Kill claude process and record partial iteration if exceeded.
- **Token tracking fix**: Diagnose and fix why `wt-usage --since` returns 0 tokens. Add fallback token estimation from session file sizes if wt-usage fails.
- **Robust state recording**: Write iteration state incrementally (start record on begin, update on end). Trap signals to record `ended` timestamp on abnormal termination. Ensure commits detected mid-iteration are always recorded.
- **GUI Start Loop dialog improvements**: Default done criteria combo to "tasks" when tasks.md exists. Show warning if "manual" selected. Add estimated duration display based on max iterations.
- **GUI loop status improvements**: Show elapsed time per iteration. Distinguish "stuck" (time-based) from "stalled" (no-commit). Show last activity timestamp. Better tooltip with iteration progress details.
- **Terminal title updates**: Update terminal window title with current iteration number (`Ralph: change-id [3/10]`). Helps identify loop progress at a glance.
- **Configurable stall threshold**: Add `--stall-threshold N` flag (default 2 instead of current 1). Stalling after 1 commit-less iteration is too aggressive.

## Capabilities

### New Capabilities
- `loop-stall-recovery`: Time-based stall detection, per-iteration timeout, and graceful recovery when Claude hits context limits or hangs.

### Modified Capabilities
- `ralph-loop`: Change default done criteria to `tasks`, fix token tracking, robust state recording with signal traps, configurable stall threshold, terminal title updates.
- `control-center`: GUI Start Loop dialog defaults, loop status display improvements, elapsed time and activity indicators.

## Impact

- `bin/wt-loop`: Major changes to `cmd_run()`, `cmd_start()`, done criteria defaults, stall detection, signal handling, terminal title updates.
- `bin/wt-usage`: Investigate and fix token extraction for `--since` flag.
- `gui/control_center/mixins/menus.py`: Start Loop dialog improvements.
- `gui/control_center/mixins/table.py`: Loop status tooltip and display enhancements.
- `openspec/specs/ralph-loop/spec.md`: Updated state format, new status values.
- `tests/gui/`: New/updated tests for loop status display.
