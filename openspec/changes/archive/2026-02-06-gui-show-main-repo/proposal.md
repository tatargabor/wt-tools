## Summary

Show the main (non-worktree) repository directory alongside worktrees in the Control Center GUI. Currently only git worktrees are displayed; the main repo checkout is explicitly filtered out. This change adds the main repo as a first-class entry per project, enabling users who work directly on the main branch to manage it from the same interface.

## Problem

Two use cases are unsupported:
1. A user works directly on the main branch without creating worktrees — they have no visibility or control from the Control Center.
2. Users want to see what's happening on the main branch (agent status, uncommitted changes, last commit) alongside their worktrees.

## Proposed Solution

### Backend (`bin/wt-status`)
- Remove the filter that skips the main repo path from JSON output
- Add `"is_main_repo": true` flag to the main repo entry
- Use the current branch name (e.g., `master`) as `change_id`
- Emit the main repo entry first per project (before worktrees)

### CLI tools (`bin/wt-work`, `bin/wt-focus`, `bin/wt-common.sh`)
- Add `get_main_branch()` helper to `wt-common.sh`
- Modify `wt-work` to detect when `change_id` matches the main branch and skip worktree creation/lookup — use `project_path` directly
- Modify `wt-focus` to resolve the main repo path when `change_id` matches the main branch (instead of searching for `change/<id>` branches)

### GUI display (`gui/control_center/mixins/table.py`)
- Render main repo row with `★` prefix in the Change column
- Always position it as the first row under its project header
- Same status indicators (running/idle/waiting/compacting) as worktrees

### GUI context menu (`gui/control_center/mixins/menus.py`)
- Show the same context menu for main repo rows with these exclusions:
  - No "Worktree > Close" (cannot close the main repo)
  - No "Git > Merge to..." (wt-merge is worktree-specific)
  - No "Worktree > Push Branch" (wt-push is worktree-specific)
- All other actions (terminal, file manager, focus, git push/pull/fetch, JIRA, Ralph, project settings) work unchanged since they are path-based

### GUI double-click (`gui/control_center/mixins/handlers.py`)
- For main repo rows, call `wt-work` with the main branch name as change_id
- `wt-work` handles this natively after the CLI changes above

## Scope

- All existing worktree functionality remains unchanged
- No changes to worktree creation, merge, or close flows
- GUI tests must be added/updated for the new main repo row
