## RENAMED Requirements

### Requirement: Broadcast Skill
FROM: `/context broadcast`
TO: `/wt:broadcast`

### Requirement: Status Skill
FROM: `/context status`
TO: `/wt:status`

## MODIFIED Requirements

### Requirement: Broadcast Skill

The system SHALL provide a `/wt:broadcast` skill for agents to announce their current work.

#### Scenario: Set broadcast message

- **GIVEN** an agent is working in a worktree
- **WHEN** the agent runs `/wt:broadcast "Adding Google OAuth provider"`
- **THEN** `.claude/activity.json` is updated with `broadcast: "Adding Google OAuth provider"`
- **AND** `updated_at` is set to current time

#### Scenario: Broadcast overwrites previous

- **GIVEN** `.claude/activity.json` has `broadcast: "old message"`
- **WHEN** the agent runs `/wt:broadcast "new message"`
- **THEN** `broadcast` is replaced with "new message"
- **AND** other fields (skill, skill_args) are preserved

### Requirement: Status Skill

The system SHALL provide a `/wt:status` skill to display all agents' current activities.

#### Scenario: Show local agents' activity

- **GIVEN** Agent-A (worktree-1) has activity: skill=opsx:apply, broadcast="Adding OAuth"
- **AND** Agent-B (worktree-2) has activity: skill=opsx:explore
- **WHEN** any agent runs `/wt:status`
- **THEN** output shows both agents' activities with worktree path, skill, broadcast, and relative timestamp

#### Scenario: Show remote agents' activity

- **GIVEN** team-sync is enabled
- **AND** remote member "peter@laptop" has activity in `members/peter@laptop.json`
- **WHEN** agent runs `/wt:status`
- **THEN** output includes remote member's activity
- **AND** remote entries are marked with source indicator (e.g., "(remote)")

#### Scenario: Show unread message count in status

- **GIVEN** agent has 3 unread directed messages
- **WHEN** agent runs `/wt:status`
- **THEN** output includes "3 unread messages" indicator
- **AND** suggests running `/wt:inbox` to read them

#### Scenario: Stale activity detection

- **GIVEN** an activity file has `updated_at` older than 5 minutes
- **WHEN** `/wt:status` displays this entry
- **THEN** the entry is shown with "(stale)" indicator

#### Scenario: No activity anywhere

- **GIVEN** no activity files exist locally
- **AND** no team members have activity data
- **WHEN** agent runs `/wt:status`
- **THEN** output shows "No active agents found"
