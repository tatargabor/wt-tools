## MODIFIED Requirements

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
- **GIVEN** no plugins are installed
- **WHEN** the worktree context menu is displayed
- **THEN** no plugin submenus appear
- **AND** no errors occur

### Requirement: Structured Context Menu Sections
The system SHALL organize context menus with clear visual sections.

#### Scenario: Row context menu sections
- **GIVEN** the user right-clicks on a worktree row
- **WHEN** the context menu appears
- **THEN** actions are grouped: Worktree Actions, Create, Git, Ralph, Project, Config
- **AND** separators divide the groups
