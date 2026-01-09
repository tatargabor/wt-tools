## MODIFIED Requirements

### Requirement: Structured Context Menu Sections
The system SHALL organize context menus with clear visual sections.

#### Scenario: Row context menu sections
- **GIVEN** the user right-clicks on a worktree row
- **WHEN** the context menu appears
- **THEN** actions are grouped: Worktree Actions, Create, Git, Ralph, Plugins, Project, Config
- **AND** separators divide the groups
- **AND** the Worktree Actions group SHALL include "Close Editor" directly after "Focus Window"

#### Scenario: Empty area context menu
- **GIVEN** the user right-clicks on an empty area
- **WHEN** the context menu appears
- **THEN** only global and create actions are shown
- **AND** worktree-specific actions are not available
