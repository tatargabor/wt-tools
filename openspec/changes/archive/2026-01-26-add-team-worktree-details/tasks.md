# Tasks: Add Team Worktree Details

## Phase 1: Team Row Selection

- [x] **T01**: Make team rows selectable
  - Removed `~Qt.ItemIsSelectable` flag from team row items
  - Store team worktree data in `row_to_team_worktree` dict
  - Distinguish from own worktrees in selection handling

- [x] **T02**: Add tooltip to team rows
  - Full member name (display_name)
  - Change ID
  - Agent status
  - Last seen (relative time: "2 min ago")

## Phase 2: My Machines Filter

- [x] **T03**: Detect "my other machines"
  - Compare `user` field in member JSON with current user
  - Different hostname = other machine
  - `is_my_machine` flag in team_wt data

- [x] **T04**: Update filter button to cycle through states
  - State 0: All Team (👥)
  - State 1: My Machines Only (👤)
  - State 2: Hide Team (empty)
  - Click cycles through states

- [x] **T05**: Apply filter in `update_status()`
  - All Team: show all team members
  - My Machines: filter where `user == my_user AND hostname != my_hostname`
  - Hide: show no team worktrees

## Phase 3: Context Menu

- [x] **T06**: Add read-only context menu for team rows
  - "View Details..." → show dialog with full info
  - "Copy Change ID" → copy to clipboard
  - No destructive actions

- [x] **T07**: Create TeamWorktreeDetailsDialog
  - Shows: member, hostname, change, status, last_seen
  - Read-only, informational only
  - Close button
  - "⚡ This is your other machine" indicator

## Verification

- [x] Team rows can be selected (highlighted)
- [x] Tooltip shows on hover
- [x] Filter cycles: All → My Machines → Hide → All
- [x] "My Machines" shows only current user's other machines
- [x] Context menu shows on right-click
- [x] "Copy Change ID" works
