## Why

The GUI's "New Worktree" dialog fails with `Error: [Errno 2] No such file or directory: 'wt-new'` because it invokes `wt-new` via bare command name (PATH lookup) instead of using the full path via `SCRIPT_DIR`, unlike every other wt-* command in the same file. When the GUI is launched from contexts where `~/.local/bin` is not in PATH, the command is not found.

## What Changes

- Fix `create_worktree()` in `gui/control_center/mixins/handlers.py` to use `SCRIPT_DIR / "wt-new"` instead of bare `"wt-new"`, consistent with all other wt-* command invocations in the same file.
- Add automated test coverage for the `create_worktree()` code path, which is currently untested (existing worktree tests bypass the GUI handler entirely).

## Capabilities

### New Capabilities

- `wt-new-path-fix`: Fix wt-new command resolution in GUI to use full path via SCRIPT_DIR

### Modified Capabilities

_None — no spec-level behavior changes, this is a bug fix in existing implementation._

## Impact

- `gui/control_center/mixins/handlers.py` — lines 230, 233: change bare `"wt-new"` to `str(SCRIPT_DIR / "wt-new")`
- `tests/gui/` — new test file for create_worktree handler validation
