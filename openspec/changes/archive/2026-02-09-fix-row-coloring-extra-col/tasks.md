## 1. Helper and Initial Render

- [x] 1.1 Add `_set_row_background(row, color)` helper in `gui/control_center/mixins/table.py` that sets background on both items and cellWidgets for all columns
- [x] 1.2 Use `_set_row_background()` in `_render_worktree_row()` instead of the inline loop at lines 269-276

## 2. Animation and Blink

- [x] 2.1 Use `_set_row_background()` in `update_pulse()` instead of the inline loop at lines 510-515
- [x] 2.2 Use `_set_row_background()` in `toggle_blink()` (main_window.py) instead of the inline loop at lines 626-629

## 3. Double-click Clear

- [x] 3.1 Use `_set_row_background()` in `on_double_click()` (handlers.py) instead of the inline loop at lines 382-385

## 4. Testing

- [x] 4.1 Add or update GUI test to verify row background coloring covers the Extra column
- [ ] 4.2 Run GUI tests: `PYTHONPATH=. python -m pytest tests/gui/ -v --tb=short`
