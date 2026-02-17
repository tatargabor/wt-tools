## Why

`wt-project init` only registers the project in `projects.json`. It doesn't deploy hooks, `/wt:*` commands, or wt skills to the project's `.claude/` directory. Currently these are deployed via global symlinks (`~/.claude/commands/wt`) by `install.sh`, which means all projects share one version — breaking when different projects need different wt-tools versions. There's no single command to set up or update a project's wt-tools integration.

## What Changes

- Enhance `wt-project init` to also deploy the full wt-tools `.claude/` stack to the target project:
  - Hooks → `.claude/settings.json` (via existing `wt-deploy-hooks`)
  - Commands → `.claude/commands/wt/` (copy from wt-tools repo)
  - Skills → `.claude/skills/wt/` (copy from wt-tools repo)
- Re-running `wt-project init` on an already-registered project skips registration but updates all deployed files (idempotent update)
- Remove global symlinks from `install.sh`'s `install_skills()` — per-project deployment replaces them

## Capabilities

### New Capabilities
- `project-init-deploy`: Per-project deployment of wt-tools hooks, commands, and skills via `wt-project init`

### Modified Capabilities
- `worktree-tools`: `wt-project init` gains deployment behavior; re-running on existing project triggers update

## Impact

- `bin/wt-project`: `cmd_init` enhanced with deploy logic
- `install.sh`: `install_skills()` no longer creates `~/.claude/commands/wt` and `~/.claude/skills/wt` global symlinks; `install_project_hooks()` folded into the new per-project deploy
- User projects get `.claude/commands/wt/` and `.claude/skills/wt/` as copied files (not symlinks)
