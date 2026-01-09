# Team Sync Capability - Bug Fixes

## ADDED Requirements

### Requirement: Remote Worktree Display Format
Remote worktrees in the table SHALL display the full `user@hostname:` prefix in the first column to distinguish between different machines of the same user.

#### Scenario: Remote worktree from same user different machine
- **GIVEN** user "gabor" has worktrees on machines "laptop" and "desktop"
- **WHEN** viewing the Control Center table
- **THEN** remote worktrees show "gabor@laptop:" and "gabor@desktop:" prefixes

#### Scenario: Remote worktree from different user
- **GIVEN** user "peter" has a worktree on machine "workstation"
- **WHEN** viewing the Control Center table
- **THEN** remote worktree shows "peter@workstation:" prefix

### Requirement: Project Discovery from Worktrees
The TeamWorker SHALL discover project paths from the current worktree list, not solely from projects.json configuration.

#### Scenario: Project not in projects.json but has worktrees
- **GIVEN** a project "aitools" has worktrees visible in wt-status
- **AND** "aitools" is not listed in projects.json
- **AND** team sync is enabled for aitools remote_url
- **WHEN** TeamWorker runs sync
- **THEN** aitools worktrees are included in team data

#### Scenario: Project path discovered from worktree
- **GIVEN** a worktree has remote_url matching an enabled team project
- **WHEN** TeamWorker needs the project path for wt-control-sync
- **THEN** the worktree path's parent directory is used as project path

## MODIFIED Requirements

### Requirement: Team Member Chat Key Visibility
Team members with chat encryption keys SHALL appear in the chat recipient dropdown when team sync is enabled.

#### Scenario: Member has chat public key
- **GIVEN** team member "peter@desktop" has generated a chat keypair
- **AND** peter's member.json includes `chat_public_key` field
- **WHEN** opening the Chat dialog
- **THEN** "peter@desktop" appears in the recipient dropdown

#### Scenario: Member without chat key
- **GIVEN** team member "anna@laptop" has NOT generated a chat keypair
- **WHEN** opening the Chat dialog
- **THEN** "anna@laptop" does NOT appear in the recipient dropdown

#### Scenario: No members have chat keys
- **GIVEN** no team members have generated chat keypairs
- **WHEN** opening the Chat dialog
- **THEN** dropdown shows "No recipients with chat keys"
- **AND** send button is disabled

### Requirement: Project Identification by Remote URL
All team-related functions SHALL use the git remote URL as the unique project identifier, not the local project directory name.

#### Scenario: Same repo with different local names
- **GIVEN** user A has project cloned to ~/code/myproject
- **AND** user B has same repo cloned to ~/projects/the-project
- **WHEN** both enable team sync for the same remote URL
- **THEN** their worktrees appear together in team view

#### Scenario: Team settings stored by remote URL
- **GIVEN** a project with remote URL "ssh://git@server/repo.git"
- **WHEN** enabling team sync in Team Settings dialog
- **THEN** settings are stored under the remote URL key, not project name

#### Scenario: Multiple projects same remote
- **GIVEN** multiple local directories pointing to the same remote URL
- **WHEN** viewing team settings
- **THEN** all share the same team enabled/disabled state
