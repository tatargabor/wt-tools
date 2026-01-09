## Context

The GUI's `_render_worktree_row()` already reads `editor_open` from the JSON and uses it to dim idle rows without an editor. The `get_status_icon()` function maps status strings to icons/colors. Currently "idle" is the only no-agent status — we split it into "idle" (nothing) and "idle (IDE)" (editor open).

## Goals / Non-Goals

**Goals:**
- Visually distinguish "editor open, no agent" from "nothing open"
- Minimal code change — reuse existing `editor_open` data, no new wt-status logic
- Consistent across all 4 color profiles

**Non-Goals:**
- Detecting specific editor types (Zed vs VSCode) in the status display
- Terminal-only detection (future work)
- Changing wt-status bash output format

## Decisions

### Decision 1: Status string "idle (IDE)" with icon ◇

Use `◇` (white diamond, U+25C7) — visually similar to `○` (idle) but clearly distinct. The text shows "idle (IDE)" to make it explicit. Color: a subtle blue-gray, slightly more prominent than plain idle gray.

**Why ◇:** It suggests "open/available" (hollow diamond = open workspace). Keeps visual consistency with `○` (idle) being a hollow shape.

### Decision 2: Derive status in _render_worktree_row, not in wt-status

The "idle (IDE)" status is purely visual — it's derived in the GUI from `editor_open + empty agents`. The bash `wt-status` output stays unchanged (agents array empty = idle). This keeps the data layer clean and avoids bash changes.

### Decision 3: Color choice — muted blue tint

Use a muted blue (not green/yellow/purple which are taken by other statuses). This signals "something is here" without implying activity. Distinct from idle gray but not attention-grabbing.

## Risks / Trade-offs

- [Extra status in icon map] → Trivial complexity increase, one entry in dict
- [Color consistency across profiles] → Each profile gets its own blue-gray variant tuned for contrast
