## ADDED Requirements

### Requirement: Cross-project worktree resolution

The `wt-loop` commands `monitor`, `status`, `stop`, and `history` SHALL resolve a change-id across all registered projects, not just the current project.

Resolution order:
1. Current project (from CWD or `-p` flag) — fast path
2. All registered projects in `projects.json` — fallback scan

The `find_worktree_across_projects()` helper in `wt-common.sh` SHALL implement this logic and be used by the affected commands.

#### Scenario: Change-id found in different project

- **WHEN** user runs `wt-loop monitor <change-id>` from project A's directory
- **AND** the change-id belongs to a worktree in project B
- **THEN** the command SHALL find and operate on project B's worktree

#### Scenario: Change-id found in current project

- **WHEN** user runs `wt-loop status <change-id>` from the project that owns that worktree
- **THEN** the command SHALL find the worktree via the fast path (no cross-project scan)

#### Scenario: Change-id not found anywhere

- **WHEN** user runs `wt-loop stop <change-id>` and no registered project has a matching worktree
- **THEN** the command SHALL exit with error "Worktree not found for: <change-id>"
