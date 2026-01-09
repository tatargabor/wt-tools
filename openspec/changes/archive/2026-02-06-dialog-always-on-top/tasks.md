## 1. Create helper wrappers

- [x] 1.1 Create `gui/dialogs/helpers.py` with wrapper functions: `show_warning`, `show_information`, `show_question`, `get_text`, `get_item`, `get_existing_directory`, `get_open_filename` — each sets `WindowStaysOnTopHint` and calls `pause/resume_always_on_top()` on parent
- [x] 1.2 Export helpers from `gui/dialogs/__init__.py`

## 2. Replace QMessageBox calls in mixins

- [x] 2.1 Replace `QMessageBox.warning/information/question` in `gui/control_center/mixins/handlers.py` (lines 49, 55, 146, 207, 283, 324, 390, 449) with helpers
- [x] 2.2 Replace `QMessageBox.warning/information` in `gui/control_center/mixins/menus.py` (lines 86, 350, 358, 369, 427) with helpers
- [x] 2.3 Replace `QMessageBox.warning/information/question` in `gui/control_center/mixins/team.py` (lines 278, 289, 294, 304, 310, 315, 324, 329, 331, 333) with helpers
- [x] 2.4 Replace `QMessageBox.information` in `gui/control_center/mixins/jira.py` (lines 117, 124, 129, 151) with helpers

## 3. Replace QInputDialog and QFileDialog calls

- [x] 3.1 Replace `QInputDialog.getText` in `gui/control_center/mixins/handlers.py` (line 311) with `get_text` helper
- [x] 3.2 Replace `QInputDialog.getItem` in `gui/control_center/mixins/handlers.py` (line 151) with `get_item` helper
- [x] 3.3 Replace `QFileDialog.getExistingDirectory` in `gui/control_center/mixins/handlers.py` (line 428) with `get_existing_directory` helper

## 4. Fix ad-hoc QDialogs

- [x] 4.1 Add `WindowStaysOnTopHint` and `pause/resume_always_on_top()` to `show_team_worktree_details()` in `menus.py` (line 314)
- [x] 4.2 Add `WindowStaysOnTopHint` and `pause/resume_always_on_top()` to `start_ralph_loop_dialog()` in `menus.py` (line 389)
- [x] 4.3 Add `WindowStaysOnTopHint` and `pause/resume_always_on_top()` to `view_ralph_log()` fallback QDialog in `handlers.py` (line 270)

## 5. Add pause/resume to custom dialog exec() calls

- [x] 5.1 Add `pause/resume_always_on_top()` around `run_command_dialog()` in `handlers.py` (line 30)
- [x] 5.2 Add `pause/resume_always_on_top()` around `MergeDialog` usage in `handlers.py` (line 92)
- [x] 5.3 Add `pause/resume_always_on_top()` around `NewWorktreeDialog` usage in `handlers.py` (line 395)
- [x] 5.4 Add `pause/resume_always_on_top()` around `WorkDialog` usage in `handlers.py` (line 407)
- [x] 5.5 Add `pause/resume_always_on_top()` around custom dialogs in `menus.py` (open_settings, open_team_settings, show_chat_dialog, show_worktree_config, JiraSyncDialog usages in jira.py)

## 6. CLAUDE.md rule

- [x] 6.1 Add always-on-top dialog rule to CLAUDE.md

## 7. Tests

- [x] 7.1 Add test in `tests/gui/test_XX_dialog_helpers.py` to verify helpers set `WindowStaysOnTopHint` and call pause/resume
- [ ] 7.2 Run GUI tests: `PYTHONPATH=. python -m pytest tests/gui/ -v --tb=short`
