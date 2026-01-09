# Change: Improve Branch Workflow

JIRA Key: EXAMPLE-526
Story: EXAMPLE-466

## Why
The current worktree tools don't properly handle remote branches:
1. `wt-close` automatically deletes the local branch without asking - this is unintuitive
2. There's no way to list remote `change/*` branches
3. If a change was started on another machine (e.g., `change/add-feature` already exists on remote), `wt-work` creates a new branch instead of checking out the remote one

## What Changes

### wt-close modification
- Interactive mode: ask what to do with the branch
  - "Remove worktree only" - branch stays (can be reopened)
  - "Delete local branch too" - delete local branch
  - "Delete remote branch too" - delete remote branch as well (if exists)
- Keep `--keep-branch` flag (worktree removal only)
- `--force` flag: deletes everything without asking (current behavior)

### wt-list extension
- `wt-list --remote` / `-r`: list remote `change/*` branches
- Shows which remote branches don't have a local worktree

### wt-work modification
- If `change/<id>` exists on remote but not locally: checks out the remote branch
- This enables continuing work started on another machine

## Impact
- Affected code: `bin/wt-close`, `bin/wt-list`, `bin/wt-work`
- No breaking changes - new flags and interactive prompt
