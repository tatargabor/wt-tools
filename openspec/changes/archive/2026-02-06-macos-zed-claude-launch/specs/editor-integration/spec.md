## MODIFIED Requirements

### Requirement: Editor-Specific Worktree Opening
The system SHALL open worktrees in the configured editor with appropriate Claude Code setup.

#### Scenario: Open worktree in Zed (Linux)
- **WHEN** Zed is the configured editor
- **AND** the platform is Linux
- **AND** user runs `wt-work <change-id>`
- **THEN** Zed opens the worktree directory
- **AND** Claude Code terminal is launched via Ctrl+Shift+L keystroke using xdotool

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

### Requirement: Editor-Specific Window Focus
The system SHALL focus the correct editor window for a worktree.

#### Scenario: Focus Zed window (Linux)
- **WHEN** Zed is the configured editor
- **AND** the platform is Linux
- **AND** user runs `wt-focus <change-id>`
- **THEN** xdotool searches for windows with class "Zed"
- **AND** the window containing the worktree folder name is focused

#### Scenario: Focus Zed window (macOS)
- **WHEN** Zed is the configured editor
- **AND** the platform is macOS
- **AND** user runs `wt-focus <change-id>`
- **THEN** osascript activates the Zed window containing the worktree

#### Scenario: Focus VS Code window
- **WHEN** VS Code is the configured editor
- **AND** user runs `wt-focus <change-id>`
- **THEN** the VS Code window containing the worktree folder name is focused

#### Scenario: Focus Cursor window
- **WHEN** Cursor is the configured editor
- **AND** user runs `wt-focus <change-id>`
- **THEN** the Cursor window containing the worktree folder name is focused

#### Scenario: Focus Windsurf window
- **WHEN** Windsurf is the configured editor
- **AND** user runs `wt-focus <change-id>`
- **THEN** the Windsurf window containing the worktree folder name is focused
