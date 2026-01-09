## Context

The Control Center has a filter button (🖥️) intended to show a compact view of only "active" worktrees. The current implementation uses `xdotool` to detect open editor windows and match them to worktree paths. This is Linux-only — on macOS, `xdotool` doesn't exist, so the detection returns an empty set and the filter hides every row.

Meanwhile, `wt-status --json` already provides `agent.status` (running/waiting/compacting/idle) for every worktree. This data is refreshed on every status cycle and is already available in `self.worktrees` when the table renders.

## Goals / Non-Goals

**Goals:**
- Make the compact filter work on all platforms using existing worktree data
- Remove the xdotool dependency and `EditorDetectionMixin` entirely
- Simplify the filter: active = `agent.status != "idle"`

**Non-Goals:**
- Adding macOS editor detection (AppleScript-based or otherwise) — not needed
- Changing the refresh cycle or data flow

## Decisions

### Use agent.status instead of editor window detection

**Rationale**: The `agent.status` field already tells us if a worktree is actively being worked on. An editor being open is a weaker signal — you could have an editor open on an idle worktree. Agent status is more meaningful and already available cross-platform.

**Alternative considered**: Implementing macOS editor detection via AppleScript. Rejected because it adds complexity for a weaker signal.

### Filter rule: show only non-idle local worktrees

When filter is active, show a row only if ALL conditions are met:
- It is a local worktree (not team, not `is_main_repo`)
- `agent.status` is one of: `running`, `waiting`, `compacting`

Everything else is hidden: idle locals, main repo rows, all team rows.

### Remove EditorDetectionMixin completely

The entire `gui/control_center/mixins/editor_detection.py` file and its mixin class are removed. No fallback, no platform check — the feature is replaced, not adapted.

### No extra invalidation needed

The current flow already works: `refresh_table_display()` re-renders the table from `self.worktrees` on every status refresh. The filter just adds a condition to the rendering loop. The `invalidate_editor_cache()` calls become no-ops and are removed.

## Risks / Trade-offs

- **[Changed semantics]** The button now filters by agent activity, not editor windows. Users who had editors open on idle worktrees would have seen them before (on Linux) but won't now. → Acceptable: agent status is a better signal.
- **[No filter when all idle]** If all worktrees are idle, the filter shows an empty table. → Same as current behavior on macOS. Could add a "no active worktrees" message later if needed.
