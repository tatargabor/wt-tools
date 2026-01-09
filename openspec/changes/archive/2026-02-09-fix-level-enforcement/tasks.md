## 1. Core Level Enforcement

- [x] 1.1 Add `_enforce_native_level()` method to MainWindow — checks current NSWindow level and sets to 25 if drifted
- [x] 1.2 Add `_on_app_state_changed()` handler that calls `_enforce_native_level()` with 50ms QTimer.singleShot delay
- [x] 1.3 Connect `QApplication.instance().applicationStateChanged` signal in `setup_always_on_top_timer()`
- [x] 1.4 Add periodic backup timer (5s interval) calling `_enforce_native_level()` in `setup_always_on_top_timer()`

## 2. Native Setup Hardening

- [x] 2.1 Add `ns_window.setHidesOnDeactivate_(False)` to `_setup_macos_always_on_top()`
- [x] 2.2 Ensure `show_window()` calls full `_setup_macos_always_on_top()` after `setWindowFlags()` (already does — verify it works with new enforcement)

## 3. Tests

- [x] 3.1 Add test for `_enforce_native_level` method existence
- [x] 3.2 Add test for `_on_app_state_changed` method existence
- [x] 3.3 Add test that periodic level enforcement timer is running (macOS only)
- [x] 3.4 Update existing `test_ns_window_level_is_status` to also verify level is maintained after simulated state change
