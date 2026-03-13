## MODIFIED Requirements

### Requirement: Editor-Specific Worktree Opening
The system SHALL open worktrees in the configured editor and display a Claude Code startup tip.

#### Scenario: Open worktree in Zed (Linux)
- **WHEN** Zed is the configured editor
- **AND** the platform is Linux
- **AND** user runs `wt-work <change-id>`
- **THEN** Zed opens the worktree directory
- **AND** user is informed to press Ctrl+Shift+L to start Claude Code

#### Scenario: Open worktree in Zed (macOS)
- **WHEN** Zed is the configured editor
- **AND** the platform is macOS
- **AND** user runs `wt-work <change-id>`
- **THEN** Zed opens the worktree directory
- **AND** user is informed to press Ctrl+Shift+L to start Claude Code

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

#### Scenario: Auto-create worktree if missing
- **WHEN** user runs `wt-work <change-id>` and no worktree exists for that change
- **AND** `--no-create` flag is NOT set
- **THEN** the system SHALL create the worktree automatically before opening

#### Scenario: Main branch opening
- **WHEN** user runs `wt-work` with the main branch name as change-id
- **THEN** the system SHALL open the main repo directory instead of a worktree

### Requirement: Editor-Specific Window Focus
The system SHALL focus the editor window for a worktree by delegating to the editor's CLI.

#### Scenario: Focus editor window via CLI
- **WHEN** user runs `wt-focus <change-id>`
- **THEN** the system SHALL call the configured editor's CLI open command for the worktree path
- **AND** the editor SHALL focus the existing window if already open, or open a new one

#### Scenario: No matching window found
- **WHEN** no editor window matches the worktree folder name
- **THEN** the system SHALL open a new editor window for the worktree

## REMOVED Requirements

### Requirement: Keystroke automation (xdotool/osascript)
**Reason**: Never implemented. The code delegates to editor CLI and prints manual Claude Code startup tips.
**Migration**: Users start Claude Code manually via keyboard shortcut or terminal command as shown in the startup tip.

### Requirement: WM_CLASS window filtering
**Reason**: Never implemented. Window focus uses editor CLI delegation, not platform-level window management.
**Migration**: Editor CLI handles window focus natively.

### Requirement: Accessibility permission handling
**Reason**: Never implemented. No platform-level window management is used.
**Migration**: Not needed — editor CLI does not require accessibility permissions.
