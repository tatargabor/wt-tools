## Why

The `on_focus()` handler in the Control Center GUI calls the `wt-focus` bash script, which depends on `xdotool` — a Linux/X11-only tool. On macOS, focus silently fails. A Python platform abstraction layer (`gui/platform/macos.py`) already exists with AppleScript-based `focus_window()` and `find_window_by_title()`, but these methods have bugs and are not wired into the GUI's focus flow.

## What Changes

- **`on_focus()` in handlers.py**: Use the Python platform layer instead of shelling out to `wt-focus` on all platforms. The platform layer already handles Linux (xdotool) and macOS (AppleScript) — it just needs to be called.
- **`find_window_by_title()` in macos.py**: Fix the AppleScript — currently searches for process names containing the title string (broken), needs to search window titles across all processes (or target the active editor specifically).
- **`focus_window()` in macos.py**: Currently takes a PID and sets the process frontmost. Needs to also support activating a specific window by title, since `find_window_by_title` should return enough info to focus the right window.
- **`wt-focus` bash script**: Add macOS support using `osascript` as fallback when `xdotool` is not available, so the CLI command also works on macOS (not just the GUI).

## Capabilities

### New Capabilities

_(none — this is a fix to existing capabilities)_

### Modified Capabilities

- `editor-integration`: Window focus scenarios currently specify xdotool only. Requirements should be platform-agnostic (xdotool on Linux, AppleScript on macOS).

## Impact

- `gui/control_center/mixins/handlers.py` — `on_focus()` method
- `gui/platform/macos.py` — `find_window_by_title()`, `focus_window()`
- `bin/wt-focus` — macOS support branch
- `openspec/specs/editor-integration/spec.md` — platform-agnostic focus requirements
