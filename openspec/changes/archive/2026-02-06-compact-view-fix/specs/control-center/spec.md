## REMOVED Requirements

### Requirement: Window Focus
**Reason**: Editor window detection via xdotool is replaced by agent-status-based filtering. The `wt-focus` CLI command still works independently; only the GUI mixin for editor detection is removed.
**Migration**: The filter button now uses `agent.status` from worktree data instead of detecting editor windows.

## ADDED Requirements

### Requirement: Active Worktree Filter
The GUI SHALL provide a filter button that shows only actively worked-on worktrees.

#### Scenario: Toggle compact view
- **WHEN** the user clicks the 🖥️ filter button
- **THEN** the table shows only worktrees with `agent.status` of running, waiting, or compacting (including main repo if active)
- **AND** idle worktrees and team rows are hidden

#### Scenario: Filter re-evaluates on refresh
- **WHEN** the filter is active and the status data refreshes
- **THEN** the visible rows update to reflect current agent statuses
- **AND** no additional external process calls are needed

#### Scenario: Disable filter
- **WHEN** the user clicks the 🖥️ filter button while it is checked
- **THEN** all worktrees (including idle, main repo, and team) are shown again

#### Scenario: Button tooltip
- **WHEN** the user hovers over the 🖥️ filter button
- **THEN** the tooltip reads "Show only active worktrees"
