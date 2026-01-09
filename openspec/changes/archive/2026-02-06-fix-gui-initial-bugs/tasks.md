## Tasks: fix-gui-initial-bugs

### Safari Session Import
- [x] Add Safari to browser list in `gui/workers/usage.py` `_import_browser_session()`

### Always-on-Top Fix
- [x] Add `raise_()` call after `self.show()` in handlers that hide/show the main window

### Work Dialog / wt-work
- [x] Fix Zed `-n` flag incompatibility on macOS in `bin/wt-work`

### Worktree Lista
- [x] Verified `refresh_status()` works correctly - no fix needed

### MCP Server Install (ÚJ)
- [x] Investigated: MCP server was not registered because `uv` was not installed
- [x] Installed `uv` and registered MCP server with `claude mcp add`
- [x] MCP server now connected and working

### Always-on-Top Robusztus Fix (ÚJ)
- [x] Current Qt flags not sufficient on macOS - window gets covered when switching apps with Tab
- [x] ~~Implemented periodic raise timer~~ - REMOVED (stole focus)
- [x] ~~Implemented PyObjC NSFloatingWindowLevel~~ - not strong enough
- [x] Use NSStatusWindowLevel (25) instead of NSFloatingWindowLevel (3)

### wt-work Dialog Fix
- [x] Remove CommandOutputDialog for wt-work - runs in background via subprocess.Popen

### wt-loop macOS Support
- [x] Add Terminal.app support using osascript
- [x] Fix bash vs zsh issue (use temp script file to run commands in bash)
