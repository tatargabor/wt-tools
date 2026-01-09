# team-sync Specification Delta

## MODIFIED Requirements

### Requirement: Team Worktrees Display

The GUI SHALL display team worktrees with selection, tooltips, and read-only context menu.

#### Scenario: Team rows not interactive

**REMOVED** - Replaced by new interactive scenarios below.

#### Scenario: Team row selection

- **GIVEN** team worktrees are displayed
- **WHEN** the user clicks on a team row
- **THEN** the row is selected (highlighted)
- **AND** no action is triggered (read-only)

#### Scenario: Team row tooltip

- **GIVEN** team worktrees are displayed
- **WHEN** the user hovers over a team row
- **THEN** a tooltip shows:
  - Full member name (display_name)
  - Change ID
  - Agent status
  - Last seen (relative time, e.g., "2 min ago")

#### Scenario: Team row context menu

- **GIVEN** a team row is displayed
- **WHEN** the user right-clicks on the team row
- **THEN** a context menu appears with:
  - "View Details..." (opens detail dialog)
  - "Copy Change ID" (copies to clipboard)
- **AND** no destructive actions are available

#### Scenario: Team filter toggle (MODIFIED)

- **GIVEN** the Control Center is displayed with team sync enabled
- **WHEN** the user clicks the filter button
- **THEN** the filter cycles through states:
  - All Team (👥): shows all team members' worktrees
  - My Machines (👤): shows only current user's worktrees on other machines
  - Hide Team: hides all team worktrees

#### Scenario: My machines filter

- **GIVEN** current user is "gabor" on hostname "workstation"
- **AND** team member "gabor@laptop" exists with worktrees
- **WHEN** "My Machines" filter is active
- **THEN** only "gabor@laptop" worktrees are shown
- **AND** other team members' worktrees are hidden

#### Scenario: Identify same user different machine

- **GIVEN** member JSON contains `user` and `hostname` fields
- **WHEN** filtering for "My Machines"
- **THEN** members with same `user` but different `hostname` are included
- **AND** members with different `user` are excluded

## ADDED Requirements

### Requirement: Team Worktree Details Dialog

The system SHALL provide a dialog to view team worktree details.

#### Scenario: Open details dialog

- **GIVEN** a team row is selected
- **WHEN** the user clicks "View Details..." from context menu
- **THEN** a dialog opens showing:
  - Member name and hostname
  - Change ID
  - Agent status
  - Last seen timestamp
  - Last activity description (if available)

#### Scenario: Close details dialog

- **GIVEN** the details dialog is open
- **WHEN** the user clicks "Close" or presses Escape
- **THEN** the dialog closes
- **AND** no changes are made
