## ADDED Requirements

### Requirement: Post-merge custom command directive
The orchestrator SHALL support a `post_merge_command` directive that runs a project-specific command after each successful merge.

#### Scenario: Directive configured with a command
- **WHEN** `post_merge_command` is set in orchestration directives (via `.claude/orchestration.yaml` or in-document directives)
- **AND** a change is successfully merged to main
- **THEN** the orchestrator SHALL execute the command via `bash -c "$post_merge_command"` in the main project directory
- **AND** execution SHALL occur after dependency install but before build verification
- **AND** the command SHALL have a 300-second timeout

#### Scenario: Custom command succeeds
- **WHEN** the post-merge custom command exits with code 0
- **THEN** the orchestrator SHALL log "Post-merge: custom command succeeded"
- **AND** proceed to build verification

#### Scenario: Custom command fails
- **WHEN** the post-merge custom command exits with non-zero code
- **THEN** the orchestrator SHALL log a warning "Post-merge: custom command failed (rc=N)"
- **AND** SHALL still proceed to build verification (non-blocking)

#### Scenario: No custom command configured
- **WHEN** `post_merge_command` is empty or not set
- **THEN** the orchestrator SHALL skip the custom command step silently

### Requirement: Directives persistence in state
The orchestrator SHALL persist the resolved directives object in `orchestration-state.json` so that downstream functions can read directive values without parameter passing.

#### Scenario: Directives written on fresh start
- **WHEN** `cmd_start()` initializes state via `init_state()`
- **THEN** the resolved directives SHALL be written to `.directives` in state.json immediately after init

#### Scenario: Directives written on resume
- **WHEN** the orchestrator resumes from a stopped/time_limit state
- **THEN** the directives SHALL be re-resolved from the input file and written to `.directives` in state.json

#### Scenario: Directives written on replan
- **WHEN** a replan cycle re-initializes state
- **THEN** the directives SHALL be written to `.directives` in the new state

#### Scenario: Downstream reads from state
- **WHEN** `merge_change()` or other post-merge functions need directive values
- **THEN** they SHALL read from `jq -r '.directives.<key> // empty' orchestration-state.json`

### Requirement: Post-merge command directive parsing
The `post_merge_command` directive SHALL be parsed from all directive sources with standard 4-level precedence.

#### Scenario: Parsed from orchestration.yaml
- **WHEN** `.claude/orchestration.yaml` contains `post_merge_command: <value>`
- **THEN** the value SHALL be parsed as a string (preserving spaces)
- **AND** SHALL override in-document directive values

#### Scenario: Default value
- **WHEN** `post_merge_command` is not specified in any source
- **THEN** the default SHALL be an empty string (no command)
