## ADDED Requirements

### Requirement: Terminal vs IDE Agent Display
The system SHALL visually distinguish agents running in the configured IDE from agents running in a plain terminal.

#### Scenario: Agent in configured IDE shows standard waiting
- **WHEN** a worktree has an agent with status "waiting"
- **AND** the `editor_type` from wt-status matches a known IDE process name (zed, code, cursor, windsurf)
- **THEN** the agent SHALL be displayed with the standard orange `⚡ waiting` icon and colors

#### Scenario: Agent in terminal shows dimmed waiting
- **WHEN** a worktree has an agent with status "waiting"
- **AND** the `editor_type` from wt-status is truthy but does NOT match a known IDE process name
- **THEN** the agent SHALL be displayed with dimmed/muted colors (reusing idle palette)
- **AND** the status text SHALL still read "waiting"

#### Scenario: Running agent always shows green regardless of editor type
- **WHEN** a worktree has an agent with status "running"
- **THEN** the agent SHALL always be displayed with the standard green running indicator
- **AND** the display SHALL NOT be affected by `editor_type`

#### Scenario: No editor_type falls back to standard display
- **WHEN** a worktree has an agent
- **AND** the `editor_type` is null or empty
- **THEN** the standard status display SHALL be used (no dimming)

### Requirement: Focus Action Editor-Type Awareness
The system SHALL optimize the focus action based on the worktree's editor type.

#### Scenario: Focus worktree with IDE editor type
- **WHEN** user triggers focus for a worktree
- **AND** the `editor_type` matches a known IDE process name
- **THEN** the system SHALL first search by window title with the configured app name
- **AND** fall back to `window_id` if title search fails

#### Scenario: Focus worktree with terminal editor type
- **WHEN** user triggers focus for a worktree
- **AND** the `editor_type` is truthy but NOT a known IDE process name
- **AND** a `window_id` is available
- **THEN** the system SHALL skip the title-based IDE search
- **AND** focus the window directly using `window_id`

#### Scenario: Focus worktree with no window
- **WHEN** user triggers focus for a worktree
- **AND** no `window_id` is available
- **AND** no title-based search finds a window
- **THEN** the system SHALL open the worktree in the configured editor
