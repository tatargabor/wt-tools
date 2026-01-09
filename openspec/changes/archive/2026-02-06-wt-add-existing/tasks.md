# Tasks: Add Existing Worktrees/Branches

## Phase 1: wt-add Command (relax to accept git repos)

- [x] Create `wt-add` bash script
  - [x] Detect if current directory is a git worktree
  - [x] Extract worktree info (path, branch, main repo)
  - [x] Derive change-id from directory/branch name
  - [x] Support `--as <change-id>` override
  - [x] Support `--project <name>` to associate with project

- [x] Relax validation: accept any git repo, not just worktrees (D1)
  - [x] Replace `is_worktree()` with `is_git_repo()` check
  - [x] Update error messages for non-git directories

- [x] Adapt get_main_repo logic for non-worktree repos (D2)
  - [x] For worktrees: use existing `get_main_repo_from_worktree()`
  - [x] For regular repos: `main_repo = wt_path`

- [x] Add `is_worktree` flag to registration metadata (D5)
  - [x] Pass `is_worktree` to `register_worktree()`
  - [x] Store in projects.json alongside `added_manually`

- [x] Update usage text and script header

- [x] Register worktree in projects.json
  - [x] Add worktree to project's worktrees section
  - [x] Mark as `added_manually: true`
  - [x] Handle already-registered case gracefully

- [x] Run openspec init if not present
  - [x] Check for openspec/config.yaml
  - [x] Call `openspec init` if missing

- [x] Install script integration
  - [x] Add wt-add to install.sh symlinks

## Phase 2: GUI Integration (D4)

- [x] Add "Add" button to bottom button bar (next to New, Work)
  - [x] Create btn_add in main_window.py
  - [x] Connect to on_add handler
  - [x] Opens folder browser dialog
  - [x] Calls wt-add with selected path
  - [x] Refresh worktree list on success

- [x] Update GUI labels for broader scope (D4)
  - [x] Tooltip: "Add existing worktree" → "Add existing repository or worktree"
  - [x] Dialog title: "Select Existing Worktree" → "Select Git Repository"
  - [x] Command output title: "Adding worktree" → "Adding repository"
