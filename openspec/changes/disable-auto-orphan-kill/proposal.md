## Why

The automatic orphan agent kill in `cleanup_orphan_agents()` is unreliable — especially on macOS where `osascript`-based window detection frequently misidentifies active sessions as orphans. This caused an active Claude Code session to be SIGTERM-ed (exit code 143) mid-work. The grace period (3x detection + 15 seconds) does not protect against consistent false negatives in window detection. The kill should be manual-only via the GUI context menu ("Kill Orphan Process"), which already exists.

## What Changes

- **Disable automatic `kill` in `cleanup_orphan_agents()`**: Comment out the `kill` call and the `continue` that removes the agent from output, with a comment explaining why (unreliable window detection, especially macOS).
- **Keep orphan detection intact**: The status="orphan" marking and grace period infrastructure remain — agents are still flagged as orphans in the UI (⚠ prefix), users just kill them manually.
- **No new capabilities**: The manual kill path already exists in the GUI context menu.

## Capabilities

### New Capabilities

_(none)_

### Modified Capabilities
- `orphan-agent-cleanup`: Disable the automatic SIGTERM — orphan detection stays, auto-kill goes away.

## Impact

| Area | Impact |
|------|--------|
| `bin/wt-status` | `cleanup_orphan_agents()` — comment out kill + continue |
| GUI behavior | No change — orphans still shown with ⚠, context menu kill still works |
| Grace period infra | Stays in place (marker files, detection counting) — dormant but preservable |
