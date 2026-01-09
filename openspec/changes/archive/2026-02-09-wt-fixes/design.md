## Context

In `gui/control_center/mixins/handlers.py`, every wt-* command is invoked using `str(SCRIPT_DIR / "wt-<name>")` which resolves to the absolute path of the script in `bin/`. The sole exception is `wt-new` on lines 230 and 233, which uses bare `"wt-new"` with a comment: "use global wt-new (from PATH), not local". This fails when the GUI process doesn't have `~/.local/bin` in PATH (e.g., launched from desktop environment, IDE, or launchd).

Existing tests (`test_08_worktree_ops.py`, `test_11_ralph_loop.py`) test worktree operations by calling `git worktree add` directly, never exercising the `create_worktree()` handler.

## Goals / Non-Goals

**Goals:**
- Fix `wt-new` invocation to use `SCRIPT_DIR` path, matching all other commands
- Add test that validates command construction in `create_worktree()`

**Non-Goals:**
- Refactoring other command invocations (they already work correctly)
- Adding end-to-end tests that actually create worktrees via the dialog
- Changing how `CommandOutputDialog` runs subprocesses

## Decisions

### Use `SCRIPT_DIR / "wt-new"` (same pattern as all other commands)

Replace bare `"wt-new"` with `str(SCRIPT_DIR / "wt-new")` on lines 230 and 233. This is the established pattern used by `wt-merge`, `wt-push`, `wt-work`, `wt-focus`, `wt-add`, and `wt-close` in the same file. Remove the misleading comment on line 228.

**Alternative considered**: Adding `~/.local/bin` to PATH in the subprocess env. Rejected — over-engineered, inconsistent with existing pattern, and fragile.

### Test via mock/patch on `run_command_dialog`

Patch `run_command_dialog` to capture the `cmd` argument, then call `create_worktree()` and assert the command list uses the full SCRIPT_DIR path. This avoids needing to actually spawn a dialog or create real worktrees.

## Risks / Trade-offs

- [Minimal risk] The fix is a 2-line change following an established pattern
- [Test gap] The new test validates command construction but not actual subprocess execution — acceptable since `CommandOutputDialog` is tested separately by other tests
