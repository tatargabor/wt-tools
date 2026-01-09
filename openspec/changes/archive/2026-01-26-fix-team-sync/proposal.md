# Proposal: Fix Team Sync Bugs

JIRA Key: TBD
Story: EXAMPLE-466

## Summary

The team sync functionality contains several bugs: not all project worktrees are displayed, the chat recipient selector is empty, and the machine name is missing from the first column of remote worktrees.

## Motivation

The team sync feature was implemented in Phase 1-2, but several bugs were discovered during usage:

1. **Missing remote worktrees**: Some projects' (e.g., aitools) remote worktrees don't appear, even though team is enabled
2. **Empty chat recipient dropdown**: Can't select a recipient, the dropdown shows "No recipients with chat keys" message
3. **Project identification inconsistency**: The code uses a mix of project name and remote URL as identifier
4. **Missing machine name in table**: Remote worktrees only show "username:", the machine name is missing

## Root Cause Analysis

### Bug 1: Missing remote worktrees
- `TeamWorker._get_enabled_project_paths()` reads project paths from `projects.json`
- `projects.json` doesn't contain all projects, only manually added ones
- Solution: Use remote_urls from worktrees directly

### Bug 2: Chat recipient dropdown
- `ChatDialog.load_recipients()` populates from `team_data.members` list
- The `team_data` dict passed to ChatDialog doesn't always contain chat_public_key
- Solution: Verify wt-control-sync JSON output

### Bug 3: Project identification
- Some places use `project` name, others use `remote_url` as key
- `_get_project_remote_url()` tries to look up from `self.worktrees`, but if there's no worktree for that project, returns empty string
- Solution: Consistently use remote_url everywhere

### Bug 4: Missing machine name
- `_render_team_worktree_row()` uses the `team_wt['member']` value (already abbreviated)
- `_get_team_worktrees_for_project()` provides `display_name.split("@")[0][:12]` as `member`
- Solution: Display `user@host` format in the table's first column

## What Changes

1. **TeamWorker fix**: Synchronization runs for all enabled projects, not just those listed in projects.json
2. **Chat recipient fix**: Verify chat_public_key presence in team_data.members list
3. **Remote URL consistency**: All project identification based on remote_url
4. **Machine name display**: `user@host:` format in the table's first column

## Impact

- Affected files:
  - `gui/workers/team.py` - TeamWorker._get_enabled_project_paths()
  - `gui/control_center/mixins/team.py` - _get_team_worktrees_for_project()
  - `gui/control_center/mixins/table.py` - _render_team_worktree_row()
  - `gui/dialogs/chat.py` - load_recipients()
  - `bin/wt-control-sync` - JSON output verification

## Out of Scope

- Adding new team features
- Chat encryption modifications
- UI redesign
