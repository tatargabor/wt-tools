## Why

The Control Center worktree list is confusing when there are many projects/worktrees - it's hard to find the actively used ones. Additionally, the current status display ("waiting") is misleading, and showing the PID would be better replaced with the currently running skill name.

## What Changes

- **Active filter button**: New toggle button on the toolbar that only shows worktrees where an editor window is open (Zed, VS Code, Cursor, Windsurf)
- **Skill tracking**: Display the running skill name instead of PID (e.g., "opsx:explore", "wt:new")
- **PID removal**: Process ID no longer appears next to the status

## Capabilities

### New Capabilities
- `editor-window-detection`: Detecting editor windows based on worktree path, filter logic in the GUI
- `skill-tracking`: Skill registration to status file, skill name reading and display

### Modified Capabilities
- `control-center`: New filter button on the toolbar, modified status display

## Impact

- **Modified files:**
  - `bin/wt-status` - skill reading, status renaming, PID removal
  - `bin/wt-focus` - editor detection function exports
  - `gui/control_center/main_window.py` - filter button, filter state
  - `gui/control_center/mixins/table.py` - filtered rendering
  - `.claude/skills/*/SKILL.md` - skill registration addition

- **New files:**
  - `bin/wt-skill-start` - helper script for skill registration
  - `gui/control_center/mixins/editor_detection.py` - editor window detection mixin
