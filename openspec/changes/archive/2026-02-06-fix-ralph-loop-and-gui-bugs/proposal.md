## Why

Three bugs surfaced during a Ralph loop test on a cross-project worktree:
1. `wt-loop monitor/status/stop` fails with "Worktree not found" when the loop runs in a different project than CWD — `list` scans all projects but other commands only search the current one.
2. The GUI's `on_focus()` double-click handler shows a `show_warning()` dialog when no editor window is found, but the dialog can get hidden behind other windows, blocking the entire UI with no way to dismiss it.
3. `quit_app()` and `restart_app()` forget to stop `usage_worker`, so on exit Qt destroys a running QThread and calls `fatal()` → `abort()`.

## What Changes

- **wt-loop cross-project lookup**: `cmd_monitor`, `cmd_status`, `cmd_stop`, and `cmd_history` will scan all registered projects when the change-id isn't found in the current project, matching the behavior of `cmd_list`.
- **on_focus dialog visibility**: When no editor window is found, use a non-blocking approach (tray notification or status bar message) instead of a blocking `QDialog.exec()` / `show_warning()` that can freeze the UI.
- **UsageWorker shutdown**: Add `usage_worker` to the shutdown sequence in `quit_app()` and `restart_app()`. Make UsageWorker's 30s sleep interruptible so `stop()` takes effect within ~500ms.

## Capabilities

### New Capabilities

_(none)_

### Modified Capabilities

- `ralph-loop`: Cross-project worktree resolution for monitor/status/stop/history commands
- `control-center`: Non-blocking feedback when on_focus fails to find an editor window
- `usage-display`: Clean shutdown of UsageWorker thread

## Impact

- `bin/wt-loop` — `cmd_monitor`, `cmd_status`, `cmd_stop`, `cmd_history` functions
- `bin/wt-common.sh` — possibly add a `find_worktree_across_projects()` helper
- `gui/control_center/mixins/handlers.py` — `on_focus()` error path
- `gui/control_center/main_window.py` — `quit_app()`, `restart_app()`
- `gui/workers/usage.py` — `run()` sleep pattern, `stop()` method
