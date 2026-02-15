## ADDED Requirements

### Requirement: Terminal emulator support
The system SHALL support terminal emulators as editor types for users who run Claude Code without an IDE.

#### Scenario: Supported terminal emulators
- **WHEN** the system lists supported editors
- **THEN** the following terminal emulators SHALL be included: kitty, alacritty, wezterm, gnome-terminal, konsole, iterm2 (macOS), terminal-app (macOS)
- **AND** each SHALL have a type of "terminal" (vs "ide" for Zed/VSCode/etc.)

#### Scenario: Open worktree in kitty
- **WHEN** kitty is the configured editor
- **AND** user runs `wt-work <change-id>`
- **THEN** kitty opens a new window at the worktree directory via `kitty --directory <path>`
- **AND** user is informed: "Start Claude Code: run `claude` in the terminal"

#### Scenario: Open worktree in alacritty
- **WHEN** alacritty is the configured editor
- **AND** user runs `wt-work <change-id>`
- **THEN** alacritty opens at the worktree directory via `alacritty --working-directory <path>`

#### Scenario: Open worktree in wezterm
- **WHEN** wezterm is the configured editor
- **AND** user runs `wt-work <change-id>`
- **THEN** wezterm opens at the worktree directory via `wezterm start --cwd <path>`

#### Scenario: Open worktree in gnome-terminal
- **WHEN** gnome-terminal is the configured editor
- **AND** user runs `wt-work <change-id>`
- **THEN** gnome-terminal opens at the worktree directory via `gnome-terminal -- bash -c "cd '<path>' && exec bash"`

#### Scenario: Open worktree in konsole
- **WHEN** konsole is the configured editor
- **AND** user runs `wt-work <change-id>`
- **THEN** konsole opens at the worktree directory via `konsole --workdir <path>`

#### Scenario: Open worktree in iTerm2 (macOS)
- **WHEN** iterm2 is the configured editor
- **AND** the platform is macOS
- **THEN** iTerm2 opens a new tab at the worktree directory via AppleScript

#### Scenario: Open worktree in Terminal.app (macOS)
- **WHEN** terminal-app is the configured editor
- **AND** the platform is macOS
- **THEN** Terminal.app opens a new tab at the worktree directory via `open -a Terminal <path>`

#### Scenario: Auto-detect terminal editors
- **WHEN** no editor is configured (auto mode)
- **THEN** IDEs SHALL be checked first (Zed, VSCode, Cursor, Windsurf)
- **AND** if no IDE is found, terminal emulators SHALL be checked (kitty, alacritty, wezterm, gnome-terminal, konsole)
- **AND** the first available SHALL be used

### Requirement: Editor selection in install script
The system SHALL prompt the user to choose an editor during installation.

#### Scenario: Install prompts for editor
- **WHEN** `install.sh` runs
- **THEN** it SHALL detect available editors (IDEs and terminals)
- **AND** present a numbered list to the user
- **AND** highlight detected/installed editors
- **AND** save the choice to config.json

#### Scenario: Install with no editor detected
- **WHEN** `install.sh` runs and no supported editor is detected
- **THEN** it SHALL warn the user
- **AND** allow them to type a custom editor name or proceed with "auto"

### Requirement: Editor selection in Settings dialog
The system SHALL allow changing the editor in the Control Center Settings dialog.

#### Scenario: Settings shows editor dropdown
- **WHEN** user opens the Settings dialog
- **THEN** an "Editor" dropdown SHALL be displayed
- **AND** it SHALL list all supported editors grouped by type (IDE / Terminal)
- **AND** the current config value SHALL be pre-selected
- **AND** changing the selection SHALL update config.json immediately

## MODIFIED Requirements

### Requirement: Editor-Specific Worktree Opening
The system SHALL open worktrees in the configured editor without auto-launching Claude Code.

#### Scenario: Open worktree in Zed (Linux)
- **WHEN** Zed is the configured editor
- **AND** the platform is Linux
- **AND** user runs `wt-work <change-id>`
- **THEN** Zed opens the worktree directory via `zed <path>` (without -n flag)
- **AND** if the project is already open, the existing window SHALL be focused
- **AND** user is informed: "Start Claude Code: Ctrl+Shift+L"

#### Scenario: Open worktree in Zed (macOS)
- **WHEN** Zed is the configured editor
- **AND** the platform is macOS
- **AND** user runs `wt-work <change-id>`
- **THEN** Zed opens the worktree directory via `zed <path>`
- **AND** user is informed: "Start Claude Code: Ctrl+Shift+L"

#### Scenario: Open worktree in VS Code
- **WHEN** VS Code is the configured editor
- **AND** user runs `wt-work <change-id>`
- **THEN** VS Code opens the worktree directory via `code <path>`
- **AND** user is informed: "Start Claude Code: Ctrl+Shift+L or click Spark icon"

#### Scenario: Open worktree in Cursor
- **WHEN** Cursor is the configured editor
- **AND** user runs `wt-work <change-id>`
- **THEN** Cursor opens the worktree directory via `cursor <path>`
- **AND** user is informed: "Start Claude Code: Ctrl+L"

#### Scenario: Open worktree in Windsurf
- **WHEN** Windsurf is the configured editor
- **AND** user runs `wt-work <change-id>`
- **THEN** Windsurf opens the worktree directory via `windsurf <path>`
- **AND** user is informed: "Start Claude Code: use Cascade or run `claude` in terminal"

#### Scenario: Editor not installed
- **WHEN** the configured editor is not found
- **THEN** an error is shown with installation instructions
- **AND** alternative detected editors are suggested

#### Scenario: Skip Claude launch if already running
- **WHEN** `wt-work` is run for a worktree that already has a Claude agent
- **THEN** the editor SHALL still be opened/focused
- **AND** no additional Claude launch SHALL occur
- **AND** user is informed that Claude is already running

## REMOVED Requirements

### Requirement: Editor-Specific Worktree Opening — Keystroke injection scenarios
**Reason**: Keystroke injection (xdotool key / osascript keystroke) for auto-launching Claude Code is removed. It was fragile (sleep/retry, window search, race conditions) and incompatible with terminal-based workflows.
**Migration**: Users start Claude Code manually via keyboard shortcut or terminal command. The system shows the appropriate shortcut as a tip.

### Requirement: Editor-Specific Window Focus — Title-based matching scenarios
**Reason**: Window focus via title matching (xdotool --name / --class + title contains) is replaced by PPID chain detection which returns window_id directly, or editor CLI fallback.
**Migration**: `on_focus()` uses window_id from wt-status JSON data. If no window_id, falls back to editor CLI (`zed <path>`, `code <path>`, etc.) which handles focus-or-open automatically.

## MODIFIED Requirements

### Requirement: Editor-Specific Window Focus
The system SHALL focus the correct editor window for a worktree using window_id from PPID chain detection or editor CLI fallback.

#### Scenario: Focus with window_id available (Linux)
- **WHEN** user triggers focus for a worktree
- **AND** the worktree status includes a `window_id`
- **AND** the platform is Linux
- **THEN** the system SHALL run `xdotool windowactivate <window_id>`

#### Scenario: Focus with window_id available (macOS)
- **WHEN** user triggers focus for a worktree
- **AND** the worktree status includes a `window_id`
- **AND** the platform is macOS
- **THEN** the system SHALL use AppleScript to raise the window by ID

#### Scenario: Focus without window_id (fallback)
- **WHEN** user triggers focus for a worktree
- **AND** no `window_id` is available (no agent running)
- **THEN** the system SHALL use the editor CLI to open/focus: `zed <path>`, `code <path>`, etc.
- **AND** if the editor is a terminal type, SHALL use terminal-specific directory flag

#### Scenario: Focus from GUI uses window_id
- **WHEN** user double-clicks a worktree in the Control Center
- **OR** user selects "Focus" from the context menu
- **THEN** the system SHALL use `window_id` from the cached worktree status data
- **AND** SHALL NOT perform a separate window search

### Requirement: Editor Detection Fallback
The system SHALL automatically detect and use an available editor when not configured.

#### Scenario: Auto-detect editor order
- **WHEN** no editor is configured
- **AND** wt-work is run
- **THEN** IDEs are checked first in order: Zed, VS Code, Cursor, Windsurf
- **AND** then terminals: kitty, alacritty, wezterm, gnome-terminal, konsole
- **AND** the first available is used

#### Scenario: No editor available
- **WHEN** no supported editor is detected
- **THEN** an error is shown listing all supported editors
- **AND** installation links are provided for each

### Requirement: wt-focus simplification
The `bin/wt-focus` script SHALL be simplified from its current 460-line class+title window search to a thin wrapper around editor CLI calls.

#### Scenario: wt-focus opens/focuses editor via CLI
- **WHEN** `wt-focus <change-id>` is run
- **THEN** the system SHALL resolve the worktree path for the change
- **AND** call the configured editor CLI: `zed <path>`, `code <path>`, `kitty --directory <path>`, etc.
- **AND** the editor CLI handles focus-or-open automatically (no window search needed)

#### Scenario: wt-focus with no editor configured
- **WHEN** `wt-focus <change-id>` is run
- **AND** no editor is configured
- **THEN** the auto-detect logic SHALL be used (same as wt-work)

## REMOVED Requirements

### Requirement: wt-focus — Class and title-based window enumeration
**Reason**: The 460-line `bin/wt-focus` script performs complex X11 window class + title matching with fallbacks. This is replaced by simple editor CLI calls which handle focus-or-open natively.
**Migration**: `wt-focus` becomes a thin wrapper: resolve worktree path → call editor CLI. The GUI never calls wt-focus (uses window_id from wt-status directly).
