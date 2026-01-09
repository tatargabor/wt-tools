## 1. Cross-project worktree lookup (wt-loop)

- [x] 1.1 Add `find_worktree_across_projects()` function to `bin/wt-common.sh` — tries current project first, then scans all registered projects
- [x] 1.2 Update `cmd_monitor` in `bin/wt-loop` to use `find_worktree_across_projects()` instead of `resolve_project("") + find_existing_worktree()`
- [x] 1.3 Update `cmd_status` in `bin/wt-loop` to use `find_worktree_across_projects()`
- [x] 1.4 Update `cmd_stop` in `bin/wt-loop` to use `find_worktree_across_projects()`
- [x] 1.5 Update `cmd_history` in `bin/wt-loop` to use `find_worktree_across_projects()`

## 2. Non-blocking on_focus failure feedback (GUI)

- [x] 2.1 ~~In `on_focus()`, replace `show_warning()` with tray notification~~ (superseded by 2.2)
- [x] 2.2 Rewrite `on_double_click()` to be window-presence-based: try focus, if no window → `wt-work`. Remove agent status branching.
- [x] 2.3 Update `test_16_focus.py` to match new behavior

## 3. Clean worker shutdown (GUI)

- [x] 3.1 Add `_stop_all_workers()` and `_wait_all_workers()` helper methods to `gui/control_center/main_window.py`
- [x] 3.2 Refactor `quit_app()` to use the new helpers (includes `usage_worker`)
- [x] 3.3 Refactor `restart_app()` to use the new helpers (includes `usage_worker`)
- [x] 3.4 Add `_interruptible_sleep()` method to `gui/workers/usage.py` — 500ms chunks checking `_running`
- [x] 3.5 Replace `msleep(30000)` calls in UsageWorker.run() with `_interruptible_sleep(30000)`

## 4. Tests

- [x] 4.1 Add test for `on_focus` with no editor window — verify no blocking dialog is shown
