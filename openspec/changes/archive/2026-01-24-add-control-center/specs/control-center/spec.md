# Control Center Capability

## ADDED Requirements

### Requirement: Status Command
The system SHALL provide a `wt-status` command that displays worktree and agent status.

#### Scenario: List all worktrees with status
Given multiple worktrees exist across projects
When the user runs `wt-status`
Then each worktree is shown with:
  - Project name
  - Change ID
  - Agent status (running/waiting/idle/done)
  - Last activity time

#### Scenario: JSON output
Given worktrees exist
When the user runs `wt-status --json`
Then output is valid JSON with worktree details and summary

#### Scenario: Compact output
Given worktrees exist
When the user runs `wt-status --compact`
Then output is a single line summary suitable for status bars

### Requirement: Agent Detection
The system SHALL detect Claude agent processes associated with worktrees.

#### Scenario: Detect running agent
Given a Claude process is running in a worktree directory
When wt-status checks that worktree
Then the agent status shows "running" with PID

#### Scenario: Detect waiting agent
Given a Claude process is sleeping (waiting for input)
When wt-status checks that worktree
Then the agent status shows "waiting"

#### Scenario: No agent
Given no Claude process exists for a worktree
When wt-status checks that worktree
Then the agent status shows "idle"

### Requirement: Window Focus
The system SHALL provide window focus functionality via xdotool.

#### Scenario: Focus worktree window
Given a Zed window is open for a worktree
When the user runs `wt-focus <change-id>`
Then the corresponding Zed window is brought to foreground

#### Scenario: Window not found
Given no Zed window exists for a worktree
When the user runs `wt-focus <change-id>`
Then an error message indicates no window found

### Requirement: Interactive TUI
The system SHALL provide an interactive terminal UI for the control center.

#### Scenario: Launch TUI
Given worktrees exist
When the user runs `wt-control` (or `wt-status --interactive`)
Then an interactive TUI is displayed with worktree list

#### Scenario: Navigate and focus
Given the TUI is running
When the user selects a worktree and presses 'f'
Then that worktree's Zed window is focused

#### Scenario: Start new worktree
Given the TUI is running
When the user presses 'n'
Then prompted to create a new worktree (calls wt-new flow)
