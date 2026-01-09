# Tasks

## Implementation

- [x] Create `bin/wt-version` script
  - Follow symlink to find source directory
  - Read git branch, commit, date from source repo
  - Support `--json` flag for machine-readable output
  - Handle error cases (broken symlink, not a git repo)
  - Support git worktrees (.git file instead of directory)

- [x] Update `install.sh` to include wt-version in scripts list

## Validation

- [x] Test: `wt-version` shows correct branch/commit/date
- [x] Test: `wt-version --json` outputs valid JSON
- [x] Test: Reinstall and verify wt-version is linked
