# Tasks: Team Sync & Collaboration

## Phase 1: Infrastructure (DONE)

- [x] **T01**: Create `wt-control-init` script
  - Creates orphan branch `wt-control`
  - Creates hidden worktree `.wt-control/`
  - Creates directory structure: `members/`, `queue/`, `chat/`
  - Adds `.wt-control/` to `.gitignore`
  - Pushes to remote if possible

- [x] **T02**: Create `wt-control-sync` script
  - Reads member name from git config + hostname
  - Generates member JSON with status and changes
  - Writes to `members/{name}.json`
  - Supports `--pull`, `--push`, `--full` modes
  - Supports `--json` output for GUI
  - Conflict detection (multiple members on same change)

- [x] **T03**: Filter `.wt-control` worktree from `wt-status`
  - Modified: `bin/wt-status`
  - Skip worktrees matching `$proj_path/.wt-control`

## Phase 2: GUI Integration (DONE)

- [x] **T04**: Add TeamWorker background thread
  - Polls `wt-control-sync --full --json`
  - Emits `team_updated` signal with data
  - Respects `sync_interval_ms` config

- [x] **T05**: Add team status label to main window
  - Shows active/waiting team members
  - Shows conflict warnings
  - Updates on `team_updated` signal

- [x] **T06**: Add Team settings tab
  - Enable/disable checkbox
  - Auto-sync checkbox
  - Sync interval spinbox
  - Initialize button (calls `wt-control-init`)
  - Status label for feedback

## Phase 3: Team Worktrees Display (DONE)

- [x] **T07**: Add team worktrees to table display
  - Modified: `update_status()` in `gui/main.py`
  - Separator row between own and team worktrees
  - Gray/italic styling for team rows
  - Team rows not selectable (no context menu)

- [x] **T08**: Add team filter toggle button
  - Added: `btn_team_filter` (👥) in toolbar
  - Toggle: show/hide team worktrees
  - State: `self.show_team_worktrees`

## Phase 4: Per-Project Team Display (DONE)

- [x] **T09**: Per-project team filter
  - Redesigned table with project header rows
  - Team filter button (👥/👤/ ) in each project header
  - `team_filter_state` changed from int to dict `{project: 0|1|2}`
  - Team worktrees shown under their respective project, not at bottom

- [x] **T10**: Per-project chat unread tracking
  - `chat_unread` changed from int to dict `{project: count}`
  - Chat "C" button in project header (not in worktree rows)
  - Fast blinking (3x faster) for chat icon

- [x] **T11**: Refactored table rendering
  - New `refresh_table_display()` method
  - Helper methods: `_create_project_header()`, `_get_team_worktrees_for_project()`
  - `_render_worktree_row()`, `_render_team_worktree_row()`
  - Removed global `btn_team_filter` from toolbar

## Phase 5: Future Features (NOT STARTED)

- [ ] Conflict Warning panel (file-level)
- [ ] Shared Task Queue panel
- [ ] Findings/Knowledge base

## Verification

- [x] `wt-control-init` creates branch and worktree
- [x] `wt-control-sync --json` outputs valid JSON
- [x] `.wt-control` NOT shown in worktree list
- [x] Team label shows member status
- [x] Team worktrees displayed (gray, non-interactive)
- [x] Filter toggle (👥) works
- [x] Settings tab can enable/disable team sync
- [x] TeamWorker respects enabled flag
- [x] Per-project team filter: each project has own filter button
- [x] Per-project chat: "C" button only appears in project header with unread
- [x] Team worktrees appear under their project, not at table bottom
