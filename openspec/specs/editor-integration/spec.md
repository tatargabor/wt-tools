# editor-integration Specification

## Purpose
TBD - created by archiving change add-multi-editor-support. Update Purpose after archive.
## Requirements
### Requirement: Multi-Editor Support
The system SHALL support multiple code editors for opening worktrees with Claude Code integration.

#### Scenario: List supported editors
- **WHEN** user runs `wt-config editor list`
- **THEN** all supported editors are displayed with availability status
- **AND** each entry shows: name, CLI command, detected (yes/no)

#### Scenario: Detect available editors
- **WHEN** wt-tools starts or `wt-config editor list` is run
- **THEN** the system detects which editors are installed
- **AND** detection checks standard installation paths per platform

#### Scenario: Set preferred editor
- **WHEN** user runs `wt-config editor set vscode`
- **THEN** VS Code becomes the default editor
- **AND** preference is stored in `~/.config/wt-tools/config.json`

#### Scenario: Invalid editor name
- **WHEN** user runs `wt-config editor set unknown`
- **THEN** an error is shown listing valid editor names

#### Scenario: Show current editor
- **WHEN** user runs `wt-config editor show`
- **THEN** the currently configured editor name is displayed
- **AND** if not configured, shows "auto (detected: <name>)"

### Requirement: Editor-Specific Worktree Opening
The system SHALL open worktrees in the configured editor with appropriate Claude Code setup.

#### Scenario: Open worktree in Zed (Linux)
- **WHEN** Zed is the configured editor
- **AND** the platform is Linux
- **AND** user runs `wt-work <change-id>`
- **THEN** Zed opens the worktree directory
- **AND** Claude Code terminal is launched via Ctrl+Shift+L keystroke using xdotool
- **AND** the system SHALL verify the Zed window appeared before sending the keystroke
- **AND** the system SHALL retry keystroke delivery up to 2 times if no claude process is detected within 5 seconds

#### Scenario: Open worktree in Zed (macOS)
- **WHEN** Zed is the configured editor
- **AND** the platform is macOS
- **AND** user runs `wt-work <change-id>`
- **THEN** Zed opens the worktree directory
- **AND** Claude Code terminal is launched via Ctrl+Shift+L keystroke using osascript

#### Scenario: Open worktree in Zed (no automation tool)
- **WHEN** Zed is the configured editor
- **AND** neither xdotool nor osascript is available
- **AND** user runs `wt-work <change-id>`
- **THEN** Zed opens the worktree directory
- **AND** user is informed to press Ctrl+Shift+L manually to start Claude Code

#### Scenario: Open worktree in VS Code
- **WHEN** VS Code is the configured editor
- **AND** user runs `wt-work <change-id>`
- **THEN** VS Code opens the worktree directory via `code <path>`
- **AND** user is informed to use Claude Code extension or run `claude` in terminal

#### Scenario: Open worktree in Cursor
- **WHEN** Cursor is the configured editor
- **AND** user runs `wt-work <change-id>`
- **THEN** Cursor opens the worktree directory via `cursor <path>`
- **AND** user is informed to use Claude Code extension or run `claude` in terminal

#### Scenario: Open worktree in Windsurf
- **WHEN** Windsurf is the configured editor
- **AND** user runs `wt-work <change-id>`
- **THEN** Windsurf opens the worktree directory via `windsurf <path>`
- **AND** user is informed to use Cascade or run `claude` in terminal

#### Scenario: Editor not installed
- **WHEN** the configured editor is not found
- **THEN** an error is shown with installation instructions
- **AND** alternative detected editors are suggested

#### Scenario: Skip Claude launch if already running
- **WHEN** `wt-work` detects a claude process already running in the worktree CWD
- **THEN** the keystroke SHALL NOT be sent
- **AND** the existing editor window SHALL be focused instead

### Requirement: Editor-Specific Window Focus
The system SHALL focus the correct editor window for a worktree using platform-appropriate mechanisms.

#### Scenario: Focus editor window on Linux
- **WHEN** the platform is Linux
- **AND** user triggers focus for a worktree (via GUI or `wt-focus <change-id>`)
- **THEN** xdotool searches for windows with the editor's window class
- **AND** the window containing the worktree folder name in its title is activated

#### Scenario: Focus editor window on macOS
- **WHEN** the platform is macOS
- **AND** user triggers focus for a worktree (via GUI or `wt-focus <change-id>`)
- **THEN** AppleScript activates the editor application
- **AND** raises the specific window whose title contains the worktree folder name

#### Scenario: Focus from GUI uses platform abstraction
- **WHEN** user double-clicks a running worktree in the Control Center
- **OR** user selects "Focus" from the context menu
- **THEN** the system uses the Python platform layer (`gui/platform/`) to find and focus the window
- **AND** the system SHALL NOT shell out to `wt-focus` from the GUI

#### Scenario: Focus from CLI on macOS
- **WHEN** user runs `wt-focus <change-id>` on macOS
- **THEN** the script uses `osascript` with AppleScript to find and focus the editor window
- **AND** the script SHALL NOT require `xdotool`

#### Scenario: No matching window found
- **WHEN** no editor window matches the worktree folder name
- **THEN** an error is shown indicating no window was found
- **AND** available editor windows are listed (if possible)

#### Scenario: Accessibility permission denied on macOS
- **WHEN** the system cannot control windows due to missing Accessibility permissions
- **THEN** the error is surfaced to the user with guidance to enable permissions

### Requirement: Editor Window Close
The system SHALL close the editor window for a worktree using platform-appropriate mechanisms.

#### Scenario: Close editor window on Linux
- **WHEN** the platform is Linux
- **AND** user selects "Close Editor" from the worktree context menu
- **THEN** the system finds the editor window matching the worktree folder name using xdotool
- **AND** sends WM_DELETE_WINDOW via `xdotool windowclose` (graceful close)

#### Scenario: Close editor window on macOS
- **WHEN** the platform is macOS
- **AND** user selects "Close Editor" from the worktree context menu
- **THEN** the system finds the editor window matching the worktree folder name
- **AND** closes it via AppleScript

#### Scenario: Close from GUI uses platform abstraction
- **WHEN** user selects "Close Editor" from the worktree context menu
- **THEN** the system SHALL use the Python platform layer (`gui/platform/`) with a `close_window()` method
- **AND** the close method SHALL accept a window ID returned by `find_window_by_title()`

#### Scenario: No editor window found for close
- **WHEN** user selects "Close Editor" but no editor window matches the worktree
- **THEN** the action SHALL be a silent no-op (no error dialog)

#### Scenario: Editor prompts for unsaved changes
- **WHEN** the editor has unsaved changes in the worktree
- **AND** user selects "Close Editor"
- **THEN** the editor's native unsaved-changes dialog SHALL appear
- **AND** the system SHALL NOT force-close the window

### Requirement: Editor Detection Fallback
The system SHALL automatically detect and use an available editor when not configured.

#### Scenario: Auto-detect editor order
- **WHEN** no editor is configured
- **AND** wt-work is run
- **THEN** editors are checked in order: Zed, VS Code, Cursor, Windsurf
- **AND** the first available editor is used

#### Scenario: No editor available
- **WHEN** no supported editor is detected
- **THEN** an error is shown listing all supported editors
- **AND** installation links are provided for each
