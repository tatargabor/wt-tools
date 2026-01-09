## 1. Add `get_main_branch()` helper to `wt-common.sh`

- [x] 1.1 Add `get_main_branch()` function
  - Takes `project_path` as argument
  - Returns `git -C "$project_path" symbolic-ref --short HEAD`
  - Fallback: returns `git rev-parse --short HEAD` if detached

## 2. Modify `bin/wt-status` to include main repo

- [x] 2.1 Remove the main repo skip filter in `collect_all_status()`
  - Refactored loop with `emit_entry()` helper
  - Main repo emitted first via `get_main_branch()` before worktree loop
- [x] 2.2 Add `is_main_repo` flag to `collect_worktree_status()` output
  - Added 5th parameter `is_main_repo` (default `false`)
  - Included `"is_main_repo": $is_main_repo` in the JSON output
- [x] 2.3 Emit main repo entry first per project
  - Main repo emitted before the worktree loop with `is_main_repo=true`
  - Uses branch name as `change_id` for main repo

## 3. Modify `bin/wt-work` for main branch support

- [x] 3.1 Detect main branch and skip worktree creation
  - Checks `change_id == main_branch` before worktree lookup
  - If match: `wt_path = project_path`, skips find/create
  - Editor open and Claude launch run unchanged

## 4. Modify `bin/wt-focus` for main branch support

- [x] 4.1 Update `get_worktree_path_for_focus()` to handle main branch
  - Early return with `project_path` if `change_id == main_branch`
  - Otherwise falls through to existing `change/*` branch search

## 5. GUI: Display main repo in table

- [x] 5.1 Update `refresh_table_display()` in `table.py`
  - Sort key: `not is_main_repo` ensures main repo sorts first within project
- [x] 5.2 Update `_render_worktree_row()` in `table.py`
  - Prefixes change_id with `★ ` when `is_main_repo` is true

## 6. GUI: Filter context menu for main repo

- [x] 6.1 Update `show_row_context_menu()` in `menus.py`
  - Read `is_main_repo = wt.get("is_main_repo", False)`
  - Skip "Worktree" submenu (Close, Push Branch) when `is_main_repo`
  - Skip "Git > Merge to..." when `is_main_repo`
  - All other menu items remain

## 7. GUI: Update handlers for main repo

- [x] 7.1 Update `on_double_click()` in `handlers.py`
  - No change needed — `wt-work` now handles main branch natively
  - Verified: `wt["change_id"]` (branch name) and `wt["project"]` are passed correctly
- [x] 7.2 Update `on_focus()` in `handlers.py`
  - No change needed — `wt-focus` now handles main branch natively

## 8. Add GUI tests

- [x] 8.1 Create `tests/gui/test_12_main_repo.py`
  - Test that main repo row appears in table with `★` prefix
  - Test that main repo row is first under project header
  - Test that context menu for main repo excludes Close/Merge to/Push Branch
  - Test that context menu for main repo includes Focus/Terminal/File Manager/Git Push/Pull/Fetch

## 9. Run tests

- [x] 9.1 Run full GUI test suite
  - `PYTHONPATH=. python -m pytest tests/gui/ -v --tb=short`
  - All 49 existing tests pass
  - All 5 new test_12_main_repo tests pass (54 total)
