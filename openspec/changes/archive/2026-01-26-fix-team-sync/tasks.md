# Tasks: Fix Team Sync Bugs

## 1. Investigation & Debugging

- [x] 1.1 Debug TeamWorker: add logging to see which projects are being synced
- [x] 1.2 Verify wt-control-sync JSON output includes chat_public_key for members
- [x] 1.3 Check projects.json structure vs worktrees remote_url

## 2. Bug Fix: Missing Remote Worktrees

- [x] 2.1 Modify `TeamWorker._get_enabled_project_paths()` to discover project paths from worktrees
- [x] 2.2 Fall back to projects.json only if worktrees don't provide the path (not needed - worktrees always available)
- [x] 2.3 Ensure all enabled projects (by remote_url) get synced

## 3. Bug Fix: Chat Recipient Dropdown

- [x] 3.1 Verify wt-control-sync outputs `chat_public_key` in member JSON
- [x] 3.2 Debug ChatDialog.load_recipients() - log team_data.members
- [x] 3.3 Fix recipient filtering - improved message when no keys available

## 4. Bug Fix: Project Identification Consistency

- [x] 4.1 Audit all uses of project name vs remote_url in team-related code
- [x] 4.2 Ensure settings dialog uses remote_url consistently (already correct)
- [x] 4.3 Ensure TeamMixin methods use remote_url for lookups (already correct)

## 5. Bug Fix: Missing Hostname in Table

- [x] 5.1 Modify `_get_team_worktrees_for_project()` to include full `user@host` in member field
- [x] 5.2 Update `_render_team_worktree_row()` to display `user@host:` format (uses member field)
- [x] 5.3 Adjust column width if needed for longer text (not needed - truncation handles it)

## 6. Testing & Validation

- [x] 6.1 Test team sync with multiple projects enabled - aitools now shows 2 team worktrees
- [x] 6.2 Test chat recipient dropdown shows team members with keys - improved message
- [x] 6.3 Test remote worktree display shows user@hostname format
- [x] 6.4 Verify no regressions in existing team functionality
