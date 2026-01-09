## MODIFIED Requirements

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
