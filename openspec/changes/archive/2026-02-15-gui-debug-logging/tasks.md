## 1. Logging Infrastructure

- [x] 1.1 Create `gui/logging_setup.py` with `setup_logging()` function — RotatingFileHandler to `/tmp/wt-control.log` (cross-platform via `tempfile.gettempdir()`), 5 MB max, 3 backups, format: `YYYY-MM-DD HH:MM:SS LEVEL module:function message`
- [x] 1.2 Create `log_exceptions` decorator in `gui/logging_setup.py` for wrapping Qt signal handlers
- [x] 1.3 Call `setup_logging()` in `gui/main.py` at startup, log app version and Python version

## 2. Handler Logging (handlers.py)

- [x] 2.1 Add logger and `@log_exceptions` to `on_double_click` — log entry with project/change_id/path, each decision branch (window found, window_id fallback, editor open), and the final action taken
- [x] 2.2 Add logger and `@log_exceptions` to `on_focus`, `on_close_editor` — log window search/focus/close results
- [x] 2.3 Add logging to `on_new`, `on_work`, `on_add`, `on_close` — log action entry and key parameters
- [x] 2.4 Add logging to `git_merge`, `git_merge_from`, `git_push`, `git_pull`, `git_fetch`, `create_worktree` — log command and subprocess results

## 3. Platform Logging (macos.py, linux.py, windows.py)

- [x] 3.1 Add logger to `gui/platform/macos.py` — log `find_window_by_title` (input + result), `focus_window` (input + success/fail), `close_window`, `find_window_by_pid`
- [x] 3.2 Add logger to `gui/platform/linux.py` — same coverage: `find_window_by_title`, `focus_window`, `close_window`, `find_window_by_pid`, `find_window_by_class`
- [x] 3.3 Add logger to `gui/platform/windows.py` — same coverage for implemented methods

## 4. Menu and Dialog Logging

- [x] 4.1 Add logger to `gui/control_center/mixins/menus.py` — log context menu action selection with worktree project/change_id
- [x] 4.2 Add logging to dialog subprocess calls in `gui/dialogs/command_output.py` — log command start and completion

## 5. Worker Error Logging

- [x] 5.1 Add logger to `gui/workers/status.py` — log errors only (not normal poll cycles)
- [x] 5.2 Add logger to `gui/workers/team.py`, `gui/workers/chat.py`, `gui/workers/usage.py` — log errors only

## 6. Testing

- [x] 6.1 Add `tests/gui/test_30_logging.py` — verify log file creation, log format, RotatingFileHandler setup, and that `log_exceptions` decorator catches and logs exceptions
