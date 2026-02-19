## ADDED Requirements

### Requirement: Migrate subcommand
`wt-memory migrate` SHALL run all pending memory storage migrations. `wt-memory migrate --status` SHALL display migration history.

#### Scenario: Run pending migrations
- **WHEN** user runs `wt-memory migrate`
- **THEN** all pending migrations are applied in numbered order
- **AND** stdout prints each migration: `001: branch-tags — applied`

#### Scenario: Show migration status
- **WHEN** user runs `wt-memory migrate --status`
- **THEN** stdout lists all known migrations with applied/pending status

#### Scenario: Migrate with shodh-memory not installed
- **WHEN** shodh-memory is not installed
- **AND** user runs `wt-memory migrate`
- **THEN** the command exits 0 silently

### Requirement: Updated usage text
The `usage()` function SHALL include the `migrate` subcommand in its output.

#### Scenario: Help text includes migrate
- **WHEN** user runs `wt-memory --help`
- **THEN** output includes the `migrate` and `migrate --status` commands
