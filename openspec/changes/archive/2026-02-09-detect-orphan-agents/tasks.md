## 1. Backend: Orphan Detection in wt-status

- [x] 1.1 Add PPID-based orphan check to `detect_agents()` in `bin/wt-status`: after matching a PID to a worktree, get its PPID, resolve parent comm name, and set status to `"orphan"` if parent is not a known shell (zsh, bash, fish, sh, dash, including `-` prefix login variants)
- [x] 1.2 Exclude orphan agents from summary counts (running/compacting/waiting) in `collect_all_status()`

## 2. GUI: Color Constants

- [x] 2.1 Add `status_orphan`, `row_orphan`, `row_orphan_text` color entries to all four color profiles in `gui/constants.py`
- [x] 2.2 Add `ICON_ORPHAN = "⚠"` constant to `gui/constants.py`

## 3. GUI: Orphan Row Rendering

- [x] 3.1 Add orphan status handling in `get_status_icon()` — return `ICON_ORPHAN` and `status_orphan` color
- [x] 3.2 Update `_render_worktree_row()` in `gui/control_center/mixins/table.py` to display `⚠ <pid>` in PID column and apply `row_orphan` / `row_orphan_text` colors when status is `"orphan"`

## 4. GUI: Kill Orphan Context Menu

- [x] 4.1 Add "⚠ Kill Orphan Process" action in `show_row_context_menu()` in `gui/control_center/mixins/menus.py` — visible only when the clicked row's agent has status `"orphan"`, sends SIGTERM to the PID with try/except for ProcessLookupError

## 5. Tests

- [x] 5.1 Add GUI test for orphan row display: mock wt-status JSON with an orphan agent, verify ⚠ icon in PID column and correct row styling
- [x] 5.2 Add GUI test for orphan context menu: right-click on orphan row, verify "Kill Orphan Process" appears; right-click on normal row, verify it does not appear
