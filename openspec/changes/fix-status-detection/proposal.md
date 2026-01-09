## Why

The `wt-status` agent status detection has two bugs:
1. **False "compacting" status**: The compacting detection uses unreliable text pattern matching (`"type":"summary"`, `"compacting"`, `"Summarizing"`) on the last line of session JSONL files. The `"type":"summary"` pattern matches session title entries (which are always the last line of completed sessions), causing false positives. Since compacting is a transient state (seconds) and functionally equivalent to "running" from the user's perspective, it should be removed entirely — agents that are compacting should show as "running".
2. **Waiting/blink notification is per-worktree but should survive the running→waiting→running→waiting cycle correctly**: The `check_status_changes` in the GUI aggregates agent statuses at the worktree level. When a worktree has multiple agents and one finishes (running→waiting), the worktree-level status may flicker between states as individual agents finish at different times, creating spurious notifications.

## What Changes

- **Remove compacting status entirely**: In `detect_agents()`, remove the `tail -1` + text pattern matching logic. If session mtime < 10s → `running`. Period. Remove all compacting-related UI code (icon, color, tray tooltip, summary counts).
- **Remove compacting from GUI**: Remove compacting color definitions, status icon, row styling, tray icon logic, and status aggregation references.
- **Clean up multi-agent-detection spec**: Remove `compacting` from the status values in the spec.

## Capabilities

### New Capabilities

_(none)_

### Modified Capabilities

- `multi-agent-detection`: Remove "compacting" from the set of agent status values (running/waiting/compacting → running/waiting). Update per-agent status determination scenario.

## Impact

- `bin/wt-status`: Remove compacting detection logic from `detect_agents()`, remove compacting from summary counts, terminal format, and compact format.
- `gui/control_center/main_window.py`: Remove compacting from `check_status_changes` aggregation, `update_tray_icon`, tooltip.
- `gui/control_center/mixins/table.py`: Remove compacting row styling.
- `gui/constants.py`: Remove compacting color definitions.
- `openspec/specs/multi-agent-detection/spec.md`: Remove compacting from status values.
