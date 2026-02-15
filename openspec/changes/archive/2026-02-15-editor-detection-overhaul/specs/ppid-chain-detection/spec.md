## ADDED Requirements

### Requirement: PPID chain window discovery
The system SHALL discover the editor/terminal window for a Claude agent by walking the agent's parent process chain until a window-owning process is found.

#### Scenario: Agent running in Zed on Linux
- **WHEN** a Claude agent with PID N is detected in a worktree
- **AND** the platform is Linux
- **THEN** the system SHALL walk the PPID chain starting from PID N
- **AND** for each ancestor PID, run `xdotool search --pid <ancestor_pid>`
- **AND** stop at the first ancestor that owns an X11 window
- **AND** set `editor_open=true` and `window_id=<found_window_id>`

#### Scenario: Agent running in terminal on Linux
- **WHEN** a Claude agent is running inside kitty/alacritty/gnome-terminal/etc.
- **THEN** the PPID chain walks through: claude → bash → terminal_process
- **AND** `xdotool search --pid <terminal_pid>` finds the terminal window
- **AND** set `editor_open=true` and `window_id=<terminal_window_id>`

#### Scenario: Agent running on macOS
- **WHEN** a Claude agent with PID N is detected on macOS
- **THEN** the system SHALL walk the PPID chain using `ps -o ppid= -p <pid>`
- **AND** for each ancestor PID, check window ownership via AppleScript:
  ```
  tell application "System Events"
    set targetProc to first process whose unix id is <ancestor_pid>
    if (count of windows of targetProc) > 0 then
      return name of targetProc & "|" & (id of first window of targetProc)
    end if
  end tell
  ```
- **AND** stop at the first window-owning ancestor
- **AND** set `editor_open=true`, `window_id=<found>`, `editor_type=<process_name>`
- **AND** each AppleScript call is ~50-100ms; the full chain (3-5 levels) is 150-500ms, acceptable for periodic status refresh

#### Scenario: Chain reaches init (PID 1) with no window
- **WHEN** the PPID chain reaches PID 1 without finding a window
- **AND** the agent has a TTY (not "?")
- **THEN** `editor_open` SHALL be set to true (remote/tmux session)
- **AND** `window_id` SHALL be null (no window to focus)

#### Scenario: True orphan agent
- **WHEN** the PPID chain reaches PID 1 without finding a window
- **AND** the agent has no TTY (TTY == "?")
- **THEN** `editor_open` SHALL be set to false
- **AND** `window_id` SHALL be null

#### Scenario: Chain depth limit
- **WHEN** the PPID chain exceeds 20 levels without finding a window
- **THEN** the system SHALL stop walking and treat it as no window found

#### Scenario: No agent running
- **WHEN** a worktree has no Claude agent running
- **THEN** the PPID chain detection SHALL NOT run
- **AND** `editor_open` SHALL be false
- **AND** `window_id` SHALL be null

### Requirement: Window ID in wt-status JSON output
The system SHALL include the discovered window ID in the wt-status JSON output for each worktree.

#### Scenario: wt-status JSON with window_id
- **WHEN** `wt-status --json` is run
- **AND** a worktree has a running agent with a discovered window
- **THEN** the worktree JSON SHALL include `"window_id": "<id>"` field
- **AND** the worktree JSON SHALL include `"editor_type": "<process_name>"` field

#### Scenario: wt-status JSON without window_id
- **WHEN** `wt-status --json` is run
- **AND** a worktree has no agent or no window was discovered
- **THEN** the worktree JSON SHALL include `"window_id": null`
- **AND** `"editor_type": null`

### Requirement: PPID chain implementation in Python platform layer
The GUI platform layer SHALL provide PPID chain walking for direct use by the Control Center.

#### Scenario: Linux platform find_window_by_pid
- **WHEN** `gui/platform/linux.py` `find_window_by_pid(agent_pid)` is called
- **THEN** it SHALL walk the PPID chain using `/proc/<pid>/stat` or `ps -o ppid=`
- **AND** for each ancestor, try `xdotool search --pid <pid>`
- **AND** return `(window_id, process_name)` tuple or `(None, None)`

#### Scenario: macOS platform find_window_by_pid
- **WHEN** `gui/platform/macos.py` `find_window_by_pid(agent_pid)` is called
- **THEN** it SHALL walk the PPID chain using `ps -o ppid= -p <pid>`
- **AND** for each ancestor, check for window ownership via AppleScript (`tell application "System Events" to get first process whose unix id is <pid>`, check window count)
- **AND** return `(window_id, process_name)` tuple or `(None, None)`
