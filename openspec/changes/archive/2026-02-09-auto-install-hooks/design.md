## Context

Claude Code hooks are configured in `.claude/settings.json` at the project root. When `install.sh` or `wt-add` runs, hooks are deployed to the main repo. However, git worktrees are separate working directories, and `.claude/settings.json` is an untracked file — it doesn't propagate to worktrees automatically.

The current `deploy_project_hooks()` function in `install.sh` (line 516) handles the full hook deployment logic: creating the directory, merging JSON config, backing up existing files. This logic needs to be reusable from `wt-new` and the GUI.

## Goals / Non-Goals

**Goals:**
- Hooks are automatically deployed when `wt-new` creates a worktree
- Users can see at a glance which worktrees are missing hooks
- One-click fix from the GUI context menu
- Reusable deployment script callable from multiple contexts

**Non-Goals:**
- Changing hook configuration format
- Auto-deploying to existing worktrees without user action (except via wt-new)
- Monitoring hook health beyond presence check (e.g., verifying hooks actually fire)

## Decisions

### Decision 1: Create `bin/wt-deploy-hooks` as the single deployment entrypoint

**Rationale**: The `deploy_project_hooks()` logic in `install.sh` is ~55 lines of bash that handles directory creation, JSON merging, backups, and idempotency. Rather than duplicating this in `wt-new`, extract it to a standalone script. Both `install.sh`, `wt-new`, and the GUI "Install Hooks" action call the same script.

**Interface**: `wt-deploy-hooks <target-dir>` — deploys hooks to `<target-dir>/.claude/settings.json`.

**Alternative considered**: Symlink `.claude/settings.json` from worktree to main repo. Rejected because worktrees may need different settings (e.g., different CLAUDE.md, commands), and symlinks cause issues with some tools.

### Decision 2: `hooks_installed` field in wt-status JSON

**Rationale**: `wt-status` already walks each worktree directory. Adding a simple file existence + JSON content check is minimal overhead. The GUI can react to this boolean without needing its own file checking logic.

**Detection logic**: Check if `<worktree>/.claude/settings.json` exists AND contains both `hooks.UserPromptSubmit` and `hooks.Stop` entries.

### Decision 3: GUI indicator via tooltip + context menu, not a separate column

**Rationale**: A dedicated column for a rare state (missing hooks) wastes horizontal space. Instead: show a warning icon/tooltip on the status cell, and add "Install Hooks" to the right-click context menu when `hooks_installed` is false. Keep the UI clean.

### Decision 4: `wt-new` deploys hooks from main repo, not from template

**Rationale**: The main repo's `.claude/settings.json` may have user-customized hooks. Copying the hooks section from main repo is better than deploying a fresh template (which could overwrite user additions). `wt-deploy-hooks` checks and merges, so existing worktree settings are preserved.

## Risks / Trade-offs

- [Race condition on wt-new] → Minimal — worktree creation is synchronous and hooks deploy immediately after.
- [Main repo has no settings.json] → `wt-deploy-hooks` falls back to creating fresh hook config from template, same as `install.sh` does today.
- [Performance of hook check in wt-status] → One `jq` call per worktree. With ~10 worktrees this adds ~100ms. Acceptable for a 2s polling interval. Alternatively use simple grep-based check to avoid jq.
