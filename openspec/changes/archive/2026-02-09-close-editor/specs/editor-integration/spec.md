## ADDED Requirements

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
