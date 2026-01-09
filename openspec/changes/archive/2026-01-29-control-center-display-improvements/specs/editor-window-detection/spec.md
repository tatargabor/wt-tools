## ADDED Requirements

### Requirement: Detect open editor windows
The system SHALL detect which worktrees have an editor window open using xdotool window search.

#### Scenario: Detect Zed window for worktree
- **WHEN** a Zed window is open with a worktree folder
- **THEN** the system identifies that worktree as having an open editor
- **AND** the window ID is available for focus operations

#### Scenario: Detect VS Code window for worktree
- **WHEN** a VS Code window is open with a worktree folder
- **THEN** the system identifies that worktree as having an open editor

#### Scenario: Detect multiple editor types
- **WHEN** checking for open editors
- **THEN** the system checks for Zed, VS Code, Cursor, and Windsurf windows

#### Scenario: No editor window open
- **WHEN** no editor window is open for a worktree
- **THEN** the system reports that worktree has no open editor

### Requirement: Editor detection caching
The system SHALL cache editor detection results to avoid repeated xdotool calls during a single render cycle.

#### Scenario: Cache during table render
- **WHEN** the worktree table is being rendered
- **THEN** editor detection runs once and results are cached
- **AND** subsequent checks for the same worktree use cached results

#### Scenario: Cache invalidation on refresh
- **WHEN** user clicks refresh or filter toggle
- **THEN** the editor detection cache is invalidated
- **AND** fresh detection runs on next render
