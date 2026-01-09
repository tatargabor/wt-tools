# Add Worktree Control Center

## Summary
Central dashboard to monitor and manage multiple worktrees with parallel Claude agents.

## Problem
When working with multiple worktrees simultaneously (each with a Claude agent), there's no unified view to:
- See all active worktrees and their status
- Know which agents have finished or need attention
- Quickly switch between worktree windows
- Start new worktrees

## Solution
A lightweight control center with two modes:

### 1. Mini Panel (always visible)
- Small, unobtrusive indicator (e.g., system tray or floating widget)
- Shows: number of active worktrees, agents needing attention
- Click to expand to full terminal view

### 2. Full Terminal View (expandable)
- Interactive TUI showing all worktrees
- Agent status (running/idle/done/needs-input)
- Quick actions: focus window, start new, close

## Technical Approach

### Agent Status Detection
- Monitor `claude` processes by PID and working directory
- Detect if process is actively running or idle (waiting for input)
- Use `/proc` filesystem on Linux for process state

### Window Management
- Use `xdotool` to find and focus Zed windows by title/class
- Optional auto-focus when agent finishes
- Configurable: auto vs manual mode

### Mini Panel Options
1. **Terminal in Zed** - dedicated Zed terminal pane with `watch wt-status`
2. **Polybar/i3blocks module** - if using tiling WM
3. **Simple floating terminal** - small always-on-top terminal

## Phased Approach

### Phase 1: CLI Foundation
- `wt-status` command with JSON output
- Claude process detection
- Basic TUI for full view

### Phase 2: Integration
- Zed window detection/focus
- Auto-refresh terminal view
- Notifications when agent completes

### Phase 3: Mini Panel
- Choose best approach based on Phase 1-2 learnings
- Could be as simple as `watch -n 2 wt-status --compact`

## Future Enhancements

### Claude Code Integration (later)
- `/wt:status` slash command for inline status
- Status line integration (compact view in Claude Code footer)
- Hook-based periodic status display
- MCP server for tool-based queries
