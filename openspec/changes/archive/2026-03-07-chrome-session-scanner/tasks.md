## 1. Chrome Cookie Scanner Module

- [x] 1.1 Create `gui/workers/chrome_cookies.py` with `scan_chrome_sessions()` function that returns `list[dict]` of `{"name": str, "sessionKey": str}`
- [x] 1.2 Implement Chrome profile discovery: scan platform-specific Chrome data dir for profile directories containing `Preferences` files
- [x] 1.3 Implement profile name resolution: read `Preferences` JSON → `account_info[0].full_name` → `profile.name` → directory name fallback
- [x] 1.4 Implement session cookie extraction using `pycookiecheat`: extract `sessionKey` cookie for `claude.ai` from each profile
- [x] 1.5 Handle `pycookiecheat` import failure gracefully: return indicator that the library is not installed

## 2. GUI Integration — Menu and Toolbar

- [x] 2.1 Add `scan_chrome_sessions` handler method in `gui/control_center/mixins/handlers.py` that calls the scanner, updates `claude-session.json` via `save_accounts()`, and restarts the usage worker
- [x] 2.2 Add "Scan Chrome Sessions" menu item in `show_main_menu()` in `gui/control_center/mixins/menus.py`, placed after "Add Account..."
- [x] 2.3 Add `🔍` toolbar button in `setup_ui()` in `gui/control_center/main_window.py`, between the filter button and minimize button, with tooltip "Scan Chrome Sessions"
- [x] 2.4 Show warning dialog with install instructions when `pycookiecheat` is not installed
- [x] 2.5 Show informational dialog when scan finds no Claude sessions

## 3. Auto-Scan on Startup

- [x] 3.1 Add `QTimer.singleShot(2000, self._auto_scan_chrome)` in `__init__` of `ControlCenter`
- [x] 3.2 Implement `_auto_scan_chrome` as a silent version of the scan handler (no dialogs on success or failure, only updates accounts if sessions found)

## 4. Tests

- [x] 4.1 Add `tests/gui/test_chrome_cookies.py` with unit tests for profile discovery, name resolution, and scanner error handling (mock `pycookiecheat` and filesystem)
