## ADDED Requirements

### Requirement: Automatic Worklog Generation
The system SHALL automatically generate JIRA worklog entries based on git activity for a specified date.

#### Scenario: Generate worklog for today
- **WHEN** user runs `wt-jira auto`
- **THEN** the system collects all commits from today across all worktrees
- **AND** calculates work intervals based on commit timestamps
- **AND** allocates time proportionally to each task
- **AND** displays a summary of proposed worklogs

#### Scenario: Generate worklog for specific date
- **WHEN** user runs `wt-jira auto --date 2024-01-15`
- **THEN** the system collects all commits from January 15, 2024
- **AND** calculates and displays worklogs for that date

#### Scenario: Generate worklog for relative date
- **WHEN** user runs `wt-jira auto --date yesterday`
- **THEN** the system parses "yesterday" as the previous calendar day
- **AND** generates worklogs for that date

### Requirement: Multi-Machine Activity Sync
The system SHALL support collecting activity from multiple machines via remote git branches.

#### Scenario: Fetch remote activity before calculation
- **WHEN** user runs `wt-jira auto --fetch`
- **THEN** the system executes `git fetch --all` on all worktrees
- **AND** includes commits from remote branches in the calculation

#### Scenario: Activity from multiple machines
- **WHEN** commits exist on remote branches that are not in local history
- **AND** user runs `wt-jira auto --fetch`
- **THEN** the system includes those commits in the worklog calculation

### Requirement: Parallel Work Time Allocation
The system SHALL fairly allocate time when multiple tasks have overlapping activity periods.

#### Scenario: Two tasks with overlapping intervals
- **WHEN** Task A has activity from 09:00-12:00
- **AND** Task B has activity from 10:00-14:00
- **THEN** the overlapping period 10:00-12:00 is split equally between tasks
- **AND** Task A receives time for 09:00-10:00 plus half of 10:00-12:00
- **AND** Task B receives half of 10:00-12:00 plus time for 12:00-14:00

#### Scenario: Three or more overlapping tasks
- **WHEN** multiple tasks have overlapping activity periods
- **THEN** the overlapping time is divided equally among all active tasks

### Requirement: Gap Analysis
The system SHALL display a gap analysis comparing git activity to the daily target hours without automatic deductions.

#### Scenario: Show gap to daily target
- **WHEN** user runs `wt-jira auto`
- **AND** git activity totals 5h 30m
- **AND** daily target is configured as 8h
- **THEN** the system displays "Git activity: 5h 30m"
- **AND** displays "Daily target: 8h"
- **AND** displays "Gap: 2h 30m"
- **AND** suggests manual logging for meetings/other work

#### Scenario: No gap when target reached
- **WHEN** git activity equals or exceeds the daily target
- **THEN** the system displays the activity total
- **AND** indicates the target has been reached
- **AND** does not show a gap warning

#### Scenario: Configurable daily target
- **WHEN** configuration specifies dailyTarget: "7h"
- **THEN** the gap calculation uses 7 hours as the target
- **AND** default is 8h if not configured

### Requirement: Dry Run Mode
The system SHALL support a preview mode that displays proposed worklogs without submitting them.

#### Scenario: Preview worklogs without submission
- **WHEN** user runs `wt-jira auto --dry-run`
- **THEN** the system displays all proposed worklogs
- **AND** does not submit anything to JIRA
- **AND** displays instructions for actual submission

#### Scenario: Default behavior is dry-run
- **WHEN** user runs `wt-jira auto` without --yes flag
- **THEN** the system operates in dry-run mode
- **AND** prompts for confirmation before submission

### Requirement: Worklog Submission
The system SHALL submit worklogs to JIRA via the REST API.

#### Scenario: Submit worklogs after confirmation
- **WHEN** user runs `wt-jira auto --yes`
- **THEN** the system submits all calculated worklogs to JIRA
- **AND** displays success/failure status for each submission

#### Scenario: Interactive submission
- **WHEN** user runs `wt-jira auto --interactive`
- **THEN** the system prompts for each task individually
- **AND** allows user to modify time before submission
- **AND** allows user to skip individual tasks

#### Scenario: Duplicate detection
- **WHEN** user has already logged time to a task for the specified date
- **THEN** the system warns about existing worklogs
- **AND** asks for confirmation before adding duplicate entries

### Requirement: Project Filtering
The system SHALL support filtering worklogs by project.

#### Scenario: Filter by project key
- **WHEN** user runs `wt-jira auto --project EXAMPLE`
- **THEN** the system only processes worktrees associated with EXAMPLE project
- **AND** ignores worktrees from other projects

### Requirement: Structured Worklog Comments
The system SHALL store structured metadata in worklog comments for tracking and incremental updates.

#### Scenario: Auto-generated worklog comment format
- **WHEN** the system creates a worklog entry
- **THEN** the comment includes a `---wt-auto---` block with delimiters
- **AND** includes the change-id, source, sessions, and total fields
- **AND** preserves any existing user-written content outside the block

#### Scenario: Incremental session update
- **WHEN** user already has a worklog with `---wt-auto---` block for the same task and date
- **AND** runs `wt-jira auto` with new activity (e.g., worked from home after office)
- **THEN** the system detects the existing worklog by the block markers
- **AND** adds a new session inside the block
- **AND** updates the total field and timeSpent value
- **AND** preserves any text outside the `---wt-auto---` block

#### Scenario: Preserve user notes in worklog
- **WHEN** user has manually added notes outside the `---wt-auto---` block
- **AND** runs `wt-jira auto` to update the worklog
- **THEN** the system only modifies content inside the block
- **AND** user notes before and after the block remain unchanged

#### Scenario: Multi-location tracking
- **WHEN** commits originate from different machines (detected via hostname or remote differences)
- **THEN** the system labels sessions with location hints (e.g., "office", "home", "session-1")
- **AND** includes this in the worklog comment for audit purposes

#### Scenario: Audit trail with commit references
- **WHEN** a worklog is created from git activity
- **THEN** the comment includes abbreviated commit hashes for each session
- **AND** allows later verification of the time calculation source

### Requirement: Worklog Configuration
The system SHALL support configuration of worklog calculation parameters.

#### Scenario: Configure daily target
- **WHEN** configuration specifies dailyTarget: "8h"
- **THEN** the gap analysis uses 8 hours as the target
- **AND** default is 8h if not configured

#### Scenario: Configure activity gap threshold
- **WHEN** configuration specifies minActivityGap: "30m"
- **THEN** commits more than 30 minutes apart are treated as separate work blocks

#### Scenario: Configure time rounding
- **WHEN** configuration specifies roundTo: "15m"
- **THEN** all worklog durations are rounded to the nearest 15 minutes
