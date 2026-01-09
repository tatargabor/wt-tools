## 1. Constants

- [x] 1.1 Add `ICON_IDLE_IDE = "◇"` to `gui/constants.py` and export it
- [x] 1.2 Add `status_idle_ide`, `row_idle_ide`, `row_idle_ide_text` color keys to all 4 color profiles (light, dark, gray, high_contrast)

## 2. Status icon mapping

- [x] 2.1 Add `"idle (IDE)"` entry to `get_status_icon()` in `gui/control_center/main_window.py` with icon `◇` and color key `status_idle_ide`

## 3. Row rendering

- [x] 3.1 In `_render_worktree_row()` in `gui/control_center/mixins/table.py`, when status is "idle" and `editor_open=true`, change the status string to `"idle (IDE)"` before passing to `get_status_icon()` and use `row_idle_ide` / `row_idle_ide_text` for row colors

## 4. Tests

- [x] 4.1 Add test in `tests/gui/` verifying that a worktree with `editor_open=true` and empty agents displays `◇ idle (IDE)` status
- [x] 4.2 Add test verifying that a worktree with `editor_open=false` and empty agents displays `○ idle` status
