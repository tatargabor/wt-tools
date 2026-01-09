## 1. Fix macOS Platform Methods

- [x] 1.1 Fix `find_window_by_title()` in `gui/platform/macos.py` — rewrite AppleScript to search window titles of a specific editor app (default "Zed"), not process names. Add optional `app_name` parameter.
- [x] 1.2 Fix `focus_window()` in `gui/platform/macos.py` — use `activate` on the editor app + `AXRaise` on the matching window. Accept window title as identifier (macOS) instead of PID.
- [x] 1.3 Update `gui/platform/base.py` — add `app_name` optional parameter to `find_window_by_title()` docstring/signature if needed for the interface.

## 2. Rewire GUI Focus Handler

- [x] 2.1 Rewrite `on_focus()` in `gui/control_center/mixins/handlers.py` — use the platform layer (`get_platform().find_window_by_title()` + `focus_window()`) instead of shelling out to `wt-focus`. Resolve the worktree directory basename for the title search. Pass editor app name from config.
- [x] 2.2 Update `focus_ralph_terminal()` in handlers.py — verify it also uses the platform layer correctly (it already does, just verify the macOS path works with the fixed methods).

## 3. Add macOS Support to wt-focus CLI

- [x] 3.1 Add macOS branch in `bin/wt-focus` — when `xdotool` is not available and platform is Darwin, use `osascript` to find and focus editor windows by title. Use the same AppleScript logic as the Python platform layer.

## 4. Testing

- [x] 4.1 Add or update GUI tests in `tests/gui/` for the focus functionality — test that `on_focus()` uses the platform layer and not subprocess wt-focus.
- [x] 4.2 Run GUI tests: `PYTHONPATH=. python -m pytest tests/gui/ -v --tb=short`
