## Why

When Zed editor is closed, Claude Code terminal processes survive as orphans. `wt-status` detects these orphans as live processes (they pass `kill -0`) and reports them as "waiting" — resulting in permanently yellow rows in the GUI. There is no mechanism to detect that the editor window is gone and clean up the associated agents. On re-open, new agents spawn alongside stale orphans, leading to confused status and PID accumulation. This makes the Control Center unreliable for daily use on Linux.

## What Changes

- **Orphan agent detection and auto-kill**: `wt-status` checks whether an editor window exists for each worktree. If agents are running but no editor window is open (and no Ralph loop is active), those agents are killed automatically and removed from the status output.
- **`editor_open` field in status JSON**: Each worktree entry gains a boolean `editor_open` field so the GUI and other consumers know whether the editor is present.
- **Editor window detection in wt-status**: New `is_editor_open()` bash function using platform-appropriate detection (xdotool on Linux, osascript on macOS, tasklist on Windows). Falls back to `/proc` scanning for editor process CWD if xdotool is unavailable.
- **Robust status transitions**: Agents in worktrees without an editor and without a Ralph loop get status "orphan" briefly before being killed, then disappear from the next status cycle.
- **GUI orphan handling**: The table renderer treats "orphan" status as gray/dimmed and removes the row on the following refresh after the kill.
- **Integration tests**: New tests verifying orphan detection, status accuracy, editor window presence simulation, and PID lifecycle.
- **Zed open verification**: Verify and fix `wt-work` and `wt-new` editor opening stability on Linux.

## Capabilities

### New Capabilities
- `orphan-agent-cleanup`: Automatic detection and termination of Claude agent processes that no longer have an associated editor window open.

### Modified Capabilities
- `editor-integration`: Add editor window presence detection requirement. `wt-status` must check for editor windows per worktree.
- `control-center`: Add `editor_open` field to status JSON. Add orphan status handling in agent detection. Update status display to handle orphan agents.

## Impact

- `bin/wt-status`: New functions `is_editor_open()`, `cleanup_orphan_agents()`. Modified `collect_worktree_status()` to include `editor_open` field and orphan logic.
- `bin/wt-common.sh`: May need shared editor window detection helpers.
- `gui/control_center/mixins/table.py`: Handle "orphan" agent status in rendering.
- `gui/workers/status.py`: No changes (passthrough).
- `tests/gui/`: New test files for orphan detection and Zed integration scenarios.
- `install.sh`: Ensure xdotool is listed as Linux dependency.
- Cross-platform: Linux primary, macOS/Windows detection stubs for future.
