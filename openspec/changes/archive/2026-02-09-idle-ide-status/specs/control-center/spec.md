## ADDED Requirements

### Requirement: Idle IDE status display

The GUI SHALL display a distinct "idle (IDE)" status with icon `◇` for worktrees where the editor is open but no Claude agent is running.

#### Scenario: Editor open, no agent
- **WHEN** a worktree has `editor_open=true` and an empty agents array
- **THEN** the status column shows `◇ idle (IDE)` with a muted blue color
- **AND** the row uses `row_idle_ide` background and `row_idle_ide_text` text color

#### Scenario: Editor closed, no agent
- **WHEN** a worktree has `editor_open=false` and an empty agents array
- **THEN** the status column shows `○ idle` with the existing idle gray color
- **AND** the row uses muted/dimmed styling (existing behavior)

#### Scenario: Editor open with agents
- **WHEN** a worktree has `editor_open=true` and agents in the array
- **THEN** the agent statuses (running/waiting/compacting/orphan) are displayed as normal
- **AND** the `idle (IDE)` status is NOT shown (agent status takes precedence)

#### Scenario: Color profile support
- **WHEN** any of the 4 color profiles is active (light, dark, gray, high_contrast)
- **THEN** `status_idle_ide`, `row_idle_ide`, and `row_idle_ide_text` colors are defined and visible
