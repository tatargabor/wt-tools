## Context

Three bugs found during a cross-project Ralph loop test:
1. `wt-loop monitor/status/stop/history` use `resolve_project("")` (CWD-based) to find the worktree, but `wt-loop list` scans all projects. When running from a different project's directory, the commands fail with "Worktree not found".
2. `on_focus()` in the GUI calls `show_warning()` when no editor window is found. This opens a blocking `QDialog.exec()` that can get hidden behind other windows on macOS, freezing the entire UI.
3. `quit_app()` and `restart_app()` stop `worker`, `team_worker`, `chat_worker` but forget `usage_worker`. The UsageWorker thread is still in `msleep(30000)` when Python exits, causing `QThread::~QThread()` → `fatal()` → `abort()`.

## Goals / Non-Goals

**Goals:**
- `wt-loop monitor/status/stop/history` find worktrees across all registered projects
- `on_focus()` failure feedback is non-blocking (no modal dialog)
- All worker threads are cleanly stopped on app exit

**Non-Goals:**
- Redesigning the `wt-loop` command structure
- Changing the always-on-top timer system
- Making other worker threads' sleep interruptible (only UsageWorker has a 30s sleep that's problematic)

## Decisions

### D1: Cross-project worktree lookup via fallback scan

Add a `find_worktree_across_projects()` function to `wt-common.sh` that:
1. First tries the current project (fast path, backwards-compatible)
2. If not found, scans all registered projects — same logic `cmd_list` already uses

**Why not `-p project` flag?** The user doesn't know (or care) which project a change-id belongs to. The change-id should be sufficient. A `-p` flag can be added later if needed but isn't the primary fix.

**Applied in:** `cmd_monitor`, `cmd_status`, `cmd_stop`, `cmd_history` — replacing their `resolve_project("") + find_existing_worktree()` calls.

### D2: Double-click = window-presence-based, not agent-status-based

Simplify `on_double_click()` to a single decision: **does an IDE window exist for this worktree?**

- **YES** → focus it (`platform.focus_window`)
- **NO** → open it (`wt-work`)

Agent status is irrelevant. This eliminates the old `on_focus()` error path entirely — there's no "no window found" failure case anymore, because "no window" simply triggers `wt-work`.

**Why remove the agent-status branch?** The old logic (idle → wt-work, active → focus) assumed active agents always have an IDE window. That's false — Ralph loops can run without an IDE open. The window-presence check is the right abstraction.

### D3: Centralized worker shutdown helpers

Extract `_stop_all_workers()` and `_wait_all_workers()` methods that handle all 4 workers. Both `quit_app()` and `restart_app()` use these.

Workers are stopped in parallel (all get `stop()` first), then waited sequentially with a timeout. Stragglers are `terminate()`d.

### D4: Interruptible sleep for UsageWorker

Replace `msleep(30000)` with a loop of `msleep(500)` checking `_running` between chunks. This means `stop()` takes effect within ~500ms instead of up to 30 seconds.

**Why not QWaitCondition?** Overkill for this case. The chunked sleep pattern is simple, zero-dependency, and matches how other developers would expect `stop()` to work.

## Risks / Trade-offs

- **[Cross-project scan is O(projects × worktrees)]** → Acceptable: typical setup has 2-5 projects with <10 worktrees each. The scan runs `git worktree list` per project which is fast.
- **[wt-work called even with active agent]** → Desired behavior: opens IDE alongside the running agent. No conflict.
- **[terminate() can leave threads in bad state]** → Mitigated: only used as fallback after 2s wait timeout. The interruptible sleep makes this extremely unlikely for UsageWorker.
