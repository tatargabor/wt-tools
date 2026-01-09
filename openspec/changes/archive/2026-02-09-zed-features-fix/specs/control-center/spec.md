## MODIFIED Requirements

### Requirement: Agent Detection
The system SHALL detect all Claude agent processes associated with worktrees using `ps -e` (not `pgrep`, which skips ancestors on macOS).

#### Scenario: Detect running agent
Given a Claude process is running in a worktree directory
When wt-status checks that worktree
Then the agents array contains an entry with status "running" and the process PID

#### Scenario: Detect compacting agent
Given a Claude process is summarizing context (compacting)
When wt-status checks that worktree
Then the agents array contains an entry with status "compacting"

#### Scenario: Detect waiting agent
Given a Claude process is sleeping (waiting for input)
When wt-status checks that worktree
Then the agents array contains an entry with status "waiting"

#### Scenario: No agent
Given no Claude process exists for a worktree
When wt-status checks that worktree
Then the agents array is empty

#### Scenario: Multiple agents detected
Given two or more Claude processes have CWD in a worktree directory
When wt-status checks that worktree
Then the agents array contains one entry per process with independent status, skill, and PID

#### Scenario: CWD path-boundary matching
Given worktrees at /code/foo and /code/foo-bar
When a process has CWD /code/foo-bar
Then it matches only /code/foo-bar, not /code/foo

#### Scenario: Orphan agents excluded from output
- **WHEN** wt-status detects agents in a worktree
- **AND** those agents are "waiting" status
- **AND** no editor window is open for the worktree
- **AND** no Ralph loop is active
- **THEN** the agents are killed and excluded from the agents array

#### Scenario: Editor open status in JSON
- **WHEN** wt-status collects status for a worktree
- **THEN** the JSON entry SHALL include `"editor_open": true|false`
- **AND** the value reflects whether an editor window matching the worktree basename exists

### Requirement: Worktree List Display
The GUI SHALL display worktrees in a 6-column table: Name, PID, Status, Skill, Ctx%, Extra.

#### Scenario: Project grouping
- **GIVEN** worktrees exist across multiple projects
- **WHEN** the Control Center displays the worktree list
- **THEN** worktrees are grouped by project with header rows spanning all columns
- **AND** each agent gets its own row with independent PID, Status, Skill, Ctx%

#### Scenario: Sorting within groups
- **GIVEN** multiple worktrees in a project
- **WHEN** displayed in the list
- **THEN** main repo appears first, then sorted alphabetically by change ID

#### Scenario: Multi-agent rows
- **GIVEN** a worktree has multiple agents
- **WHEN** displayed in the table
- **THEN** each agent is a separate row; primary row has Name + Extra, secondary rows have empty Name/Extra
- **AND** all agent rows map back to the parent worktree for focus/context-menu actions

#### Scenario: Per-agent Ctx%
- **GIVEN** a worktree has N agents with N session files
- **WHEN** Ctx% is calculated
- **THEN** agent[i] reads from the (i+1)th-freshest session file

#### Scenario: Worktree with no editor dimmed
- **WHEN** a worktree has `editor_open: false` in the status data
- **AND** the worktree has no active agents
- **THEN** the row text SHALL be rendered with reduced opacity or gray color
