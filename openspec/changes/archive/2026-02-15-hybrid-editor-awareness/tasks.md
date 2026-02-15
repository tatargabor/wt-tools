## 1. GUI: Terminal-aware status display

- [x] 1.1 In `gui/control_center/mixins/table.py` `_render_worktree_row()`: add a helper check `_is_ide_editor_type(editor_type)` that returns True if `editor_type` is in `{"zed", "Zed", "code", "Code", "cursor", "Cursor", "windsurf", "Windsurf"}`. When an agent is "waiting" and `editor_type` is truthy but NOT an IDE, use dimmed row colors (`row_idle` bg, `text_muted` text) instead of the standard orange waiting colors.
- [x] 1.2 Add test in `tests/gui/` to verify that `_render_worktree_row()` uses dimmed colors for terminal-type `editor_type` and standard orange for IDE-type.

## 2. GUI: Focus optimization

- [x] 2.1 In `gui/control_center/mixins/handlers.py` `on_focus()`: before the title-based search, check if the worktree's `editor_type` is non-IDE (using the same set). If so, skip title search and go directly to `window_id` fallback.

## 3. Verify

- [x] 3.1 Manual verify: run Control Center with terminal-only Claude sessions — waiting agents should appear dimmed, not orange.
- [x] 3.2 Manual verify: double-click a terminal-based worktree in the GUI — it should focus the terminal window directly without delay.
