## Context

The orchestrator's `cmd_start()` has three resume paths:
1. status="done" → clean up, start fresh
2. status="plan_review" → wait for approval
3. status="running" → **exit with error** ("already running")

Path 3 is correct when a live orchestrator is running, but wrong after a crash. The sentinel's `check_stale_state()` can reset top-level status from "running" to "stopped", but individual change entries remain status="running" with stale worktree_path and ralph_pid values.

When `resume_stopped_changes()` runs, it only processes changes with status="stopped" — orphaned "running" changes are ignored, creating a permanent deadlock.

## Goals / Non-Goals

**Goals:**
- Recover orphaned "running" changes after crash (reset to pending for re-dispatch)
- Prevent duplicate dispatch (verify PID is dead before recovery)
- Handle multiple orphaned changes in a single restart
- Log recovery actions clearly for operator visibility

**Non-Goals:**
- Fixing sentinel worktree pruning behavior (that's correct — pruning stale worktrees is the right thing to do)
- Recovering in-progress work from dead worktrees (code is in git branches, not lost)
- Hot-reload recovery (only on restart via cmd_start)

## Decisions

### D1: Recovery function in cmd_start() resume path

Add `recover_orphaned_changes()` that runs BEFORE `resume_stopped_changes()` and `dispatch_ready_changes()`. This ensures orphaned changes are reset to "pending" before any dispatch logic runs.

**Why cmd_start and not monitor loop?** Recovery is a one-time startup operation. Running it in the monitor loop would add unnecessary checks every 15 seconds.

### D2: Three-condition check before recovery

A change is recovered only when ALL three conditions are met:
1. status = "running" (or "verifying", "stalled")
2. worktree_path is missing (`! -d "$wt_path"`) or null/empty
3. ralph_pid is dead (`! kill -0 "$pid" 2>/dev/null`) or null/0

If any condition fails (e.g., worktree exists, or PID is alive), the change is left as-is.

**Why all three?** Prevents false recovery. A live Ralph process with a missing worktree is a different bug. A dead PID with an existing worktree might be resumable without full re-dispatch.

### D3: Reset fields on recovery

Recovered changes get:
- status → "pending"
- worktree_path → null
- ralph_pid → null
- verify_retry_count → 0
- failure_reason → null

This gives dispatch a clean slate. The existing branch cleanup logic in `dispatch_change()` (lines 249-252) already handles stale `change/` branches.

### D4: Emit recovery event

Each recovered change emits a `CHANGE_RECOVERED` event with the change name and reason. This provides audit trail and sentinel visibility.

## Risks / Trade-offs

- [Risk: PID collision — new process reuses dead PID] → Very rare on modern Linux (PID space is large). Could add timestamp check as future hardening but not worth the complexity now.
- [Risk: Recovery resets verify_retry_count — change that failed verify gets unlimited retries] → Acceptable: the change starts fresh with a new worktree and clean state. Previous verify failures were in a different worktree context.
- [Risk: Multiple orphaned changes all reset to pending simultaneously] → Handled by existing `max_parallel` dispatch limit. They'll queue up naturally.
- [Risk: Branch conflict if old `change/` branch still exists in git] → Already handled by `dispatch_change()` which deletes stale branches before worktree creation (dispatcher.sh:249-252).
