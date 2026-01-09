## 1. Install script PATH auto-configuration

- [x] 1.1 Add `ensure_path()` function to `install.sh` that detects the shell rc file (`~/.zshrc`, `~/.bashrc`, or `~/.profile`) based on `$SHELL`, checks for the `# WT-TOOLS:PATH` marker, and appends `export PATH="$HOME/.local/bin:$PATH"` if not already present
- [x] 1.2 Replace the warning block in `install_scripts()` (lines 172-178) with a call to `ensure_path()`

## 2. Zed window reuse fix

- [x] 2.1 Remove the `-n` flag from the Zed invocation in `wt-work` — already done in previous change (fix-gui-initial-bugs)

## 3. pyobjc dependency for macOS always-on-top

- [x] 3.1 Add `"pyobjc-framework-Cocoa>=9.0; sys_platform == 'darwin'"` to `dependencies` in `pyproject.toml`
- [x] 3.2 Replace silent `except Exception: pass` in `_get_ns_window()` (`main_window.py`) with a warning print on first failure
- [x] 3.3 Run `pip install -e .` to install the new dependency

## 4. ~~Fullscreen auxiliary behavior for macOS~~ (platform limitation, dropped)

- [x] 4.1 ~~Investigated FullScreenAuxiliary and CanJoinAllApplications flags~~ — neither works, macOS fullscreen Spaces are isolated by design
