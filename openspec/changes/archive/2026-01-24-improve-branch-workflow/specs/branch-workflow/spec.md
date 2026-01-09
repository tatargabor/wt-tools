# Branch Workflow Capability

## MODIFIED Requirements

### Requirement: wt-close branch handling
wt-close SHALL provide interactive choice for branch deletion when closing a worktree.

#### Scenario: Interactive close without flags
Given a worktree exists for change-id "add-feature"
When user runs `wt-close add-feature`
Then show prompt with options:
  - "Remove worktree only (branch stays)"
  - "Delete local branch too"
  - "Delete remote branch too" (only if remote exists)
And execute the selected action

#### Scenario: Close with --keep-branch flag
Given a worktree exists for change-id "add-feature"
When user runs `wt-close add-feature --keep-branch`
Then remove only the worktree
And keep both local and remote branches

#### Scenario: Close with --force flag
Given a worktree exists for change-id "add-feature"
When user runs `wt-close add-feature --force`
Then remove worktree and delete local branch without prompting
And do not delete remote branch

---

### Requirement: wt-list remote branches
wt-list MUST support listing remote change branches with --remote flag.

#### Scenario: List remote change branches
Given remote has branches "origin/change/feature-a" and "origin/change/feature-b"
And local worktree exists only for "feature-a"
When user runs `wt-list --remote`
Then show remote change branches
And indicate which ones have local worktrees

---

### Requirement: wt-work remote branch checkout
wt-work MUST checkout existing remote branches instead of creating duplicates.

#### Scenario: Work on existing remote branch
Given "origin/change/add-auth" exists on remote
And no local branch or worktree for "add-auth" exists
When user runs `wt-work add-auth`
Then create worktree with branch tracking "origin/change/add-auth"
And inform user: "Checking out existing remote branch"

#### Scenario: Work on new change (no remote)
Given no remote branch "origin/change/new-feature" exists
When user runs `wt-work new-feature`
Then create new local branch "change/new-feature"
And create worktree (current behavior)
