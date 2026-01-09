## MODIFIED Requirements

### Requirement: Installation
The system SHALL provide installation scripts for all supported platforms that install all necessary dependencies.

#### Scenario: Install on Linux/macOS
- **WHEN** user runs `./install.sh`
- **THEN** tool scripts are symlinked to `~/.local/bin/`
- **AND** Claude Code CLI is installed via npm if not present
- **AND** OpenSpec CLI is installed if not present
- **AND** Zed editor installation is offered if not present
- **AND** `~/.local/bin` is automatically added to the user's shell rc file if not already in PATH

#### Scenario: PATH auto-configuration is idempotent
- **WHEN** user runs `./install.sh` multiple times
- **THEN** the PATH export line SHALL be added only once to the shell rc file
- **AND** a marker comment (`# WT-TOOLS:PATH`) SHALL identify the managed line

#### Scenario: Shell rc file detection
- **WHEN** user's default shell is zsh
- **THEN** PATH is added to `~/.zshrc`
- **WHEN** user's default shell is bash
- **THEN** PATH is added to `~/.bashrc`
- **WHEN** user's default shell is neither zsh nor bash
- **THEN** PATH is added to `~/.profile`

#### Scenario: Install on Windows
- **WHEN** user runs `install.ps1` in PowerShell
- **THEN** tool scripts are added to user PATH
- **AND** Claude Code CLI is installed via npm if not present
- **AND** OpenSpec CLI is installed if not present
- **AND** Zed editor installation is offered if not present

#### Scenario: Skip already installed dependencies
- **WHEN** a dependency is already installed
- **THEN** installation is skipped for that dependency
- **AND** user is informed of current version

### Requirement: Editor Integration
The system SHALL open the Zed editor for a specified worktree.

#### Scenario: Open Zed for worktree
- **WHEN** user runs `wt-work <change-id>` with Zed as the active editor
- **THEN** Zed opens the worktree directory without the `-n` (new window) flag
- **AND** if the worktree path is already open in Zed, the existing window SHALL be focused
- **AND** if the worktree path is not open, a new window SHALL be created

#### Scenario: Zed not installed
- **WHEN** user runs `wt-work` and Zed is not found
- **THEN** an informative error message is displayed with installation instructions
