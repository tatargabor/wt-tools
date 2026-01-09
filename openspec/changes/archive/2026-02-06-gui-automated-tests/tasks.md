## 1. Setup Test Infrastructure

- [x] 1.1 Install pytest-qt dependency
  - [x] Add `pytest-qt` to dev dependencies in `pyproject.toml`
  - [x] Verify `pip install pytest-qt` works
- [x] 1.2 Make CONFIG_DIR respect WT_CONFIG_DIR env var
  - [x] Update `gui/constants.py`: `CONFIG_DIR` reads `WT_CONFIG_DIR` env var with fallback
  - [x] Update `gui/control_center/main_window.py`: `POSITION_FILE` derives from `CONFIG_DIR` (now a property)
- [x] 1.3 Create test directory structure
  - [x] Create `tests/gui/__init__.py`
  - [x] Create `tests/gui/conftest.py` with fixtures (git_env, control_center, screenshot hook)
  - [x] Add `test-results/` to `.gitignore`
- [x] 1.4 Add pytest configuration
  - [x] Add `qt_api = pyside6` to `[tool.pytest.ini_options]` in pyproject.toml
- [x] 1.5 Optimize test performance
  - [x] Module-scoped `control_center` fixture (1 window per file, not per test)
  - [x] Faster worker cleanup (500ms wait + terminate vs 3s wait)
  - [x] Result: 49 tests in ~28s (was ~120s)

## 2. Startup Tests

- [x] 2.1 Create `tests/gui/test_01_startup.py` — ALL 4 TESTS PASS
  - [x] `test_app_starts_without_error`
  - [x] `test_window_is_visible`
  - [x] `test_initial_status_label`
  - [x] `test_table_exists_with_correct_columns`

## 3. Window Property Tests

- [x] 3.1 Create `tests/gui/test_02_window.py` — ALL 7 PASS
  - [x] `test_always_on_top`
  - [x] `test_frameless`
  - [x] `test_tool_window`
  - [x] `test_fixed_width`
  - [x] `test_window_title_contains_version`
  - [x] `test_opacity_set`
  - [x] `test_position_saved_and_restored` — uses shared fixture, verifies file save

## 4. Button Tests

- [x] 4.1 Create `tests/gui/test_03_buttons.py` — ALL 7 PASS
  - [x] `test_btn_new_exists`
  - [x] `test_btn_work_exists`
  - [x] `test_btn_add_exists`
  - [x] `test_btn_filter_is_toggle`
  - [x] `test_btn_refresh_exists`
  - [x] `test_btn_minimize_hides_window` — restores visibility after test
  - [x] `test_btn_menu_exists`

## 5. Main Menu Tests

- [x] 5.1 Create `tests/gui/test_04_main_menu.py` — ALL 3 PASS
  - [x] `test_main_menu_has_all_items`
  - [x] `test_main_menu_minimize_hides` — restores visibility after test
  - [x] `test_main_menu_settings_opens_dialog`

## 6. Context Menu Tests

- [x] 6.1 Create `tests/gui/test_05_context_menu.py` — ALL 3 PASS
  - [x] `test_window_right_click_menu`
  - [x] `test_row_right_click_menu_on_empty`
  - [x] `test_row_right_click_menu_with_worktree`

## 7. System Tray Tests

- [x] 7.1 Create `tests/gui/test_06_tray.py` — ALL 4 PASS
  - [x] `test_tray_icon_exists`
  - [x] `test_tray_icon_visible`
  - [x] `test_tray_tooltip` — checks tooltip is non-empty (content varies with status)
  - [x] `test_tray_has_menu`

## 8. Dialog Tests

- [x] 8.1 Create `tests/gui/test_07_dialogs.py` — ALL 4 PASS
  - [x] `test_settings_dialog_opens_and_closes`
  - [x] `test_new_worktree_dialog_opens`
  - [x] `test_new_worktree_dialog_preview_updates`
  - [x] `test_work_dialog_opens_with_tabs`

## 9. Worktree Operation Tests (real git)

- [x] 9.1 Create `tests/gui/test_08_worktree_ops.py` — ALL 4 PASS
  - [x] `test_create_worktree`
  - [x] `test_worktree_appears_in_table`
  - [x] `test_copy_path_to_clipboard`
  - [x] `test_close_worktree`

## 10. Table Tests

- [x] 10.1 Create `tests/gui/test_09_table.py` — ALL 4 PASS
  - [x] `test_empty_table_renders`
  - [x] `test_table_columns_correct`
  - [x] `test_table_with_worktree_shows_project_header`
  - [x] `test_double_click_no_crash`

## 11. Theme Tests

- [x] 11.1 Create `tests/gui/test_10_themes.py` — ALL 5 PASS
  - [x] `test_light_theme_applies`
  - [x] `test_dark_theme_applies`
  - [x] `test_gray_theme_applies`
  - [x] `test_high_contrast_theme_applies`
  - [x] `test_theme_switch_at_runtime`

## 12. Ralph Loop Tests

- [x] 12.1 Create `tests/gui/test_11_ralph_loop.py` — ALL 4 PASS
  - [x] `test_ralph_status_idle_when_no_loop` — no .claude/loop-state.json → status is None/idle
  - [x] `test_ralph_loop_context_menu_shows_start` — when no loop running, menu shows "Start Loop..."
  - [x] `test_ralph_loop_state_file_detected` — create a fake loop-state.json, verify GUI reads it
  - [x] `test_ralph_loop_context_menu_shows_stop_when_running` — with active loop state, menu shows "Stop Loop"

---

## Test Results Summary

**49/49 tests pass** in ~28 seconds on macOS.

Run all tests: `PYTHONPATH=. python -m pytest tests/gui/ -v --tb=short`

## Fixed Issues

### BUG FOUND: `toggle_active_filter` calls non-existent `render_table()`
- **File**: `gui/control_center/main_window.py:762`
- **Fix applied**: Changed `self.render_table()` → `self.refresh_table_display()`
- **Status**: FIXED ✓

### CRASH: QMenu.exec patching causes abort
- **Problem**: PySide6 `QMenu.exec()` is a C++ slot. Direct `unittest.mock.patch` causes SIGABRT.
- **Solution**: `_MenuCapture` context manager patches `QMenu.__init__` to replace `exec` on each instance.
- **Status**: FIXED ✓

### CRASH: teardown abort from `deleteLater()` with running threads
- **Problem**: `window.deleteLater()` caused SIGABRT when threads still running.
- **Solution**: Removed `deleteLater()`, signal all workers to stop, wait 500ms, terminate stragglers.
- **Status**: FIXED ✓

### Tray icon accumulation
- **Problem**: Each ControlCenter creates a tray icon; icons piled up.
- **Solution**: Module-scoped fixtures (11 windows instead of 49) + explicit `tray.hide()` in teardown.
- **Status**: FIXED ✓

### POSITION_FILE used import-time CONFIG_DIR
- **Problem**: Class attribute `POSITION_FILE = CONFIG_DIR / ...` was evaluated at import, not reflecting test overrides.
- **Solution**: Changed to `@property` that reads `CONFIG_DIR` dynamically.
- **Status**: FIXED ✓
