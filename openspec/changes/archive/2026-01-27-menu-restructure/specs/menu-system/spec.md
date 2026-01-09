## ADDED Requirements

### Requirement: Three-Level Menu Organization
The system SHALL organize menu items into three levels: Global, Project, and Worktree.

#### Scenario: Global actions in main menu
- **GIVEN** the user opens the main menu (hamburger button)
- **WHEN** the menu is displayed
- **THEN** global actions (Settings, Refresh, Restart, Quit) are shown at the top
- **AND** project-specific actions are grouped under a "Project" section
- **AND** plugin actions are grouped under a "Plugins" section

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

### Requirement: Plugin Menu Integration
The system SHALL allow plugins to register menu items at appropriate levels.

#### Scenario: Plugin registers worktree menu items
- **GIVEN** a plugin provides worktree-level menu items
- **WHEN** the worktree context menu is built
- **THEN** plugin items appear in a submenu named after the plugin
- **AND** the submenu only appears when the plugin is available

#### Scenario: Plugin registers project menu items
- **GIVEN** a plugin provides project-level menu items
- **WHEN** the main menu or project submenu is built
- **THEN** plugin items appear in the Plugins section
- **AND** items are grouped by plugin name

#### Scenario: Graceful degradation without plugins
- **GIVEN** JIRA plugin is not installed
- **WHEN** the worktree context menu is displayed
- **THEN** no JIRA submenu appears
- **AND** no errors occur

### Requirement: Consistent Menu Icons
The system SHALL display icons for all menu actions.

#### Scenario: Icons in context menus
- **GIVEN** the user opens any context menu
- **WHEN** the menu is displayed
- **THEN** each action has a Unicode icon prefix
- **AND** icons follow a consistent style (emoji for actions, circles for status)

#### Scenario: Icons in tray menu
- **GIVEN** the user opens the tray icon menu
- **WHEN** the menu is displayed
- **THEN** common actions have recognizable icons

### Requirement: Structured Context Menu Sections
The system SHALL organize context menus with clear visual sections.

#### Scenario: Row context menu sections
- **GIVEN** the user right-clicks on a worktree row
- **WHEN** the context menu appears
- **THEN** actions are grouped: Worktree Actions, Create, Git, Ralph, Plugins, Project, Config
- **AND** separators divide the groups

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
