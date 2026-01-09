## Why

On macOS, when the Control Center opens a dialog (QMessageBox, QInputDialog, QFileDialog, or ad-hoc QDialog), the dialog does not inherit the always-on-top window flag. Other applications (e.g., Zed editor) cover the dialog, making it invisible and the UI appears frozen. The periodic `orderFrontRegardless()` timer also conflicts with open dialogs by fighting for focus. Users must manually hunt for the hidden dialog window.

## What Changes

- Create `gui/dialogs/helpers.py` with wrapper functions for `QMessageBox`, `QInputDialog`, and `QFileDialog` that automatically set `WindowStaysOnTopHint` and call `pause_always_on_top()` / `resume_always_on_top()` on the parent window
- Replace all direct `QMessageBox.warning()`, `QMessageBox.question()`, `QMessageBox.information()`, `QInputDialog.getText()`, `QInputDialog.getItem()`, `QFileDialog.getExistingDirectory()`, `QFileDialog.getOpenFileName()` calls with the new wrappers
- Fix two ad-hoc QDialog instances in `menus.py` (`show_team_worktree_details`, `start_ralph_loop_dialog`) to set `WindowStaysOnTopHint`
- Add `pause_always_on_top()` / `resume_always_on_top()` calls around all custom dialog `exec()` calls in handlers.py and menus.py
- Add CLAUDE.md rule requiring always-on-top handling for any new dialog

## Capabilities

### New Capabilities

### Modified Capabilities
- `control-center`: Dialogs must stay on top on macOS and pause the always-on-top timer during display

## Impact

- `gui/dialogs/helpers.py` — new file with wrapper functions
- `gui/control_center/mixins/handlers.py` — updated dialog call sites
- `gui/control_center/mixins/menus.py` — updated dialog call sites + ad-hoc QDialog fixes
- `gui/dialogs/settings.py` — QFileDialog calls updated
- `gui/dialogs/new_worktree.py` — QFileDialog calls updated
- `gui/main.py` — QMessageBox call updated
- `gui/dialogs/team_settings.py` — QMessageBox calls updated
- `gui/dialogs/chat.py` — QMessageBox calls updated
- `CLAUDE.md` — new rule for always-on-top dialog handling
