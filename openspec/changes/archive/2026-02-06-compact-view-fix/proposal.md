## Why

The compact view filter button (🖥️) uses `xdotool` for editor window detection, which is Linux-only. On macOS, `xdotool` is missing so `editor_paths` returns an empty set, causing the filter to hide ALL rows instead of showing active ones. The existing `wt-status` data already contains `agent.status` for every worktree — there's no need for external window detection at all.

## What Changes

- Replace xdotool-based editor detection with agent status filtering: show only local worktrees where `agent.status != "idle"` (running/waiting/compacting)
- Hide main repo rows, team rows, and idle local worktrees when filter is active
- Remove `gui/editor_detection.py` entirely
- Update button tooltip from "Show only worktrees with open editor" to "Show only active worktrees"
- Filter re-evaluates naturally on every table refresh (no extra calls needed)

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `control-center`: The filter button behavior changes from editor-window-based to agent-status-based filtering

## Impact

- `gui/editor_detection.py` — removed entirely
- `gui/control_center/mixins/table.py` — filter logic simplified (use agent.status instead of editor_paths)
- `gui/control_center/main_window.py` — remove editor detection imports/calls, update tooltip
- No external dependencies removed (xdotool was never a declared dependency)
