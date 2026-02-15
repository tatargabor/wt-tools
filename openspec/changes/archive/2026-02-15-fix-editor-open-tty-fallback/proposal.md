## Why

`is_editor_open()` in `wt-status` has a TTY fallback that returns true whenever a Claude process has a TTY — even when the configured editor is an IDE like Zed. This causes all terminal-based Claude sessions to report `editor_open: true`, which prevents orphan cleanup and makes every idle worktree show "waiting" status in the Control Center, even when no IDE window is open.

## What Changes

- Make `is_editor_open()` editor-type-aware: read the configured editor type (`ide` vs `terminal`) and only use the TTY fallback when type is `terminal`.
- When editor type is `ide` (zed, vscode, cursor, windsurf), require an actual window match (PPID chain or xdotool/AppleScript title search) — a bare TTY is not sufficient.
- When editor type is `terminal` (kitty, alacritty, etc.), the existing TTY fallback remains valid.
- When editor is `auto`, detect the active editor type and apply the appropriate rule.

## Capabilities

### New Capabilities

_(none)_

### Modified Capabilities

- `orphan-agent-cleanup`: The "Editor Window Presence Detection" requirement must account for editor type — TTY-only detection should only report `editor_open: true` when the configured editor is a terminal emulator, not an IDE.

## Impact

- `bin/wt-status`: `is_editor_open()` function — add config lookup and conditional TTY fallback.
- `bin/wt-common.sh`: May need a helper to resolve configured editor type (`ide`/`terminal`) for use by `wt-status`.
- Control Center GUI: No changes needed — it already consumes `editor_open` from `wt-status` JSON.
- Orphan cleanup: Will now correctly trigger for worktrees with idle terminal Claude sessions when an IDE is configured.
