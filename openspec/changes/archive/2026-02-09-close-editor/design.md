## Context

The Control Center GUI manages editor windows via the platform abstraction layer (`gui/platform/`). Currently it supports `find_window_by_title()` and `focus_window()`. The "Focus Window" context menu action finds the editor window matching the worktree basename and brings it to front — or opens it if not found.

There is no way to close an editor window from the GUI. Users must alt-tab to find and close it manually.

## Goals / Non-Goals

**Goals:**
- Add "Close Editor" to the worktree row context menu
- Graceful close (WM_DELETE_WINDOW on Linux, AppleScript on macOS) — editors can prompt for unsaved changes
- Reuse existing window detection logic from `on_focus`

**Non-Goals:**
- Force-killing editor processes
- Closing all windows of an editor (only the one matching the worktree)
- Windows platform support (currently unsupported for window management)

## Decisions

### D1: Use `xdotool windowclose` on Linux
`xdotool windowclose` sends WM_DELETE_WINDOW, which is the standard graceful close. The editor handles it the same as clicking the X button — including unsaved changes prompts.

Alternative: `xdotool key --window <id> ctrl+w` — editor-specific, unreliable.
Alternative: `wmctrl -c` — requires separate tool, xdotool already in use.

### D2: Place menu item directly after "Focus Window"
The close action is logically paired with focus — both operate on the editor window. Placing them together makes the menu scannable.

### D3: Silent no-op when no window found
If the editor window is already closed, do nothing. No error dialog needed — the action is idempotent.

## Risks / Trade-offs

- [Editor prompts for unsaved changes] → Expected behavior, same as clicking X. No mitigation needed.
- [xdotool not installed on some Linux distros] → Same risk as existing focus_window. Returns False gracefully.
