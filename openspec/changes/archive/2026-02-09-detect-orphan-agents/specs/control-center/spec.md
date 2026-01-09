## ADDED Requirements

### Requirement: Orphan Agent Detection
The system SHALL detect orphan `claude` processes — those whose parent process is not a known shell (zsh, bash, fish, sh, dash) — and classify them with status `"orphan"` in the `wt-status` JSON output.

#### Scenario: Detect orphan agent
- **WHEN** a `claude` process has CWD in a worktree directory
- **AND** its parent process (PPID) is not a shell (zsh, bash, fish, sh, dash, or their login-shell variants with `-` prefix)
- **THEN** the agent entry in the JSON output SHALL have `"status": "orphan"`

#### Scenario: Normal agent not classified as orphan
- **WHEN** a `claude` process has CWD in a worktree directory
- **AND** its parent process is a known shell (e.g., zsh, -zsh, bash, -bash)
- **THEN** the agent entry SHALL retain its normal status (running, compacting, or waiting)

#### Scenario: Orphan agent in summary counts
- **WHEN** orphan agents exist
- **THEN** they SHALL NOT be counted in the `running`, `compacting`, or `waiting` summary totals

### Requirement: Orphan Agent Display
The GUI SHALL display orphan agents with distinct visual styling to differentiate them from active agents.

#### Scenario: Orphan row background color
- **WHEN** an agent row has `"status": "orphan"`
- **THEN** the row background SHALL use the `row_orphan` color from the active color profile

#### Scenario: Orphan PID warning icon
- **WHEN** an agent row has `"status": "orphan"`
- **THEN** the PID column SHALL display `⚠ <pid>` (warning icon followed by the PID number)

#### Scenario: Orphan status icon
- **WHEN** an agent row has `"status": "orphan"`
- **THEN** the Status column SHALL display `⚠ orphan` with the `status_orphan` color

#### Scenario: Orphan color in all profiles
- **WHEN** any color profile is active (light, dark, gray, high_contrast)
- **THEN** the profile SHALL include `row_orphan`, `row_orphan_text`, and `status_orphan` color values

### Requirement: Kill Orphan Process
The GUI SHALL allow users to terminate orphan agent processes via the row context menu.

#### Scenario: Kill menu item appears for orphan rows
- **WHEN** the user right-clicks on a worktree row
- **AND** the agent for that row has `"status": "orphan"`
- **THEN** the context menu SHALL include a "⚠ Kill Orphan Process" action

#### Scenario: Kill menu item hidden for non-orphan rows
- **WHEN** the user right-clicks on a worktree row
- **AND** the agent for that row does NOT have `"status": "orphan"`
- **THEN** the context menu SHALL NOT include the "⚠ Kill Orphan Process" action

#### Scenario: Kill sends SIGTERM
- **WHEN** the user clicks "⚠ Kill Orphan Process"
- **THEN** the system SHALL send SIGTERM to the orphan process PID
- **AND** the orphan row SHALL disappear on the next status refresh

#### Scenario: Kill handles already-dead process
- **WHEN** the user clicks "⚠ Kill Orphan Process"
- **AND** the process has already exited
- **THEN** no error SHALL be shown to the user

## MODIFIED Requirements

### Requirement: Agent Detection
The system SHALL detect all Claude agent processes associated with worktrees using `ps -e` (not `pgrep`, which skips ancestors on macOS). For each detected process, the system SHALL check the parent process (PPID) to determine if the agent is orphaned.

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

#### Scenario: Detect orphan agent
Given a Claude process exists in a worktree directory
When wt-status checks that worktree
And the process's parent is not a known shell
Then the agents array contains an entry with status "orphan" and the process PID

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

### Requirement: Visual Status Indicators
The GUI SHALL provide visual indicators for agent status on each row independently.

#### Scenario: Running row pulse animation
- **GIVEN** an agent row has "running" status
- **WHEN** displayed in the table
- **THEN** that specific row background pulses with green opacity animation (1s cycle)

#### Scenario: Compacting row indicator
- **GIVEN** an agent row has "compacting" status
- **WHEN** displayed in the table
- **THEN** the row has purple background with ⟳ icon

#### Scenario: Waiting row with attention blink
- **GIVEN** any agent on a worktree transitions to "waiting" and needs attention
- **WHEN** displayed in the table
- **THEN** the worktree's primary row background blinks between yellow and red

#### Scenario: Orphan row indicator
- **GIVEN** an agent row has "orphan" status
- **WHEN** displayed in the table
- **THEN** the row has gray background with ⚠ icon and muted text color

#### Scenario: Status colors by theme
- **GIVEN** the user selects a color profile (light/gray/dark/high_contrast)
- **WHEN** worktrees are displayed
- **THEN** status colors match the selected profile:
  - running: green
  - compacting: purple/magenta
  - waiting: yellow/amber
  - orphan: gray
  - idle: gray (lighter than orphan)

#### Scenario: Theme applies immediately
- **GIVEN** the user changes color profile in Settings
- **WHEN** clicking Apply or OK
- **THEN** window background and all elements update immediately
