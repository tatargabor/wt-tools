## MODIFIED Requirements

### Requirement: GUI shows hook status
The GUI SHALL indicate when a worktree is missing Claude Code hooks and offer a fix action.

#### Scenario: Tooltip shows hooks missing warning
- **WHEN** a worktree row is rendered
- **AND** `hooks_installed` is false
- **THEN** the status cell tooltip SHALL show "Claude hooks not installed\nRight-click → Install Claude Hooks"

#### Scenario: Context menu offers Install Claude Hooks
- **WHEN** user right-clicks a worktree row
- **AND** `hooks_installed` is false
- **THEN** the context menu SHALL include an "Install Claude Hooks" action

#### Scenario: Install Claude Hooks action deploys hooks
- **WHEN** user clicks "Install Claude Hooks" from the context menu
- **THEN** `wt-deploy-hooks` SHALL be called on the worktree path
- **AND** a status refresh SHALL be triggered after deployment

#### Scenario: Context menu hides Install Claude Hooks when not needed
- **WHEN** user right-clicks a worktree row
- **AND** `hooks_installed` is true
- **THEN** the context menu SHALL NOT include "Install Claude Hooks"

### Requirement: Reusable hook deployment script
The `wt-deploy-hooks` script SHALL only accept `--quiet` and `--no-memory` flags. Any other flags SHALL cause an error with usage instructions.

#### Scenario: Invalid flag causes error
- **WHEN** `wt-deploy-hooks --memory /path` is called with an unrecognized flag
- **THEN** the script SHALL exit with error and print usage showing valid flags (`--quiet`, `--no-memory`)
