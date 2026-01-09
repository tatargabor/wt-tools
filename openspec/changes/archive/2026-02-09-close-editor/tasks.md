## 1. Platform Layer

- [x] 1.1 Add `close_window(window_id, app_name)` to `gui/platform/base.py` (default returns False)
- [x] 1.2 Implement `close_window()` in `gui/platform/linux.py` using `xdotool windowclose`
- [x] 1.3 Implement `close_window()` in `gui/platform/macos.py` using AppleScript

## 2. GUI Handler and Menu

- [x] 2.1 Add `on_close_editor()` handler in `gui/control_center/mixins/handlers.py`
- [x] 2.2 Add "Close Editor" menu item in `gui/control_center/mixins/menus.py` after "Focus Window"

## 3. Tests

- [x] 3.1 Add test for Close Editor menu item presence in context menu
