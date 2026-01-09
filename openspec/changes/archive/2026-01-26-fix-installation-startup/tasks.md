# Tasks

## Implementation

1. [x] Fix `gui/main.py` to handle both script and module execution
   - Already has path manipulation when `__package__` is None (lines 26-30)
   - Uses conditional imports based on execution context

2. [x] Update `bin/wt-control` to set PYTHONPATH
   - Added PROJECT_ROOT variable
   - Export PYTHONPATH before launching

3. [x] Fix desktop entry in `install.sh`
   - Use wt-control wrapper script instead of direct python
   - Wrapper handles PYTHONPATH automatically

4. [x] Add GUI startup verification to `install.sh`
   - Test gui.control_center import
   - Test PySide6 import

5. [x] Update CLAUDE.md startup instructions
   - Documented PYTHONPATH requirement
   - Added troubleshooting section

## Validation

6. [x] Test fresh installation
   - Verified wt-control starts from terminal
   - GUI runs correctly

7. [x] Test symlinked installation
   - Verified ~/.local/bin/wt-control symlink works
   - GUI started successfully via symlink

8. [ ] Test desktop entry
   - Run from Alt+F2 launcher (manual test needed)
   - Verify GUI starts without terminal
