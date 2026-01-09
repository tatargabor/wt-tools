## Context

Two usability bugs exist in the current tooling:

1. **PATH not configured**: `install.sh` symlinks scripts to `~/.local/bin/` but only prints a warning if that directory is not in PATH. Users miss the warning and get "command not found" when trying to use `wt-*` commands.

2. **Zed always opens new window**: `wt-work` invokes `zed -n "$wt_path"` where `-n` means "new window". This creates duplicate Zed windows instead of focusing the existing one for the same worktree.

## Goals / Non-Goals

**Goals:**
- `install.sh` automatically adds `~/.local/bin` to PATH in the user's shell rc file
- `wt-work` reuses/focuses an existing Zed window instead of always opening a new one

**Non-Goals:**
- Changing how other editors (VS Code, Cursor, Windsurf) are launched
- Rewriting the install script beyond the PATH fix
- Implementing `wt-focus` for macOS (currently Linux-only via xdotool)

## Decisions

### 1. Auto-append PATH to shell rc file

**Decision**: Add an `ensure_path()` function to `install.sh` that appends `export PATH="$HOME/.local/bin:$PATH"` to the appropriate shell rc file.

**Shell rc detection**: Based on `$SHELL` — zsh → `~/.zshrc`, bash → `~/.bashrc`, fallback → `~/.profile`.

**Idempotency**: Use a marker comment `# WT-TOOLS:PATH` to prevent duplicate entries on re-install.

**Alternative considered**: Modifying `~/.zprofile` instead of `~/.zshrc` — rejected because `~/.zshrc` is loaded for both login and interactive shells and is the conventional place for user PATH additions.

### 2. Remove `-n` flag from Zed invocation

**Decision**: Change `zed -n "$wt_path"` to `zed "$wt_path"` in `wt-work`.

When called without flags, Zed's CLI will focus an existing window if the path is already open, or create a new window if it isn't. This is the desired behavior.

**Alternative considered**: Using `zed --reuse "$wt_path"` — rejected because `--reuse` replaces the workspace in an existing window (potentially losing the user's workspace state), while the no-flag behavior is more intuitive.

### 3. Add pyobjc-framework-Cocoa dependency for macOS

**Decision**: Add `pyobjc-framework-Cocoa>=9.0; sys_platform == 'darwin'` to `pyproject.toml` dependencies.

The always-on-top feature in `main_window.py` uses `import objc` to access native NSWindow APIs (setLevel_, setCollectionBehavior_, orderFrontRegardless). Without pyobjc installed, `_get_ns_window()` silently returns `None` and all macOS-specific window management is skipped, leaving only the Qt `WindowStaysOnTopHint` which is insufficient on macOS.

**Additional fix**: Replace the bare `except Exception: pass` in `_get_ns_window()` with a logged warning so the failure is visible.

### 4. macOS fullscreen Spaces — known platform limitation

Investigated `FullScreenAuxiliary` (1 << 8) and `CanJoinAllApplications` (1 << 18) flags to make the Control Center visible when other apps enter macOS fullscreen mode. Neither worked — macOS fullscreen Spaces are designed to be isolated; no window level or collection behavior flag can penetrate them from a different process. Accepted as platform limitation.

## Risks / Trade-offs

- **[Shell rc modification]** → Writing to `~/.zshrc` or `~/.bashrc` is a mildly invasive action. Mitigated by: using a clear marker comment for easy identification/removal, only appending (never modifying existing content), and checking idempotency before writing.
- **[Zed flag removal]** → Minimal risk. The no-flag behavior is well-documented and is the default Zed behavior. Users who specifically want new windows can still use `zed -n` manually.
- **[pyobjc dependency]** → Adds a macOS-only dependency (~30MB). Mitigated by: platform marker ensures it's only installed on macOS. The package is the official Python-ObjC bridge maintained by the PSF.
