## Why

When `wt-new` creates a worktree, the `.claude/settings.json` (which contains hook configuration for skill tracking) is not copied to the new worktree directory. This file is untracked by git, so git worktree creation doesn't include it. As a result, agents running in worktrees have no skill tracking — `wt-status` never shows which skill an agent is running, and the GUI skill column stays empty. This silently degrades the user experience with no indication of what's wrong.

## What Changes

- **`wt-new` deploys hooks on worktree creation**: After creating a git worktree, copy/deploy `.claude/settings.json` hook config from the main repo to the new worktree.
- **`wt-status` detects missing hooks**: Add a `hooks_installed` boolean field per worktree in JSON output. Check for `.claude/settings.json` existence and presence of expected hook entries.
- **GUI shows missing hooks warning**: Worktrees with `hooks_installed: false` show a visual indicator (e.g., tooltip warning). Context menu offers "Install Hooks" action to deploy hooks to the worktree.
- **Standalone `wt-deploy-hooks` script**: Extract hook deployment logic from `install.sh` into a reusable script that can target a specific directory, used by both `wt-new` and the GUI action.

## Capabilities

### New Capabilities

- `hook-auto-install`: Automatic hook deployment to worktrees and detection of missing hooks

### Modified Capabilities

- `skill-tracking-hooks`: Add requirement for hook deployment on worktree creation, not just on project registration

## Impact

- `bin/wt-new`: Call hook deployment after worktree creation
- `bin/wt-status`: Add `hooks_installed` field to worktree JSON output
- `bin/wt-deploy-hooks` (new): Reusable hook deployment script
- `install.sh`: Refactor `deploy_project_hooks()` to use `wt-deploy-hooks`
- `gui/control_center/mixins/menus.py`: Add "Install Hooks" context menu action
- `gui/control_center/mixins/table.py`: Show hook warning indicator
