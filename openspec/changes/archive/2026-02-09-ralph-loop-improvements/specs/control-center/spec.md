## MODIFIED Requirements

### Requirement: Ralph Loop Integration
The GUI SHALL integrate with Ralph Loop for autonomous Claude sessions.

#### Scenario: Ralph settings tab
- **GIVEN** the settings dialog is open
- **WHEN** the user views the "Ralph" tab
- **THEN** the following settings are available:
  - Terminal fullscreen (checkbox)
  - Default max iterations (spinbox)
  - Default stall threshold (spinbox, default 2, range 1-10)
  - Default iteration timeout minutes (spinbox, default 45, range 5-120)

#### Scenario: Start Loop dialog defaults
- **GIVEN** the user opens the Start Loop dialog for a worktree
- **WHEN** a `tasks.md` exists in the change directory
- **THEN** the done criteria combo SHALL default to "tasks"
- **AND** a "tasks.md found" indicator SHALL be visible

#### Scenario: Start Loop dialog manual warning
- **GIVEN** the Start Loop dialog is open
- **WHEN** the user selects "manual" done criteria
- **THEN** an inline warning SHALL appear: "Loop won't auto-stop. Use 'Stop Loop' to end."

#### Scenario: Start Loop dialog stall threshold
- **GIVEN** the Start Loop dialog is open
- **THEN** a stall threshold spinner SHALL be visible (default from settings, range 1-10)

#### Scenario: Ralph status indicator
- **GIVEN** a worktree has an active Ralph loop
- **WHEN** displayed in the table
- **THEN** an "R" button shows with color indicating status (green=running, red=stuck, orange=stalled, blue=done, gray=stopped)

#### Scenario: Ralph status tooltip details
- **GIVEN** the user hovers over the Ralph "R" button
- **THEN** the tooltip SHALL show:
  - Status (running/stuck/stalled/done/stopped)
  - Current iteration / max iterations
  - Elapsed time since loop started
  - Elapsed time of current iteration
  - Task description (first 60 chars)
  - Last commit timestamp (if any)

#### Scenario: View Ralph terminal
- **GIVEN** a Ralph loop is running
- **WHEN** user clicks "View Terminal" from context menu
- **THEN** the Ralph terminal window is focused

#### Scenario: View Ralph log
- **GIVEN** a Ralph loop has finished (terminal closed)
- **WHEN** user clicks "View Log" from context menu
- **THEN** the Ralph log file (.claude/ralph-loop.log) opens

#### Scenario: Ralph terminal logging
- **GIVEN** a Ralph loop is started
- **WHEN** the loop runs
- **THEN** all output is logged to .claude/ralph-loop.log

#### Scenario: Stop Loop records final state
- **GIVEN** a Ralph loop is running
- **WHEN** user clicks "Stop Loop" from the context menu
- **THEN** the loop-state.json SHALL be updated to "stopped"
- **AND** the current iteration SHALL have an `ended` timestamp recorded
- **AND** the terminal process SHALL be sent SIGTERM (allowing trap to fire)
