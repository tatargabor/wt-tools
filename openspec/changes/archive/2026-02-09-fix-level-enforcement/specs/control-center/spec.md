## MODIFIED Requirements

### Requirement: Dialog Always-On-Top
The GUI SHALL ensure the Control Center window and all its dialogs remain visible on top of other applications on macOS by maintaining NSStatusWindowLevel (25) across all app activation state changes.

#### Scenario: CC stays above normal apps after clicking another app
- **WHEN** the Control Center is visible at NSStatusWindowLevel (25)
- **AND** the user clicks on another application (e.g., Zed editor)
- **THEN** the Control Center SHALL remain visible above the other application
- **AND** the NSWindow level SHALL be 25 (NSStatusWindowLevel)

#### Scenario: Level enforcement on app state change
- **WHEN** the application activation state changes (active → inactive or inactive → active)
- **THEN** the system SHALL verify the NSWindow level is 25
- **AND** correct it within 100ms if Qt6 has reset it

#### Scenario: Periodic level enforcement backup
- **WHEN** the Control Center is running
- **THEN** a periodic timer SHALL check the NSWindow level every 5 seconds
- **AND** restore it to 25 if it has drifted

#### Scenario: Level enforcement after show_window
- **WHEN** the Control Center is shown (e.g., from tray icon click)
- **AND** `setWindowFlags()` recreates the NSWindow
- **THEN** the native level and collection behavior SHALL be re-applied

#### Scenario: System dialog stays on top
- **WHEN** a QMessageBox, QInputDialog, or QFileDialog is opened from the Control Center
- **THEN** the dialog has `WindowStaysOnTopHint` set
- **AND** the dialog is visible above other applications

#### Scenario: Ad-hoc dialog stays on top
- **WHEN** an inline QDialog is created (e.g., Ralph Loop config, Team Worktree Details)
- **THEN** the dialog has `WindowStaysOnTopHint` set

#### Scenario: Helper wrappers for system dialogs
- **WHEN** code needs to show a QMessageBox, QInputDialog, or QFileDialog
- **THEN** wrapper functions from `gui/dialogs/helpers.py` MUST be used instead of direct Qt static methods
- **AND** the wrappers handle `WindowStaysOnTopHint` automatically

#### Scenario: Window does not hide on deactivation
- **WHEN** the user activates another application
- **THEN** the Control Center window SHALL NOT hide
- **AND** `hidesOnDeactivate` SHALL be set to False on the native NSWindow
