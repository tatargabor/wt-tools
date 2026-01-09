## MODIFIED Requirements

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

## REMOVED Requirements

### Requirement: Plugin Menu Integration
**Reason**: The plugin menu infrastructure (MenuBuilder, MENU_ICONS, PluginRegistry integration) was created but never used. Menus are built manually. Removing to reduce dead code.
**Migration**: If plugin menus are needed in the future, design a fresh system when the requirement materializes.
