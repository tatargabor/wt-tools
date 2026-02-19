## 1. Fix Critical Bugs

- [x] 1.1 Add missing `os_status = self.get_openspec_status(project)` in `_create_project_header()` (table.py ~line 210)
- [x] 1.2 Verify `_set_row_background` replaces alpha-transparent colors with opaque `bg_dialog` (already partially done)
- [x] 1.3 Verify `update_pulse` uses pre-blended opaque colors instead of `setAlphaF()` (already partially done)
- [x] 1.4 Verify `WA_StyledBackground` is set on QMainWindow (already partially done)
- [x] 1.5 Remove `WA_TranslucentBackground` from Ralph extra column widget (already partially done)

## 2. Error Boundaries on Signal Handlers

- [x] 2.1 Find the existing `@log_exceptions` decorator pattern in handlers.py
- [x] 2.2 Apply error boundary (try/except with logging) to `update_status()` in main_window.py
- [x] 2.3 Apply error boundary to `on_features_updated()` in main_window.py
- [x] 2.4 Apply error boundary to `update_team()` in team.py mixin
- [x] 2.5 Apply error boundary to `update_usage()` in main_window.py
- [x] 2.6 Apply error boundary to `update_chat_badge()` in main_window.py

## 3. Worker Logging

- [x] 3.1 Add logger to FeatureWorker (`wt-control.workers.feature`) — log poll cycles at DEBUG, errors at ERROR
- [x] 3.2 Add logger to ChatWorker (`wt-control.workers.chat`) — already has logger, verify it's used in all exception paths
- [x] 3.3 Add logger to UsageWorker (`wt-control.workers.usage`) — already has logger, verify poll cycle logging
- [x] 3.4 Replace bare `except: pass` with `except Exception as e: logger.error(...)` in FeatureWorker

## 4. GUI Tests

- [x] 4.1 Create `tests/gui/test_31_feature_header.py` — test project header renders with populated feature cache
- [x] 4.2 Add test: project header renders with empty feature cache (gray "checking..." buttons)
- [x] 4.3 Add test: all row backgrounds are opaque (alpha=255) after status update
- [ ] 4.4 Run full GUI test suite to verify no regressions
