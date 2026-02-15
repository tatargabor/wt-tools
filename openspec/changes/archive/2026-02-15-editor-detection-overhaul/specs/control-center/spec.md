## MODIFIED Requirements

### Requirement: Worktree Focus Action
The Control Center SHALL focus editor/terminal windows using the window_id from wt-status data instead of performing a separate window search.

#### Scenario: Focus with window_id from status
- **WHEN** user double-clicks a running worktree row or selects "Focus" from context menu
- **AND** the worktree status data contains a non-null `window_id`
- **THEN** the system SHALL use the platform layer to activate that window directly
- **AND** on Linux: `xdotool windowactivate <window_id>`
- **AND** on macOS: AppleScript to raise the window

#### Scenario: Focus without window_id (editor CLI fallback)
- **WHEN** user triggers focus for a worktree
- **AND** the worktree status data has `window_id=null`
- **THEN** the system SHALL use the configured editor CLI to open/focus: `zed <path>`, `code <path>`, `kitty --directory <path>`, etc.

#### Scenario: Double-click behavior unchanged
- **WHEN** user double-clicks a worktree row
- **THEN** the needs_attention flag SHALL still be cleared
- **AND** the row background SHALL be reset
- **AND** focus behavior SHALL follow the window_id / CLI fallback logic

## ADDED Requirements

### Requirement: Editor selection in Settings dialog
The Control Center Settings dialog SHALL allow the user to change the editor and Claude permission mode.

#### Scenario: Editor dropdown in Settings
- **WHEN** user opens the Settings dialog
- **THEN** an "Editor" section SHALL be displayed with a dropdown
- **AND** the dropdown SHALL list supported editors grouped: IDEs (Zed, VSCode, Cursor, Windsurf), Terminals (kitty, alacritty, wezterm, gnome-terminal, konsole, iTerm2, Terminal.app), Auto
- **AND** only editors detected as installed SHALL be selectable (others shown as disabled/grayed)
- **AND** the current config value SHALL be pre-selected

#### Scenario: Permission mode in Settings
- **WHEN** user opens the Settings dialog
- **THEN** a "Claude Permission Mode" section SHALL be displayed
- **AND** three radio buttons: "Auto-accept (full autonomy)", "Allowed Tools (selective)", "Plan (interactive)"
- **AND** the current config value SHALL be pre-selected
- **AND** "Plan" option SHALL show a note: "Incompatible with Ralph loop"

#### Scenario: Changing editor in Settings
- **WHEN** user changes the editor dropdown value
- **THEN** config.json SHALL be updated immediately with the new `editor.name` value

#### Scenario: Changing permission mode in Settings
- **WHEN** user changes the permission mode
- **THEN** config.json SHALL be updated immediately with the new `claude.permission_mode` value
- **AND** the change takes effect for future `wt-work` and `wt-loop` invocations (not currently running ones)

### Requirement: Close Editor Action
The Control Center SHALL close editor/terminal windows using the window_id from wt-status data instead of searching by title.

#### Scenario: Close editor with window_id
- **WHEN** user selects "Close Editor" from the context menu
- **AND** the worktree status data contains a non-null `window_id`
- **THEN** the system SHALL close that window directly
- **AND** on Linux: `xdotool windowclose <window_id>`
- **AND** on macOS: AppleScript to close the window

#### Scenario: Close editor without window_id
- **WHEN** user selects "Close Editor" from the context menu
- **AND** the worktree status data has `window_id=null`
- **THEN** the action SHALL be a silent no-op (cannot close what cannot be found)

### Requirement: Ralph Terminal Focus
The Control Center SHALL focus the Ralph loop terminal window using the Ralph loop PID and PPID chain walking instead of window title matching.

#### Scenario: Focus Ralph terminal with running loop
- **WHEN** user selects "Focus Ralph" from the context menu
- **AND** the Ralph loop is running (loop-state.json has PID and status "running")
- **THEN** the system SHALL read the Ralph loop PID from loop-state.json
- **AND** walk the PPID chain from the loop PID to find the terminal window
- **AND** focus that window using the discovered window_id

#### Scenario: Focus Ralph terminal without running loop
- **WHEN** user selects "Focus Ralph" from the context menu
- **AND** no Ralph loop is running
- **THEN** the action SHALL fall back to opening the Ralph log file (if available)
- **OR** show a message that no Ralph loop is active
