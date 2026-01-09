## Why

When a terminal tab is closed in Zed (or other editors), the shell process dies but the child `claude` process survives as an orphan — re-parented directly to the editor process (e.g., PID of Zed). These orphan agents continue to appear in the Control Center as "waiting", indistinguishable from legitimate agents. They waste memory and pollute the worktree list.

## What Changes

- `wt-status` `detect_agents()` gains PPID-based orphan detection: if a `claude` process's parent is not a shell (zsh/bash/fish/sh) but directly an editor process (Zed, VS Code, etc.), it is classified as `"orphan"` instead of its normal status.
- GUI displays orphan agent rows with distinct gray styling and a `⚠` warning icon in the PID column.
- Right-click context menu on orphan rows includes a "Kill Orphan Process" action that sends SIGTERM to clean up the dead agent.

## Capabilities

### New Capabilities

_None_ — this extends existing agent detection, not a new capability.

### Modified Capabilities

- `control-center`: Add orphan agent status detection in `wt-status`, orphan row styling in GUI, and "Kill Orphan Process" context menu action.

## Impact

- `bin/wt-status`: `detect_agents()` function modified to check PPID and classify orphans.
- `gui/control_center/mixins/table.py`: Orphan row styling (gray background, `⚠` in PID column).
- `gui/control_center/mixins/menus.py`: "Kill Orphan Process" context menu item for orphan rows.
- `gui/constants.py`: Orphan color constants added to color profiles.
- `tests/gui/`: New or extended test for orphan row display and context menu action.
