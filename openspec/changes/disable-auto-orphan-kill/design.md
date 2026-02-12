## Context

The `cleanup_orphan_agents()` function in `bin/wt-status` automatically kills "waiting" agents that have no detected editor window and no active Ralph loop. On macOS, the osascript-based window detection is unreliable — it caused an active Claude Code session to be killed (exit code 143 / SIGTERM) mid-work. The grace period (3x detection + 15 seconds) does not help when window detection consistently returns false negatives.

The GUI already has a manual "Kill Orphan Process" context menu option, so the user can kill orphans on demand.

## Goals / Non-Goals

**Goals:**
- Disable automatic orphan killing in `cleanup_orphan_agents()` on all platforms
- Keep orphan detection working (agents still flagged as orphans in UI with ⚠ prefix)
- Preserve the grace period infrastructure as dormant code (commented out kill)

**Non-Goals:**
- Fixing the window detection reliability (separate concern, separate change)
- Adding a settings toggle for auto-kill (may do later if window detection improves)
- Removing the grace period code entirely

## Decisions

### Decision 1: Comment out kill, don't delete

**Choice**: Comment out the `kill` line and `continue` with explanatory comments, rather than removing the code.

**Rationale**: The auto-kill feature may be re-enabled in the future if window detection becomes more reliable. Keeping the code (commented) with an explanation makes it easy to restore.

**Alternative considered**: Delete all auto-kill code and grace period infrastructure → rejected because it's more churn for a potentially temporary decision.

### Decision 2: Platform-agnostic disable

**Choice**: Disable on all platforms (macOS and Linux), not just macOS.

**Rationale**: While macOS triggered the bug, Linux window detection (xdotool / /proc scan) is also not 100% reliable. The risk of killing an active session outweighs the convenience of auto-cleanup on any platform.

## Risks / Trade-offs

- **Orphan accumulation**: Without auto-kill, orphan agents may pile up if user doesn't manually clean them. → Mitigation: GUI clearly shows ⚠ orphans, context menu kill is easy.
- **Dormant code**: Commented-out kill may confuse future contributors. → Mitigation: Clear comment explaining why and when it was disabled.
