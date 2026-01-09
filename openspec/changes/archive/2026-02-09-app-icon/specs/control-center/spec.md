## ADDED Requirements

### Requirement: Application Icon
The GUI SHALL display a custom application icon in the window decoration and taskbar.

#### Scenario: Icon loaded on startup
- **WHEN** the Control Center starts
- **THEN** the application icon SHALL be set via `QApplication.setWindowIcon()`
- **AND** the icon SHALL be loaded from `assets/icon.png` relative to the project root

#### Scenario: Graceful fallback
- **WHEN** the icon file does not exist
- **THEN** the application SHALL start without error
- **AND** the default Qt icon SHALL be used
