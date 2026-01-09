# Create New Worktree

Create a new worktree for the given change-id: $ARGUMENTS

```bash
wt-new $ARGUMENTS
```

This creates:
- Worktree at `../<project>-wt-<change-id>/`
- Branch `change/<change-id>`

If the branch exists on remote, it will be checked out and tracked automatically.
