
## GUI Testing

When the user says "futtass tesztet", "run tests", "teljes teszt", or similar — run this:
```bash
PYTHONPATH=. python -m pytest tests/gui/ -v --tb=short
```

**Do NOT run tests automatically.** Only run tests when the user explicitly asks for it (e.g. "futtass tesztet", "run tests", "teljes teszt").

## Auto-Commit After Apply

After a skill-driven apply (e.g. `/opsx:apply`) finishes or pauses, automatically commit all changes. Follow the standard commit flow (stage relevant files, write a concise commit message).

When adding new GUI functionality (button, menu, dialog, etc.), add a corresponding test in `tests/gui/test_XX_<feature>.py`. See existing tests for patterns:
- Read-only checks: `test_01_startup.py`, `test_02_window.py`
- Menu interception: `test_04_main_menu.py` (`_MenuCapture` pattern)
- Real git operations: `test_08_worktree_ops.py`
- Worktree + context menu: `test_11_ralph_loop.py`

Fixtures are in `tests/gui/conftest.py`. The `control_center` fixture is module-scoped — restore any state you mutate (re-show window after hide, etc).

## macOS Always-On-Top Dialog Rule

The Control Center uses NSStatusWindowLevel (25) to stay above normal apps. Menus and dialogs with `WindowStaysOnTopHint` naturally appear above it — no timer or pause/resume needed.

When creating ANY dialog in the GUI (QDialog, QMessageBox, QInputDialog, QFileDialog):

1. **System dialogs** (QMessageBox, QInputDialog, QFileDialog): Use the wrapper helpers from `gui/dialogs/helpers.py` instead of the Qt static methods. These automatically set `WindowStaysOnTopHint`.
   ```python
   from gui.dialogs.helpers import show_warning, show_question, get_text, get_item, get_existing_directory, get_open_filename
   show_warning(self, "Error", "Something went wrong")
   ```

2. **Custom/ad-hoc QDialogs**: Set `WindowStaysOnTopHint` explicitly:
   ```python
   dialog = QDialog(self)
   dialog.setWindowFlags(dialog.windowFlags() | Qt.WindowStaysOnTopHint)
   dialog.exec()
   ```

3. **Custom dialog subclasses** (e.g. SettingsDialog): These already have `WindowStaysOnTopHint` in their `__init__`. Just call `.exec()` directly.

## README Updates

The README structure is defined in `docs/readme-guide.md`. When updating the README:

1. Read `docs/readme-guide.md` for mandatory sections, tone rules, and CLI documentation rules
2. Run `ls bin/wt-*` to check CLI completeness
3. Follow the mandatory section order exactly
4. Run through the Update Checklist at the bottom of the guide

When the user asks to update or regenerate the README, use the guide as the authoritative source. The guide contains AI generation instructions — it's designed to be enough context for a full README rewrite.

## GUI Startup

To start the Control Center GUI:

```bash
# Recommended - uses wrapper script with correct paths
wt-control

# Or run directly with PYTHONPATH (from project root)
PYTHONPATH=. python gui/main.py
```

To kill and restart:
```bash
pkill -f "python.*gui/main.py" 2>/dev/null; sleep 1
wt-control &
```

### Troubleshooting

**Import errors**: If you see `ImportError: attempted relative import`, make sure PYTHONPATH includes the project root:
```bash
PYTHONPATH=/path/to/wt-tools python gui/main.py
```

**Qt/conda conflicts on Linux**: Set QT_PLUGIN_PATH:
```bash
QT_PLUGIN_PATH="$(python -c 'import PySide6; print(PySide6.__path__[0])')/Qt/plugins" wt-control
```
