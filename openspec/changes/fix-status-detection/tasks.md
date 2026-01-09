## 1. Shell: Remove compacting from wt-status

- [x] 1.1 In `detect_agents()`: remove the `tail -1` + pattern matching block (lines 429-436), replace with unconditional `status="running"` when `age < 10`
- [x] 1.2 In `detect_agents()`: update comment on line 332 to only mention "running" (remove "compacting")
- [x] 1.3 In `collect_all_status()`: remove `compacting` counter variable, keep `"compacting":0` in JSON output for backward compat
- [x] 1.4 In `format_terminal()`: remove compacting from status case/display, remove compacting from summary line
- [x] 1.5 In `format_compact()`: remove compacting from compact format output, update idle check condition

## 2. GUI: Remove compacting colors and status handling

- [x] 2.1 In `gui/constants.py`: remove `ICON_COMPACTING` export and definition, remove all `status_compacting`, `row_compacting`, `row_compacting_text` entries from all color profiles
- [x] 2.2 In `gui/control_center/mixins/table.py`: remove `compacting` branch from row background/text color logic
- [x] 2.3 In `gui/control_center/main_window.py`: remove compacting from `check_status_changes()` aggregation, remove from `update_tray_icon()` parameter and tooltip
- [x] 2.4 In `gui/control_center/main_window.py`: remove compacting from `on_status_update()` summary parsing and tooltip building

## 3. GUI: Remove compacting from status icon helper

- [x] 3.1 In `gui/control_center/mixins/table.py`: remove compacting case from `get_status_icon()` method

## 4. Tests

- [x] 4.1 Update existing GUI tests to remove any compacting status references
- [x] 4.2 Run full GUI test suite to verify no regressions
