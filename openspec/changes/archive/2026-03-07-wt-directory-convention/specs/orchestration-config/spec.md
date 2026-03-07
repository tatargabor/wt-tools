## MODIFIED Requirements

### Requirement: Standalone orchestration config file
The system SHALL support orchestration directives in `wt/orchestration/config.yaml` as the primary location, with backward-compatible fallback to `.claude/orchestration.yaml`.

#### Scenario: New location config loading
- **WHEN** `wt/orchestration/config.yaml` exists in the project root
- **THEN** the system SHALL parse it as YAML and extract directive values

#### Scenario: Fallback to legacy location
- **WHEN** `wt/orchestration/config.yaml` does not exist
- **AND** `.claude/orchestration.yaml` exists
- **THEN** the system SHALL use `.claude/orchestration.yaml`

#### Scenario: New location takes precedence
- **WHEN** both `wt/orchestration/config.yaml` and `.claude/orchestration.yaml` exist
- **THEN** the system SHALL use `wt/orchestration/config.yaml`

#### Scenario: Config file format
- **WHEN** the config file is parsed (from either location)
- **THEN** it SHALL support the same top-level keys as before (max_parallel, merge_policy, checkpoint_every, test_command, etc.)
- **AND** the format is identical regardless of file location
