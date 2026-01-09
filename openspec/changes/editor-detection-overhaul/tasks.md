## 1. Config & Common Infrastructure

- [x] 1.1 Add `claude.permission_mode` field to config.json schema in `wt-common.sh` (get/set helpers, default "auto-accept")
- [x] 1.2 Extend SUPPORTED_EDITORS in `wt-common.sh` with terminal emulators (kitty, alacritty, wezterm, gnome-terminal, konsole, iterm2, terminal-app) using new format: `name:command:type` (type = ide|terminal)
- [x] 1.3 Add helper function `get_claude_permission_flags()` in `wt-common.sh` that reads config and returns the appropriate CLI flags for Claude
- [x] 1.4 Add terminal-specific open-directory commands to `wt-common.sh` (kitty --directory, alacritty --working-directory, wezterm start --cwd, etc.)

## 2. PPID Chain Detection (bash — wt-status)

- [x] 2.1 Implement `find_window_for_agent()` bash function in `wt-status`: walk PPID chain, `xdotool search --pid` at each level (Linux), return window_id + editor_type
- [x] 2.2 Implement macOS equivalent of `find_window_for_agent()` using AppleScript: `tell application "System Events" to get first process whose unix id is <pid>`, check window count, return process name + window id
- [x] 2.3 Replace `is_editor_open()` in `wt-status` to call `find_window_for_agent()` for each agent, fall back to TTY check when no xdotool
- [x] 2.4 Add `window_id` and `editor_type` fields to wt-status JSON output (null when no agent or no window found)

## 3. PPID Chain Detection (Python — GUI platform layer)

- [x] 3.1 Add `find_window_by_pid(agent_pid) -> (window_id, process_name)` to `gui/platform/linux.py` using /proc PPID walking + xdotool search --pid
- [x] 3.2 Add `find_window_by_pid(agent_pid) -> (window_id, process_name)` to `gui/platform/macos.py` using PPID walking + AppleScript/CGWindowList
- [x] 3.3 Add `find_window_by_pid()` abstract method to `gui/platform/base.py`

## 4. GUI Focus & Close Overhaul

- [x] 4.1 Modify `on_focus()` in `handlers.py` to use `window_id` from worktree status data, falling back to editor CLI (`zed <path>`, `code <path>`, etc.)
- [x] 4.2 Modify `on_double_click()` in `handlers.py` to use same window_id / CLI fallback logic
- [x] 4.3 Modify `on_close_editor()` in `handlers.py` to use `window_id` from worktree status data (close via xdotool windowclose / AppleScript), silent no-op if no window_id
- [x] 4.4 Modify Ralph terminal focus (`on_ralph_focus`) to use Ralph loop PID from loop-state.json + PPID chain walking instead of title-based search ("Ralph: {change_id}")
- [x] 4.5 Update `_get_editor_app_name()` to `_get_editor_open_command()` that returns the full CLI command for the configured editor type

## 5. wt-work & wt-focus Simplification

- [x] 5.1 Remove keystroke injection logic from `wt-work` (the ~150 lines of xdotool key / osascript keystroke / sleep/retry)
- [x] 5.2 Fix Zed `-n` flag on Linux: use `zed <path>` (not `zed -n <path>`) to reuse existing window
- [x] 5.3 Add terminal editor open logic: `kitty --directory`, `alacritty --working-directory`, etc. based on editor type
- [x] 5.4 Add Claude shortcut tip output after opening editor (editor-specific: "Ctrl+Shift+L" for Zed, "Ctrl+L" for Cursor, "run `claude`" for terminals)
- [x] 5.5 Use `get_claude_permission_flags()` in tip output to show the correct claude invocation command
- [x] 5.6 Simplify `bin/wt-focus` (460 lines): replace class+title window search with editor CLI call (`zed <path>`, `code <path>`, etc.) — becomes a thin wrapper

## 6. wt-loop Permission Mode

- [x] 6.1 Add `--permission-mode <mode>` flag parsing to `wt-loop`
- [x] 6.2 Replace hardcoded `--dangerously-skip-permissions` with `get_claude_permission_flags()` (using flag override or config default)
- [x] 6.3 Add plan-mode refusal logic: refuse to start with plan mode unless --force given
- [x] 6.4 Update `wt-loop --help` to document the new flag

## 7. wt-new / Install Task Generation

- [x] 7.1 Update `install.sh` Zed tasks.json generation to use permission config (not hardcoded --dangerously-skip-permissions)
- [x] 7.2 Update `wt-new` Zed tasks.json generation to use permission config
- [x] 7.3 Update `wt-new` VSCode tasks.json generation to use permission config
- [x] 7.4 Add editor selection prompt to `install.sh` (detect available editors, numbered list, save to config)
- [x] 7.5 Add permission mode selection prompt to `install.sh` (three options with descriptions, save to config)

## 8. Settings Dialog

- [x] 8.1 Add "Editor" dropdown section to Settings dialog with IDE and Terminal groups
- [x] 8.2 Add "Claude Permission Mode" radio button section to Settings dialog (auto-accept / allowedTools / plan)
- [x] 8.3 Wire up Settings dialog to read/write config.json for both editor and permission mode
- [x] 8.4 Mark uninstalled editors as disabled/grayed in dropdown

## 9. Tests

- [x] 9.1 Unit test: PPID chain walking with mocked /proc tree (test_ppid_chain.py)
- [x] 9.2 Unit test: `get_claude_permission_flags()` returns correct flags for each mode
- [x] 9.3 GUI test: Settings dialog editor dropdown and permission mode radio buttons
- [x] 9.4 GUI test: `on_focus()` uses window_id from status data (mock platform)
- [x] 9.5 GUI test: `on_focus()` falls back to editor CLI when no window_id
- [x] 9.6 Integration test script: `tests/integration/test_editor_detection.sh` — run on real Linux/macOS desktop with live xdotool/editor, tests PPID chain detection, focus, wt-work open
- [x] 9.7 Update existing GUI tests that depend on old editor detection (test_16_focus.py, test_17_orphan_detection.py, test_18_zed_integration.py)
