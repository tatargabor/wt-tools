## MODIFIED Requirements

### Requirement: Agent Detection
The system SHALL detect Claude agent processes associated with worktrees.

#### Scenario: Detect running agent
- **GIVEN** a Claude process is running in a worktree directory
- **WHEN** wt-status checks that worktree
- **THEN** the agent status shows "running"

#### Scenario: Detect compacting agent
- **GIVEN** a Claude process is summarizing context (compacting)
- **WHEN** wt-status checks that worktree
- **THEN** the agent status shows "compacting" with purple indicator

#### Scenario: Detect waiting agent
- **GIVEN** a Claude process is sleeping (waiting for input or processing)
- **WHEN** wt-status checks that worktree
- **THEN** the agent status shows "waiting"

#### Scenario: No agent
- **GIVEN** no Claude process exists for a worktree
- **WHEN** wt-status checks that worktree
- **THEN** the agent status shows "idle"

#### Scenario: Show skill name instead of PID
- **GIVEN** an agent is running with a registered skill
- **WHEN** wt-status outputs the status
- **THEN** the status shows skill name (e.g., "waiting (opsx:explore)") instead of PID

## ADDED Requirements

### Requirement: Active Filter Toggle
The GUI SHALL provide a toggle to show only worktrees with open editor windows.

#### Scenario: Toggle button in toolbar
- **GIVEN** the Control Center is running
- **WHEN** the toolbar is displayed
- **THEN** an "Active only" toggle button appears next to the refresh button

#### Scenario: Activate filter
- **GIVEN** the filter is inactive (showing all worktrees)
- **WHEN** the user clicks the active filter button
- **THEN** only worktrees with an open editor window are displayed
- **AND** the button appears highlighted/active

#### Scenario: Deactivate filter
- **GIVEN** the filter is active
- **WHEN** the user clicks the active filter button again
- **THEN** all worktrees are displayed
- **AND** the button returns to normal appearance

#### Scenario: Filter hides project headers
- **GIVEN** the filter is active
- **WHEN** a project has no worktrees with open editors
- **THEN** the project header row is also hidden

#### Scenario: Filter persists across refresh
- **GIVEN** the filter is active
- **WHEN** the worktree list refreshes
- **THEN** the filter remains active and only filtered rows are shown
