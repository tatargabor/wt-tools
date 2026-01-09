## Why

When first launching the Control Center GUI on macOS, several critical bugs appear: Safari session import doesn't work for Claude login, already opened worktrees don't appear, the Work button can't open worktrees, the window doesn't stay on top, and the MCP server doesn't install properly.

## What Changes

- Add Safari browser to the session import browser list
- Fix worktree list initialization order (refresh before first status update)
- Fix Work dialog and other dialogs' always-on-top handling on macOS
- Re-activate main window always-on-top after dialog closure
- Remove Zed `-n` flag (incompatible with macOS)
- **NEW:** Fix MCP server installation (symlink/config)
- **NEW:** More robust always-on-top solution (NSWindow level or timer-based reactivation)

## Capabilities

### New Capabilities
- (no new capabilities)

### Modified Capabilities
- `control-center`: Safari session import support, worktree list initialization fix, always-on-top consistency on macOS

## Impact

**Affected files:**
- `gui/workers/usage.py` - Add Safari to browser list
- `gui/control_center/main_window.py` - Worktree list initialization, always-on-top reactivation
- `gui/dialogs/work.py` - Dialog window flags macOS compatibility
- `gui/control_center/mixins/handlers.py` - Window handling after dialog closure

**Platform:** macOS-specific fixes, but changes don't break Linux/Windows operation.
