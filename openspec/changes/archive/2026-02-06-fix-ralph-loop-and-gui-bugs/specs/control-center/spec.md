## MODIFIED Requirements

### Requirement: Editor-Specific Window Focus

Double-click on a worktree row SHALL check for an existing IDE window, regardless of agent status.

- If an IDE window exists for the worktree → focus it
- If no IDE window exists → open it via `wt-work`

The decision SHALL be based solely on window presence, not agent status.

#### Scenario: IDE window exists

- **WHEN** user double-clicks a worktree row
- **AND** an editor window matches the worktree folder name
- **THEN** that editor window SHALL be focused

#### Scenario: No IDE window exists

- **WHEN** user double-clicks a worktree row
- **AND** no editor window matches the worktree folder name
- **THEN** `wt-work` SHALL be called to open the worktree in the editor
- **AND** the GUI SHALL NOT block or freeze

#### Scenario: No IDE window with active agent

- **WHEN** user double-clicks a worktree row with an active agent (e.g. Ralph loop)
- **AND** no editor window matches the worktree folder name
- **THEN** `wt-work` SHALL be called to open the worktree in the editor
- **AND** the active agent SHALL NOT be affected
