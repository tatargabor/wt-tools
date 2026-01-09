## Why

The Control Center has "Focus Window" to bring an editor to front, but no way to close it. When done with a worktree, users must manually find and close the editor window. A "Close Editor" context menu action completes the editor lifecycle management.

## What Changes

- Add "Close Editor" action to the worktree row context menu, directly below "Focus Window"
- Add `close_window(window_id)` method to the platform abstraction layer
- Implement Linux support via `xdotool windowclose` (graceful WM_DELETE_WINDOW)
- Implement macOS support via AppleScript `close window`

## Capabilities

### New Capabilities

_None — this extends existing capabilities._

### Modified Capabilities

- `editor-integration`: Add editor window close requirement alongside existing focus behavior
- `menu-system`: Add Close Editor action to worktree context menu

## Impact

- `gui/platform/base.py` — new abstract method
- `gui/platform/linux.py` — xdotool implementation
- `gui/platform/macos.py` — AppleScript implementation
- `gui/control_center/mixins/handlers.py` — new `on_close_editor()` handler
- `gui/control_center/mixins/menus.py` — new menu item
