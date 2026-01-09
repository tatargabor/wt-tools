# Tasks

## wt-close improvements
- [x] Add interactive prompt for branch deletion choice
- [x] Detect if branch exists on remote
- [x] Implement "worktree only" removal option
- [x] Implement "delete local branch" option
- [x] Implement "delete remote branch" option (git push origin --delete)
- [x] Keep --keep-branch and --force flags working
- [x] Add --delete-remote flag for scripted usage

## wt-list remote support
- [x] Add --remote / -r flag to wt-list
- [x] Fetch and list origin/change/* branches
- [x] Show which remote branches have no local worktree

## wt-work/wt-new remote checkout
- [x] Fetch from remote before creating worktree
- [x] Check if origin/change/<id> exists before creating new branch
- [x] If remote exists, checkout and track it instead of creating new
- [x] Inform user when checking out existing remote branch
- [x] Add --new flag to force create new branch even if remote exists
