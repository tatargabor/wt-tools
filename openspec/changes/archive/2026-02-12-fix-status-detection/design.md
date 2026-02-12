## Context

The `detect_agents()` function in `bin/wt-status` determines agent status using session JSONL file analysis. The current compacting detection (line 432) uses unreliable text pattern matching that produces false positives — most commonly because `"type":"summary"` matches session title entries, not compaction events.

The compacting status was intended to show when an agent is summarizing its context window. In practice:
- It's a transient state lasting seconds
- The pattern matching is wrong (matches session titles, random text)
- From the user's perspective, compacting = running (agent is alive and working)

The compacting status is referenced in: `bin/wt-status` (detection, summary, terminal format, compact format), `gui/constants.py` (5 color profiles × 2 entries each), `gui/control_center/main_window.py` (status aggregation, tray icon, tooltip), `gui/control_center/mixins/table.py` (row styling).

## Goals / Non-Goals

**Goals:**
- Remove unreliable compacting detection — treat all active agents (session mtime < 10s) as `running`
- Remove all compacting-related UI code (colors, icons, status text, tray logic)
- Keep JSON output backward-compatible by keeping `compacting: 0` in summary

**Non-Goals:**
- Changing waiting/running/orphan/idle detection logic (those work correctly)
- Redesigning the PID-to-session matching heuristic
- Adding new status types

## Decisions

### Decision 1: Remove compacting entirely rather than fix detection

**Rationale**: Even with reliable detection (using `subtype: "compact_boundary"` or `isCompactSummary: true` from the JSONL), compacting is a transient state (2-5 seconds) that the 2-second polling interval rarely captures. The user gains no actionable information from seeing "compacting" vs "running". Removing it is simpler and eliminates false positives permanently.

**Alternative considered**: Fix detection with `jq` parsing of `subtype` field. Rejected because it adds `jq` dependency to a hot path, and the information has no user value.

### Decision 2: Keep `compacting: 0` in JSON summary output

**Rationale**: External consumers (MCP server, scripts) may parse the summary JSON. Removing the field would break them. Always outputting `0` is backward-compatible and signals that compacting is no longer tracked.

### Decision 3: Remove orphan-grace logic for compacting

In `bin/wt-status` line 332, there's a comment about keeping "running/compacting" agents and resetting orphan markers. After removal, only "running" agents reset markers.

## Risks / Trade-offs

- [Lost visibility into compacting] → Minimal risk. The status was unreliable anyway, and compacting is functionally "running".
- [Breaking external consumers] → Mitigated by keeping `compacting: 0` in JSON summary. GUI code changes are internal.
