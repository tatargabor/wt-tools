## 1. Simplify always-on-top setup in main_window.py

- [x] 1.1 Change `_setup_macos_always_on_top()` to use NSStatusWindowLevel (25) instead of level 1000
- [x] 1.2 Remove the `_front_timer`, `_bring_to_front()` method, and timer setup from `setup_always_on_top_timer()`
- [x] 1.3 Remove `pause_always_on_top()` and `resume_always_on_top()` methods
- [x] 1.4 Remove `_menu_open` attribute references

## 2. Remove pause/resume calls from menus.py

- [x] 2.1 Remove all `pause_always_on_top()` / `resume_always_on_top()` try/finally blocks from context menu methods (`show_context_menu`, `show_row_context_menu`, `show_team_row_context_menu`, and all menu action methods)

## 3. Remove pause/resume calls from handlers.py

- [x] 3.1 Remove all `pause_always_on_top()` / `resume_always_on_top()` try/finally blocks from dialog-opening handlers (`on_new`, `on_close`, `on_focus`, `git_merge`, `start_ralph_loop_dialog`, `show_worktree_config`, `show_chat_dialog`, etc.)

## 4. Simplify dialog helpers

- [x] 4.1 Remove `pause_always_on_top()` / `resume_always_on_top()` calls from `_run_dialog()` in `gui/dialogs/helpers.py` (keep `WindowStaysOnTopHint` on dialogs)

## 5. Remove pause/resume from custom dialogs

- [x] 5.1 Search for and remove any remaining `pause_always_on_top` / `resume_always_on_top` calls in `gui/dialogs/*.py` or anywhere else in the codebase

## 6. Update CLAUDE.md

- [x] 6.1 Simplify the "macOS Always-On-Top Dialog Rule" section — remove the pause/resume instructions, keep the helper usage recommendation

## 7. Tests

- [x] 7.1 Add or update GUI test to verify that `pause_always_on_top` / `resume_always_on_top` methods no longer exist on the main window
- [x] 7.2 Add test to verify NSWindow level is set to 25 (or skip gracefully if pyobjc not available)
