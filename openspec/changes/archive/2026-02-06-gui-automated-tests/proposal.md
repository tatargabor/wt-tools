## Summary

Add automated GUI integration tests for the Worktree Control Center that verify core functionality works correctly on macOS (first), with Linux and Windows support planned. Tests use real git repos (temp fixtures), real worktree operations, and screenshot capture on failure. Designed to be run by Ralph Loop for automated test-fix-retest cycles.

## Problem

The Control Center GUI has no automated tests. Bugs can go unnoticed until manual testing catches them. There's no way to verify that menus, buttons, dialogs, worktree operations, and themes all work after code changes. Cross-platform regressions are especially hard to catch.

## Proposed Solution

### Test Framework
- **pytest + pytest-qt** for GUI testing (industry standard for Qt apps)
- **Temp git repos** created by fixtures (no manual setup needed)
- **WT_CONFIG_DIR override** for test isolation (shell scripts already support this; GUI constants.py needs a small change)
- **Screenshot on failure** using Qt's `window.grab()` - saved to `test-results/screenshots/`

### Test Structure
```
tests/gui/
├── conftest.py              # Fixtures: git repo, config, ControlCenter
├── test_01_startup.py       # App starts, window visible, table exists
├── test_02_window.py        # Always-on-top, frameless, position save/restore
├── test_03_buttons.py       # All buttons exist, clickable, correct labels
├── test_04_main_menu.py     # ≡ menu opens, items present, Settings dialog
├── test_05_context_menu.py  # Right-click menus on window and rows
├── test_06_tray.py          # System tray icon, menu, tooltip
├── test_07_dialogs.py       # Settings, New Worktree, Work dialogs open/close
├── test_08_worktree_ops.py  # Create/list/close worktree with real git
├── test_09_table.py         # Table rendering, columns, project headers
└── test_10_themes.py        # All 4 color profiles apply correctly
```

### Key Design Decisions
1. **Real git operations, not mocks** - Tests create bare repo + clone as fixtures, run actual `wt-new`/`wt-close` scripts
2. **Isolated config** - `WT_CONFIG_DIR` env var points to temp directory, preventing pollution of real config
3. **Module-scoped git fixtures** - Git repo created once per test module (fast), ControlCenter per test (clean)
4. **Screenshot on failure** - pytest hook captures window screenshot when any test fails
5. **Ralph-compatible** - Tests output standard pytest results; Ralph can run them and fix failures iteratively

### Ralph Loop Usage
```
Task: "Run pytest tests/gui/ -v. Fix GUI code bugs (not tests). Rerun."
Done criteria: "All GUI tests pass"
Max iterations: 10
```

## Scope

### Files to modify
- `gui/constants.py` - Make CONFIG_DIR respect WT_CONFIG_DIR env var
- `gui/control_center/main_window.py` - Make POSITION_FILE use CONFIG_DIR

### Files to create
- `tests/gui/conftest.py` - Test fixtures
- `tests/gui/test_01_startup.py` through `test_10_themes.py` - Test files
- `pytest.ini` or `pyproject.toml` section - pytest-qt configuration

### Dependencies to add
- `pytest-qt` in dev/test requirements

## Out of Scope

- JIRA integration tests (later)
- Team sync tests (later)
- Chat tests (later)
- CI/CD pipeline setup (later - first get tests working locally on macOS)
- Visual regression testing / pixel comparison (later)
- Performance/load testing
