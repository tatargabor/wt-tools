## Why

The `wt-status` script uses Linux-only system calls (`/proc/$pid/cwd` and `stat -c %Y`) to detect Claude agent status. On macOS these silently fail, causing the GUI Control Center to always show "idle" for every worktree — even when agents are actively running. Context % updates correctly because it uses Python-based file I/O that is platform-agnostic.

## What Changes

- Add platform detection (`uname -s`) to `detect_agent_status()` in `bin/wt-status`
- Replace `readlink "/proc/$pid/cwd"` with `lsof -p $pid` on macOS to get process working directory
- Replace `stat -c %Y` with `stat -f "%m"` on macOS to get file modification time
- Extract platform-detection helpers so other shell scripts can reuse them if needed

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `worktree-tools`: The Cross-Platform Support requirement is not being met for `wt-status` — macOS process detection and file stat calls need platform-appropriate implementations.

## Impact

- **Code**: `bin/wt-status` (primary), potentially `bin/wt-common.sh` for shared helpers
- **Users**: macOS users will see correct running/waiting/compacting status in GUI and CLI
- **Dependencies**: `lsof` (pre-installed on macOS), no new dependencies needed
