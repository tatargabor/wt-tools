## ADDED Requirements

### Requirement: Worktree Skill Definition
The system SHALL provide a Claude Code skill at `.claude/skills/wt.md` that documents all wt-* commands for agent invocation.

#### Scenario: Skill file exists and is loadable
- **WHEN** Claude Code loads skills from the project
- **THEN** the wt skill SHALL be available for invocation

### Requirement: Central Control Mode
The system SHALL support a central agent managing multiple worktrees from the main repository.

#### Scenario: List active worktrees
- **WHEN** agent invokes `/wt list`
- **THEN** the skill SHALL execute `wt-list` and return active worktree information

#### Scenario: Create new worktree
- **WHEN** agent invokes `/wt new <change-id>`
- **THEN** the skill SHALL execute `wt-new <change-id>` and report the created worktree path

#### Scenario: Open worktree for work
- **WHEN** agent invokes `/wt work <change-id>`
- **THEN** the skill SHALL execute `wt-work <change-id>` to launch a new agent session in that worktree

#### Scenario: Close a worktree
- **WHEN** agent invokes `/wt close <change-id>`
- **THEN** the skill SHALL execute `wt-close <change-id>` with appropriate options

### Requirement: Self-Control Mode
The system SHALL allow an agent running inside a worktree to manage its own lifecycle.

#### Scenario: Detect worktree context
- **WHEN** skill is invoked from within a worktree (not main repo)
- **THEN** the skill SHALL detect the current change-id from the branch name

#### Scenario: Push current branch
- **WHEN** agent in worktree invokes `/wt push`
- **THEN** the skill SHALL execute `git push -u origin <current-branch>`

#### Scenario: Close own worktree
- **WHEN** agent in worktree invokes `/wt close-self`
- **THEN** the skill SHALL provide instructions to close the current worktree after agent exits

#### Scenario: Merge own worktree
- **WHEN** agent in worktree invokes `/wt merge-self`
- **THEN** the skill SHALL execute `wt-merge` for the current change-id

### Requirement: Command Documentation
The skill file SHALL document all available commands with usage examples and expected outputs.

#### Scenario: Help information available
- **WHEN** agent reads the skill file
- **THEN** it SHALL find complete documentation for all supported commands
