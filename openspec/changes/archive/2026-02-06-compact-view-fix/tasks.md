## 1. Remove Editor Detection

- [x] 1.1 Delete `gui/control_center/mixins/editor_detection.py`
- [x] 1.2 Remove `EditorDetectionMixin` import from `gui/control_center/mixins/__init__.py`
- [x] 1.3 Remove `invalidate_editor_cache()` calls from `gui/control_center/main_window.py`

## 2. Update Filter Logic

- [x] 2.1 In `gui/control_center/mixins/table.py`, replace editor_paths filtering with agent.status check: show only local worktrees where `agent.status != "idle"` when filter is active
- [x] 2.2 Hide main repo rows (`is_main_repo == True`) when filter is active
- [x] 2.3 Ensure team rows remain hidden when filter is active (already the case, verify)

## 3. Update Button

- [x] 3.1 Update filter button tooltip in `main_window.py` to "Show only active worktrees"

## 4. Tests

- [x] 4.1 Add or update test for compact view filter in `tests/gui/` verifying that idle worktrees are hidden and active ones are shown
- [ ] 4.2 Run GUI tests: `PYTHONPATH=. python -m pytest tests/gui/ -v --tb=short`
