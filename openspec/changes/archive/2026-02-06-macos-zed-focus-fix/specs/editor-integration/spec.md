## MODIFIED Requirements

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
