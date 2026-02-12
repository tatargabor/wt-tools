## Why

After the TTY-fallback fix (`fix-editor-open-tty-fallback`), agents in plain terminals whose PPID chain reaches a terminal window (e.g. gnome-terminal) still report `editor_open=true`. The GUI shows them as orange `⚡ waiting` — identical to agents waiting inside the configured IDE. Users see "waiting" everywhere and cannot distinguish "agent idle in Zed" from "agent idle in a plain terminal." Focus also tries to find a Zed window first (slow, fails) before falling back to the terminal window.

## What Changes

- GUI table: when an agent's `editor_type` from wt-status is a terminal process (not the configured IDE), display a distinct visual status instead of the standard orange `⚡ waiting`.
- GUI focus (`on_focus`): when `editor_type` indicates a terminal, skip the IDE title search and go directly to the `window_id` fallback — faster and always correct.
- No wt-status changes needed — the data (`editor_type`, `window_id`) is already available in the JSON output.

## Capabilities

### New Capabilities

_(none)_

### Modified Capabilities

- `control-center`: The worktree table rendering must distinguish agents running inside the configured IDE from agents running in a plain terminal, using the `editor_type` field from wt-status. Focus action must adapt its strategy based on editor type.

## Impact

- `gui/control_center/mixins/table.py`: `_render_worktree_row()` — compare `editor_type` against configured editor to choose status display.
- `gui/control_center/main_window.py`: `get_status_icon()` — add icon/color for new terminal-waiting status.
- `gui/control_center/mixins/handlers.py`: `on_focus()` — short-circuit to `window_id` when `editor_type` is a terminal.
- `tests/gui/` — add test for the new display logic.
