## Why

Row background coloring (pulse animation for running, blink for attention, static colors for waiting/compacting) does not visually extend to the Extra column (COL_EXTRA = 5) when that column contains a cellWidget (Ralph buttons). The `item.setBackground()` calls work on QTableWidgetItem, but the cellWidget sits on top and has no background set, leaving a transparent gap at the end of the row.

## What Changes

- When setting row background color in `_render_worktree_row()`, `update_pulse()`, and `toggle_blink()`, also apply the background color to cellWidgets in COL_EXTRA via stylesheet or `setAutoFillBackground()` + palette
- Ensure the integrations widget created in `_render_extra_column()` is transparent-aware so it picks up background changes

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `control-center`: Row coloring SHALL visually cover all columns including columns with cellWidgets

## Impact

- `gui/control_center/mixins/table.py` — `_render_worktree_row()`, `_render_extra_column()`, `update_pulse()`
- `gui/control_center/main_window.py` — `toggle_blink()`
