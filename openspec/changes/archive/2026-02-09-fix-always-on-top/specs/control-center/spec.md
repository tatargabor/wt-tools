## MODIFIED Requirements

### Requirement: Dialog Always-On-Top
The GUI SHALL ensure all dialogs and menus remain visible above the Control Center window on macOS by using correct window levels rather than timer-based workarounds.

#### Scenario: Main window stays above normal apps
- **WHEN** the Control Center is running on macOS
- **THEN** the main window SHALL use NSStatusWindowLevel (25) via native NSWindow API
- **AND** the window SHALL appear above all normal-level and floating-level application windows

#### Scenario: Menus appear above main window
- **WHEN** a QMenu is shown (context menu, main menu dropdown)
- **THEN** the menu SHALL appear above the Control Center window without any special handling
- **AND** the main thread SHALL NOT block due to invisible menus

#### Scenario: Dialogs appear above main window
- **WHEN** any dialog is opened (QDialog, QMessageBox, QInputDialog, QFileDialog)
- **THEN** the dialog SHALL appear above the Control Center window
- **AND** dialog helpers from `gui/dialogs/helpers.py` SHALL set `WindowStaysOnTopHint` for defense-in-depth

#### Scenario: No periodic timer for window ordering
- **WHEN** the Control Center is running
- **THEN** there SHALL be no periodic timer calling `orderFrontRegardless()` or equivalent
- **AND** window ordering SHALL be managed entirely by macOS window level system

#### Scenario: No pause/resume mechanism required
- **WHEN** a dialog or menu is opened from the Control Center
- **THEN** no `pause_always_on_top()` or `resume_always_on_top()` call SHALL be required
- **AND** neither method SHALL exist in the codebase

#### Scenario: Window behavior across Spaces
- **WHEN** the Control Center is running on macOS
- **THEN** the window SHALL appear on all desktop Spaces (NSWindowCollectionBehaviorCanJoinAllSpaces)
- **AND** the window SHALL remain stationary when switching Spaces (NSWindowCollectionBehaviorStationary)
- **AND** the window SHALL NOT appear in Cmd+Tab cycling (NSWindowCollectionBehaviorIgnoresCycle)

#### Scenario: Helper wrappers for system dialogs
- **WHEN** code needs to show a QMessageBox, QInputDialog, or QFileDialog
- **THEN** wrapper functions from `gui/dialogs/helpers.py` SHALL be used instead of direct Qt static methods
- **AND** the wrappers SHALL set `WindowStaysOnTopHint` on dialogs

#### Scenario: CLAUDE.md rule for new dialogs
- **WHEN** a new dialog is added to the GUI
- **THEN** the CLAUDE.md file SHALL document the requirement to use always-on-top helpers
- **AND** the rule SHALL NOT require pause/resume calls
