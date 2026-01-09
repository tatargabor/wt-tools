# Change: Add Worktree Tools for Parallel Spec Development

JIRA Key: EXAMPLE-524
Story: EXAMPLE-466

## Why
In OpenSpec-driven development, it's often necessary to work on multiple specs in parallel. Using git worktrees solves this cleanly, but the manual steps for worktree management slow down the workflow. Simple CLI tools are needed to automate worktree creation, editor launching, and tool availability.

## What Changes
- New `wt-project` script: multi-project management
  - `wt-project init [--name <name>]` - register current git repo (run from within the repo)
  - `wt-project list` - list registered projects
  - `wt-project remove <name>` - remove project from registry
  - `wt-project default <name>` - set default project
- New `wt-open` script: create worktree for a given change-id + `openspec init` if needed
- New `wt-edit` script: launch Zed editor in the worktree directory
- New `wt-list` script: list active worktrees (per project or all)
- New `wt-close` script: delete worktree
- `install` script:
  - Make tools available in PATH (symlink or PATH extension)
  - Install dependencies: Claude Code CLI, openspec CLI, Zed editor
- Cross-platform support: Linux, Windows (Git Bash/WSL), macOS
- Config file: `~/.config/wt-tools/projects.json` - project registry

## Impact
- Affected specs: worktree-tools (new capability)
- Affected code: `bin/` directory (new scripts)
