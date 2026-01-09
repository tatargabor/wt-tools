# menu-system Specification

## Requirements

### Requirement: Three-Level Menu Organization
The system SHALL organize menu items into three levels: Global, Project, and Worktree.

#### Scenario: Global actions in main menu
- **GIVEN** the user opens the main menu (hamburger button)
- **WHEN** the menu is displayed
- **THEN** global actions (Settings, Refresh, Restart, Quit) are shown at the top
- **AND** project-specific actions are grouped under a "Project" section

#### Scenario: Project actions require project context
- **GIVEN** a worktree is selected
- **WHEN** the user opens the context menu
- **THEN** project-level actions (Team Settings, Team Chat) are available
- **AND** they apply to the project of the selected worktree

#### Scenario: Worktree actions in row context menu
- **GIVEN** the user right-clicks on a worktree row
- **WHEN** the context menu is displayed
- **THEN** worktree-specific actions appear first (Focus, Terminal, File Manager)
- **AND** Git operations are grouped in a submenu
- **AND** Ralph Loop operations are grouped in a submenu

### Requirement: Consistent Menu Icons
The system SHALL use plain text labels (no emoji prefixes) across all menus for consistency.

#### Scenario: Icons in context menus
- **GIVEN** the user opens any context menu
- **WHEN** the menu is displayed
- **THEN** menu items use plain text labels without emoji prefixes

#### Scenario: Icons in tray menu
- **GIVEN** the user opens the tray icon menu
- **WHEN** the menu is displayed
- **THEN** menu items use plain text labels without emoji prefixes
- **AND** the style matches the main menu and context menus

### Requirement: Structured Context Menu Sections
The system SHALL organize context menus with clear visual sections.

#### Scenario: Row context menu sections
- **GIVEN** the user right-clicks on a worktree row
- **WHEN** the context menu appears
- **THEN** actions are grouped: Worktree Actions, Create, Git, Ralph, Project, Config
- **AND** separators divide the groups
- **AND** the Worktree Actions group SHALL include "Close Editor" directly after "Focus Window"
- **AND** the Worktree submenu SHALL contain only "Close" (no "Push Branch")

#### Scenario: Empty area context menu
- **GIVEN** the user right-clicks on an empty area
- **WHEN** the context menu appears
- **THEN** only global and create actions are shown
- **AND** worktree-specific actions are not available

### Requirement: Enhanced Tray Menu
The system SHALL provide quick access to common actions from the tray.

#### Scenario: Tray menu includes settings
- **GIVEN** the user right-clicks on the tray icon
- **WHEN** the tray menu is displayed
- **THEN** Settings action is available
- **AND** New Worktree action is available
