## Why

When the orchestrator crashes during execution (SIGKILL, OOM, broken pipe), state.json retains status="running" for active changes with worktree paths that may no longer exist (pruned by sentinel or system cleanup). On restart, the orchestrator either exits with "already running" error or crashes when trying to resume into missing worktree directories. This was observed in CraftBrew E2E run #2 where 2 changes were permanently lost to a crash loop.

## What Changes

- **Orphaned running change recovery**: On startup, detect changes with status="running" whose worktree directories no longer exist AND whose Ralph processes are dead. Reset them to "pending" for fresh re-dispatch.
- **PID liveness guard**: Before resetting any change, verify the Ralph PID is truly dead via `kill -0` to prevent duplicate dispatch if a process is still alive somewhere.
- **Stale branch cleanup**: Clear old worktree_path and ralph_pid fields on recovered changes so dispatch creates fresh worktrees without branch conflicts.

## Capabilities

### New Capabilities

_(none)_

### Modified Capabilities

- `orchestration-engine`: Add orphaned change recovery to startup/resume flow with PID liveness and worktree existence checks

## Impact

- `lib/orchestration/dispatcher.sh` — new `recover_orphaned_changes()` function, modified `cmd_start()` resume path
- `lib/orchestration/state.sh` — field reset helpers for recovered changes
- No config changes, no new dependencies, no API changes
