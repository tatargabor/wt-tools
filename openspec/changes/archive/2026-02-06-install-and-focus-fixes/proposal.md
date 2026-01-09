## Why

Two usability bugs cause friction in the daily workflow: (1) after running `install.sh`, `wt-*` commands are not found because `~/.local/bin` is never added to the shell PATH automatically, and (2) `wt-work` always opens a new Zed window (`zed -n`) instead of reusing/focusing an existing one for the same worktree.

## What Changes

- `install.sh`: When `~/.local/bin` is not in PATH, automatically append an `export PATH` line to the user's shell rc file (`~/.zshrc`, `~/.bashrc`, or `~/.profile`) with an idempotency marker (`# WT-TOOLS:PATH`), instead of just printing a warning.
- `wt-work`: Remove the `-n` flag from the `zed` invocation so that Zed reuses/focuses an existing window for the same path instead of always creating a new one.

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `worktree-tools`: install.sh auto-configures PATH; wt-work Zed invocation changed from `-n` (new window) to no flag (reuse/focus)
- `control-center`: pyobjc-framework-Cocoa added as macOS dependency for always-on-top NSWindow support; silent import failure replaced with warning

## Impact

- `install.sh` — `install_scripts()` function: adds a new `ensure_path()` helper that writes to shell rc files
- `bin/wt-work` — Zed case branch: removes `-n` flag
- `pyproject.toml` — adds `pyobjc-framework-Cocoa` as platform-specific dependency for macOS
- `gui/control_center/main_window.py` — adds warning log when pyobjc import fails in `_get_ns_window()`
- No breaking changes (existing behavior simply becomes automatic/correct)
