## MODIFIED Requirements

### Requirement: Agent Detection
The system SHALL detect Claude agent processes associated with worktrees.

#### Scenario: Detect running agent
Given a Claude process is running in a worktree directory
When wt-status checks that worktree
Then the agent status shows "running" with PID in the agents array

#### Scenario: Detect compacting agent
Given a Claude process is summarizing context (compacting)
When wt-status checks that worktree
Then the agent status shows "compacting" with PID in the agents array

#### Scenario: Detect waiting agent
Given a Claude process is sleeping (waiting for input)
When wt-status checks that worktree
Then the agent status shows "waiting" with PID in the agents array

#### Scenario: No agent
Given no Claude process exists for a worktree
When wt-status checks that worktree
Then the agents array is empty

#### Scenario: Multiple agents detected
Given two or more Claude processes exist for a worktree
When wt-status checks that worktree
Then the agents array contains one entry per process with independent status

### Requirement: Worktree List Display
The GUI SHALL display worktrees grouped by project with visual separators.

#### Scenario: Project grouping
- **GIVEN** worktrees exist across multiple projects
- **WHEN** the Control Center displays the worktree list
- **THEN** worktrees are grouped by project
- **AND** project name is shown in the Name column header row

#### Scenario: Table columns
- **GIVEN** the table is displayed
- **WHEN** rendering column headers
- **THEN** the columns are: Name, PID, Status, Skill, Ctx%, Extra (6 total)
- **AND** Name merges former "Project" and "Change" columns
- **AND** PID shows the claude process ID per agent row

#### Scenario: Name column content for worktree rows
- **GIVEN** a local worktree row is rendered
- **WHEN** the Name column is populated
- **THEN** it shows the change ID / branch name (with star prefix for main repo)

#### Scenario: Name column content for team rows
- **GIVEN** a team worktree row is rendered
- **WHEN** the Name column is populated
- **THEN** it shows `member: change_id` (with lightning prefix for own machines)

#### Scenario: Extra column replaces J column
- **GIVEN** the table is displayed
- **WHEN** rendering the last column
- **THEN** the column header is "Extra" instead of "J"
- **AND** it contains Ralph indicator (R button)

#### Scenario: Sorting within groups
- **GIVEN** multiple worktrees in a project
- **WHEN** displayed in the list
- **THEN** they are sorted alphabetically by change ID

### Requirement: Multi-Agent Row Display
The GUI SHALL display separate rows for each agent when multiple agents run on the same worktree.

#### Scenario: Single agent row
- **WHEN** a worktree has exactly one agent
- **THEN** the worktree is displayed as a single row with Name, Status, Skill, Ctx%, and Extra columns populated

#### Scenario: Multiple agent rows
- **WHEN** a worktree has N agents (N > 1)
- **THEN** the worktree is displayed as N rows
- **AND** each row has its own PID, Status, Skill, and Ctx% (per-agent session file matching)
- **AND** the first row additionally has the Name (branch label) and Extra column
- **AND** subsequent rows have empty Name and Extra

#### Scenario: Agent row visual distinction
- **WHEN** a secondary agent row is rendered (not the first agent for a worktree)
- **THEN** the row has empty Name column and its own PID, making it visually subordinate but identifiable

#### Scenario: Per-agent context usage
- **WHEN** a worktree has multiple agents
- **THEN** each agent row shows its own Ctx% from the Nth-freshest session file (matching detect_agents order)

#### Scenario: Row background colors for agent rows
- **WHEN** an agent row has status "running"
- **THEN** the row background pulses green (same animation as current worktree rows)

#### Scenario: Focus action from agent row
- **WHEN** the user double-clicks or uses "Focus Window" on any agent row (primary or secondary)
- **THEN** the Zed window for the parent worktree is focused (not individual agent terminals)

### Requirement: Active Worktree Filter
The GUI SHALL provide a filter button that shows only actively worked-on worktrees.

#### Scenario: Toggle compact view
- **WHEN** the user clicks the filter button
- **THEN** the table shows only worktrees that have at least one non-idle agent
- **AND** ALL agents for visible worktrees are shown (not just non-idle ones)
- **AND** idle worktrees with no agents are hidden

#### Scenario: Filter re-evaluates on refresh
- **WHEN** the filter is active and the status data refreshes
- **THEN** the visible rows update to reflect current agent statuses

#### Scenario: Disable filter
- **WHEN** the user clicks the filter button while it is checked
- **THEN** all worktrees (including idle and team) are shown again

### Requirement: Visual Status Indicators
The GUI SHALL provide visual indicators for worktree status.

#### Scenario: Running row pulse animation
- **GIVEN** an agent has "running" status
- **WHEN** displayed in the table
- **THEN** the row background pulses with green opacity animation (1s cycle)

#### Scenario: Compacting row indicator
- **GIVEN** an agent has "compacting" status
- **WHEN** displayed in the table
- **THEN** the row has purple background with icon

#### Scenario: Waiting row with attention blink
- **GIVEN** any agent on a worktree transitions to "waiting" and needs attention
- **WHEN** displayed in the table
- **THEN** the worktree's primary row background blinks between yellow and red

#### Scenario: Status colors by theme
- **GIVEN** the user selects a color profile
- **WHEN** agent rows are displayed
- **THEN** status colors match the selected profile
