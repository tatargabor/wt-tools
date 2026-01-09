## ADDED Requirements

### Requirement: Dialog Always-On-Top
The GUI SHALL ensure all dialogs remain visible on top of other applications on macOS.

#### Scenario: System dialog stays on top
- **WHEN** a QMessageBox, QInputDialog, or QFileDialog is opened from the Control Center
- **THEN** the dialog has `WindowStaysOnTopHint` set
- **AND** the dialog is visible above other applications (e.g., Zed editor)

#### Scenario: Ad-hoc dialog stays on top
- **WHEN** an inline QDialog is created (e.g., Ralph Loop config, Team Worktree Details)
- **THEN** the dialog has `WindowStaysOnTopHint` set

#### Scenario: Always-on-top timer paused during dialog
- **WHEN** any dialog is open (system or custom)
- **THEN** the periodic `orderFrontRegardless()` timer is paused
- **AND** the timer resumes after the dialog closes

#### Scenario: Helper wrappers for system dialogs
- **WHEN** code needs to show a QMessageBox, QInputDialog, or QFileDialog
- **THEN** wrapper functions from `gui/dialogs/helpers.py` MUST be used instead of direct Qt static methods
- **AND** the wrappers handle `WindowStaysOnTopHint` and timer pause/resume automatically

#### Scenario: CLAUDE.md rule for new dialogs
- **WHEN** a new dialog is added to the GUI
- **THEN** the CLAUDE.md file documents the requirement to use always-on-top helpers or set `WindowStaysOnTopHint` explicitly
