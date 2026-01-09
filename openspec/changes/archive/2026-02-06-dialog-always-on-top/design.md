## Context

The Control Center uses `Qt.WindowStaysOnTopHint` + macOS native NSWindow level 1000 + a 500ms `orderFrontRegardless()` timer to stay always-on-top. Custom QDialog subclasses already set `WindowStaysOnTopHint`, but system dialogs (QMessageBox, QInputDialog, QFileDialog) and ad-hoc QDialogs do not. The periodic timer also fights dialogs for focus, causing apparent freezes.

Current pattern:
- Menus call `pause_always_on_top()` / `resume_always_on_top()` around `menu.exec()`
- Custom dialogs use `self.hide()` / `self.show()` to avoid overlap (workaround, not fix)
- System dialogs (QMessageBox.warning(), QInputDialog.getText(), etc.) have no always-on-top handling at all

## Goals / Non-Goals

**Goals:**
- All dialogs (system and custom) stay on top of other applications on macOS
- The always-on-top timer is paused while any dialog is open
- Centralized helper functions make it hard to forget the pattern for new dialogs
- Add CLAUDE.md rule so AI agents apply the pattern to new code

**Non-Goals:**
- Changing the existing custom dialog classes (they already have WindowStaysOnTopHint)
- Changing the main window's always-on-top mechanism
- Linux/Windows specific fixes (only macOS has this issue due to NSWindow level)

## Decisions

### Decision 1: Wrapper functions in `gui/dialogs/helpers.py`

Create wrapper functions for QMessageBox, QInputDialog, and QFileDialog that:
1. Call `pause_always_on_top()` on parent (if parent has it)
2. Set `WindowStaysOnTopHint` on the dialog instance
3. Execute the dialog
4. Call `resume_always_on_top()` in a finally block

**Alternatives considered:**
- Monkey-patching Qt classes: Fragile and surprising
- Subclassing each system dialog: Too much boilerplate for simple wrappers
- Decorator on exec() calls: Doesn't solve the flag setting

**Rationale:** Simple functions are easy to understand, easy to test, and easy to enforce via CLAUDE.md rules.

### Decision 2: Non-static QMessageBox pattern

Replace `QMessageBox.warning(parent, title, text)` with instance creation:
```python
box = QMessageBox(icon, title, text, buttons, parent)
box.setWindowFlags(box.windowFlags() | Qt.WindowStaysOnTopHint)
box.exec()
```

**Rationale:** Static methods don't allow setting window flags before display.

### Decision 3: Fix ad-hoc QDialogs inline

The two ad-hoc QDialogs in menus.py (`show_team_worktree_details`, `start_ralph_loop_dialog`) will get `WindowStaysOnTopHint` added to their existing code, plus `pause/resume_always_on_top()` calls.

**Rationale:** These are one-off dialogs, not worth extracting into a helper.

### Decision 4: Wrapper function signatures mirror Qt originals

The wrappers will accept the same parameters as the Qt static methods they replace, making migration a simple find-and-replace.

Wrapper functions:
- `show_warning(parent, title, text)` → replaces `QMessageBox.warning()`
- `show_information(parent, title, text)` → replaces `QMessageBox.information()`
- `show_question(parent, title, text, buttons, default)` → replaces `QMessageBox.question()`
- `get_text(parent, title, label, **kwargs)` → replaces `QInputDialog.getText()`
- `get_item(parent, title, label, items, current, editable)` → replaces `QInputDialog.getItem()`
- `get_existing_directory(parent, caption, dir, options)` → replaces `QFileDialog.getExistingDirectory()`
- `get_open_filename(parent, caption, dir, filter)` → replaces `QFileDialog.getOpenFileName()`

### Decision 5: pause/resume around custom dialog exec() calls

Add `pause_always_on_top()` / `resume_always_on_top()` calls to custom dialog usages in handlers.py and menus.py where they are currently missing. The `self.hide()` / `self.show()` pattern stays as-is (it serves a separate purpose: preventing the main window from covering the dialog).

## Risks / Trade-offs

- [QMessageBox in main.py line 70] The "Already Running" dialog has no parent window (parent=None) → Cannot call pause/resume. But this fires before the main window exists, so it's harmless. Leave as-is.
- [QMessageBox inside custom dialogs] Messages in chat.py, team_settings.py, worktree_config.py, new_worktree.py are parented to the dialog, not the main window → These inherit always-on-top from their parent dialog which already has the flag. No change needed.
- [Performance] Creating QMessageBox instances instead of using static methods has negligible overhead.
