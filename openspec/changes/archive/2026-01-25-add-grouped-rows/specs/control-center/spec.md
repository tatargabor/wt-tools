## MODIFIED Requirements

### Requirement: Worktree List Display
The GUI SHALL display worktrees grouped by project with visual separators.

#### Scenario: Project grouping
- **GIVEN** worktrees exist across multiple projects
- **WHEN** the Control Center displays the worktree list
- **THEN** worktrees are grouped by project
- **AND** each group has a header row showing the project name
- **AND** header rows are visually distinct and not selectable

#### Scenario: Sorting within groups
- **GIVEN** multiple worktrees in a project
- **WHEN** displayed in the list
- **THEN** they are sorted alphabetically by change ID
