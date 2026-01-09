## 1. Create wt-deploy-hooks script

- [x] 1.1 Create `bin/wt-deploy-hooks` — extract hook deployment logic from `install.sh:deploy_project_hooks()` into standalone script. Accept target dir as argument, support `--quiet` flag. Same JSON merge logic (create/merge/backup/skip if present).
- [x] 1.2 Make `bin/wt-deploy-hooks` executable and add to install.sh symlink list

## 2. Refactor install.sh to use wt-deploy-hooks

- [x] 2.1 Replace inline `deploy_project_hooks()` body in `install.sh` with call to `wt-deploy-hooks`
- [x] 2.2 Update `wt-add` hook deployment to call `wt-deploy-hooks` instead of inline logic (if it has inline logic)

## 3. Hook deployment on worktree creation

- [x] 3.1 In `bin/wt-new`: after successful `git worktree add`, call `wt-deploy-hooks --quiet <new-worktree-path>`. Warn but don't fail if deployment fails.

## 4. Hook presence detection in wt-status

- [x] 4.1 Add `check_hooks_installed()` function to `bin/wt-status` — check if `<path>/.claude/settings.json` exists and contains both `hooks.UserPromptSubmit` and `hooks.Stop` entries. Return "true"/"false".
- [x] 4.2 Call `check_hooks_installed` in `collect_worktree_status()` and add `"hooks_installed": true/false` field to worktree JSON output

## 5. GUI: Hook status indicator

- [x] 5.1 In `gui/control_center/mixins/table.py` `_render_worktree_row()`: when `hooks_installed` is false, append warning text to status cell tooltip
- [x] 5.2 In `gui/control_center/mixins/menus.py` `show_row_context_menu()`: add "Install Hooks" action when `hooks_installed` is false. Call `wt-deploy-hooks` via subprocess and trigger refresh.

## 6. Tests

- [x] 6.1 Add test for GUI hook warning tooltip display when hooks_installed is false
- [x] 6.2 Add test for context menu showing "Install Hooks" when hooks_installed is false and hiding it when true
- [x] 6.3 Run full GUI test suite to verify no regressions
