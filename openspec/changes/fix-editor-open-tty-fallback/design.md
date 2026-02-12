## Context

`is_editor_open()` in `bin/wt-status` determines whether an editor window is open for a worktree. It uses a three-step detection:

1. **PPID chain walking** — follows parent processes from the Claude agent PID looking for X11/macOS windows
2. **TTY fallback** — if step 1 fails but the agent has a TTY, returns true with `editor_type="terminal"`
3. **Title-based search** — xdotool/AppleScript window title matching

The TTY fallback (step 2) was originally added for remote/SSH sessions where no X11 display is available. However, it fires for ANY terminal-based Claude session, causing `editor_open=true` even when the configured editor is an IDE (like Zed) and no IDE window exists.

Existing helpers in `wt-common.sh`:
- `get_configured_editor()` — returns editor name (e.g., "zed", "auto")
- `get_editor_property <name> type` — returns "ide" or "terminal"
- `SUPPORTED_EDITORS` array with `name:command:type` entries

## Goals / Non-Goals

**Goals:**
- `is_editor_open()` returns false for bare terminal sessions when configured editor is IDE type
- Orphan cleanup correctly triggers for worktrees where only terminal Claude sessions exist (no IDE window)
- TTY fallback still works when configured editor is terminal type (kitty, alacritty, etc.)

**Non-Goals:**
- Changing how agent status (running/waiting/orphan) is determined — that's session-mtime-based and correct
- Changing the PPID chain or xdotool detection — those work fine
- GUI changes — the GUI already consumes `editor_open` correctly

## Decisions

### Decision 1: Read editor type inside `is_editor_open()`

**Choice**: Call `get_configured_editor` + `get_editor_property` at the top of `is_editor_open()` to determine whether TTY-only counts as "editor open."

**Alternative considered**: Pass editor type as a parameter from the caller. Rejected because `is_editor_open` is called from two places (`get_worktree_json` and `cleanup_orphan_agents`) and adding a parameter to both is more invasive with no benefit — `wt-common.sh` is already sourced.

### Decision 2: TTY fallback gated on editor type

**Choice**: The TTY fallback block (current lines 121–128) only executes when `editor_type == "terminal"`. When `editor_type == "ide"`, skip it — fall through to title-based search or return false.

| Config | PPID chain finds window? | TTY present? | Result |
|--------|-------------------------|-------------|--------|
| ide    | YES                     | *           | true   |
| ide    | NO                      | YES         | **false** (was: true) |
| ide    | NO                      | NO          | false  |
| terminal | YES                   | *           | true   |
| terminal | NO                   | YES         | true (TTY fallback) |
| terminal | NO                   | NO          | false  |
| auto   | *                       | *           | resolve to actual type, then apply above |

### Decision 3: `auto` mode resolution

**Choice**: When editor is `auto`, call `get_active_editor()` (existing helper in `wt-common.sh` line ~626) to resolve to an actual editor name, then look up its type. If no editor is detected, default to `ide` behavior (require a window).

**Rationale**: If no editor can be detected, the safe default is to require a window — falsely reporting "no editor" is less disruptive than falsely reporting "editor open."

## Risks / Trade-offs

- **Risk**: Users running Claude exclusively from terminals (no IDE) with editor config still set to "zed" (default) will see their agents cleaned up as orphans.
  → **Mitigation**: The `cleanup_orphan_agents` secondary safety check (lines 304–319) already protects interactive terminal sessions — agents with a TTY + active shell (zsh/bash) are never killed. This change only affects `editor_open` reporting, not agent killing of interactive sessions.

- **Risk**: Slightly slower `is_editor_open()` due to config file read.
  → **Mitigation**: `get_configured_editor()` reads a small JSON file once. This is negligible compared to the existing `ps`, `xdotool`, and `/proc` reads already in the function.
