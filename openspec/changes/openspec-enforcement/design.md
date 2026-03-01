## Context

The orchestrator creates `proposal.md` during dispatch but does not verify whether the full artifact chain (design, specs, tasks) exists. Agents discover missing artifacts at runtime, wasting an iteration figuring out what to do. After merge, changes stay in `openspec/changes/` indefinitely — 12 active right now, most already implemented. Delta specs are not synced to main specs unless manually archived.

Current merge flow in `merge_change()`: merge → post-merge build check → done. No cleanup.
Current dispatch flow in `dispatch_change()`: create worktree → create proposal → start ralph loop. No artifact check.

## Goals / Non-Goals

**Goals:**
- Ensure agents always start with actionable context (artifacts exist or first iteration creates them)
- Auto-archive merged changes so `openspec/changes/` stays clean
- Best-effort delta spec sync during archive (non-blocking)
- Warn about stale/orphan changes at orchestration start

**Non-Goals:**
- Enforcing artifact quality (only existence check, not content validation)
- Blocking merge on missing artifacts — that ship has sailed
- Full spec sync with conflict resolution — use `--skip-specs` on failure, sync is best-effort
- Modifying the `/opsx:archive` or `/opsx:sync-specs` skills — reuse existing CLI

## Decisions

### 1. Pre-dispatch artifact check

**Decision:** In `dispatch_change()`, after creating the change directory and proposal, check if `tasks.md` exists. If not, set `iteration_hint: "ff"` in the state so Ralph's first iteration runs `/opsx:ff`. If `tasks.md` exists, set `iteration_hint: "apply"`.

**Why:** The orchestrator already pre-creates `proposal.md`. Checking for `tasks.md` tells us if the full artifact chain was completed. We don't check design.md or specs separately — if tasks.md exists, the chain was completed (since tasks depends on design+specs in the schema).

**Alternative considered:** Running `openspec status --change <name> --json` to check all artifacts. Rejected: adds ~800ms CLI overhead per dispatch, and `tasks.md` existence is a sufficient proxy.

### 2. Auto-archive after merge

**Decision:** In `merge_change()`, after successful merge and push, call a new `archive_change()` function that:
1. Moves `openspec/changes/<name>/` to `openspec/changes/archive/<date>-<name>/`
2. Attempts `openspec archive <name> --skip-specs` (fast, no sync)
3. Commits the archive move

**Why:** Archive is a filesystem move — cheap and safe. We use `--skip-specs` by default because delta spec sync frequently fails on renamed requirement headers (8/14 changes needed it in previous batch). Sync can be done manually later in a batch.

**Alternative considered:** Auto-sync delta specs during archive. Rejected: sync failures would block the orchestration pipeline. Better to batch-sync separately.

### 3. Stale change detection at startup

**Decision:** In `cmd_start()`, before dispatching, scan `openspec/changes/` (excluding `archive/`) and compare against the current plan's change names. Any directory not in the plan and not having an active worktree gets logged as a warning.

**Why:** Stale changes from previous runs confuse the planner (it sees them as "active") and clutter the directory. A warning is sufficient — auto-deletion is too aggressive.

**Alternative considered:** Auto-archive stale changes. Rejected: they might be from manual work the user is doing outside orchestration.

## Risks / Trade-offs

- [Archive fails mid-orchestration] → Mitigated: archive is best-effort, logged but non-blocking. Orchestration continues regardless.
- [Stale detection false positives] → Mitigated: only warns, doesn't act. User decides.
- [`--skip-specs` means specs drift] → Accepted: periodic manual `openspec sync-specs` is the right cadence. Automated sync during merge is too risky.
- [iteration_hint not respected by wt-loop] → Implementation detail: wt-loop's `detect_next_change_action()` already handles this — if tasks.md is missing it returns `ff:<name>`. The hint is advisory, not a new mechanism.
