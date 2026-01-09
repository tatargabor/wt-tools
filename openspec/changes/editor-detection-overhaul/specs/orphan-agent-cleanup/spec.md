## MODIFIED Requirements

### Requirement: Editor Window Presence Detection
The system SHALL detect whether an editor/terminal window is associated with a worktree by walking the agent's PPID chain instead of searching by window class/title.

#### Scenario: Editor detection via PPID chain on Linux
- **WHEN** `wt-status` checks a worktree on Linux
- **AND** the worktree has a running Claude agent
- **THEN** `is_editor_open()` SHALL walk the agent's PPID chain
- **AND** for each ancestor PID, check if it owns an X11 window via `xdotool search --pid`
- **AND** return true if a window-owning ancestor is found

#### Scenario: Editor detection via PPID chain on macOS
- **WHEN** `wt-status` checks a worktree on macOS
- **AND** the worktree has a running Claude agent
- **THEN** `is_editor_open()` SHALL walk the agent's PPID chain
- **AND** check if each ancestor owns a macOS window
- **AND** return true if a window-owning ancestor is found

#### Scenario: No agent running
- **WHEN** `wt-status` checks a worktree
- **AND** no Claude agent is running in that worktree
- **THEN** `is_editor_open()` SHALL return false (no PPID chain to walk)

#### Scenario: Agent with TTY but no window (remote session)
- **WHEN** the PPID chain reaches PID 1 without finding a window
- **AND** the agent has a TTY (not "?")
- **THEN** `is_editor_open()` SHALL return true (remote/tmux session presumed interactive)

#### Scenario: Agent without TTY and no window (true orphan)
- **WHEN** the PPID chain reaches PID 1 without finding a window
- **AND** the agent has no TTY (TTY == "?")
- **THEN** `is_editor_open()` SHALL return false

#### Scenario: Editor detection without xdotool on Linux
- **WHEN** `wt-status` checks a worktree on Linux
- **AND** xdotool is NOT available
- **THEN** `is_editor_open()` SHALL fall back to checking agent TTY only
- **AND** return true if the agent has a TTY, false if not

### Requirement: Orphan Agent Automatic Cleanup
The system SHALL automatically terminate Claude agent processes that have no associated editor window and no active Ralph loop.

#### Scenario: Kill orphan waiting agent
- **WHEN** `wt-status` detects an agent with status "waiting" in a worktree
- **AND** PPID chain detection returns `editor_open=false`
- **AND** no Ralph loop is active for that worktree (loop-state.json status is not "running")
- **THEN** the agent process SHALL be sent SIGTERM
- **AND** the agent SHALL NOT appear in the status output

#### Scenario: Preserve agent with Ralph loop
- **WHEN** `wt-status` detects an agent in a worktree with `editor_open=false`
- **AND** a Ralph loop IS active for that worktree
- **THEN** the agent SHALL NOT be killed
- **AND** the agent SHALL appear in the status output normally

#### Scenario: Preserve running agent without editor
- **WHEN** `wt-status` detects an agent with status "running" (session mtime < 10s) in a worktree
- **AND** `editor_open=false`
- **THEN** the agent SHALL NOT be killed (it may be in a transitional state)

#### Scenario: Multiple orphan agents in one worktree
- **WHEN** `wt-status` detects multiple waiting agents in a worktree with `editor_open=false`
- **AND** no Ralph loop is active
- **THEN** ALL waiting agents SHALL be killed

#### Scenario: Cleanup logging
- **WHEN** an orphan agent is killed
- **THEN** a message SHALL be written to stderr with the PID and worktree path
