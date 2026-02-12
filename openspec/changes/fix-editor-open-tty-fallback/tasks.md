## 1. Resolve editor type in `is_editor_open()`

- [x] 1.1 Add editor type resolution at the top of `is_editor_open()` in `bin/wt-status`: call `get_active_editor()` to get the editor name, then `get_editor_property "$name" type` to get `ide` or `terminal`. Default to `ide` if no editor is detected.
- [x] 1.2 Gate the TTY fallback block (lines 121–128) with a condition: only execute when resolved editor type is `terminal`. When type is `ide`, skip the TTY fallback and fall through to the title-based window search.

## 2. Verify existing behavior

- [x] 2.1 Manually verify: with `editor=zed` configured, run `wt-status --json` — confirm that worktrees with only terminal Claude sessions now show `editor_open: false`.
- [x] 2.2 Manually verify: orphan cleanup now triggers for worktrees with idle terminal-only agents (no Zed window).
- [x] 2.3 Verify the PPID chain detection still works: open a Zed window for a worktree, confirm `editor_open: true` with a real `window_id`.
