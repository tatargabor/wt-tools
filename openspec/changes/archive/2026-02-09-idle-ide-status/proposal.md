## Why

Worktrees with an editor open but no Claude agent are currently shown as plain "idle" — indistinguishable from worktrees with nothing open at all. Users want to see at a glance which worktrees have an active workspace (IDE open), both as a reminder ("I'm working there") and as a signal that orphan protection is active. The `editor_open` data is already in the JSON output; it just needs a distinct visual representation.

## What Changes

- Add a new visual status `idle (IDE)` with a distinct icon (`◇`) for worktrees where `editor_open=true` and agents array is empty
- Add `status_idle_ide` color and `row_idle_ide` / `row_idle_ide_text` colors to all 4 color profiles
- Add `ICON_IDLE_IDE` constant
- Update `get_status_icon()` to handle the new status
- Update `_render_worktree_row()` to pass `editor_open` through and select the correct status

## Capabilities

### New Capabilities

### Modified Capabilities
- `control-center`: Add `idle (IDE)` as a visual status variant for worktrees with editor open but no agent

## Impact

- `gui/constants.py`: New icon constant, new color keys in all 4 profiles
- `gui/control_center/main_window.py`: `get_status_icon()` updated
- `gui/control_center/mixins/table.py`: `_render_worktree_row()` updated to emit `idle (IDE)` status
- No `wt-status` (bash) changes — `editor_open` is already in JSON output
