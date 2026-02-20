## MODIFIED Requirements

### Requirement: Existing config with all hooks is not modified
The `wt-deploy-hooks` script SHALL skip modification only when the config matches the canonical hook set — not merely when unified hooks are present. If the config has more `wt-hook-memory` matchers than the canonical set, it SHALL downgrade.

#### Scenario: Canonical config is not modified
- **WHEN** `wt-deploy-hooks /path/to/project` is called
- **AND** settings.json PreToolUse has only `Skill` matcher (activity-track.sh, no wt-hook-memory entries)
- **AND** settings.json PostToolUse has only `Read` and `Bash` matchers (wt-hook-memory)
- **THEN** the script SHALL exit 0 without modification

#### Scenario: Over-provisioned config is downgraded
- **WHEN** `wt-deploy-hooks /path/to/project` is called
- **AND** settings.json PreToolUse has wt-hook-memory entries for Read, Edit, Write, Bash, Task, Grep
- **AND** settings.json PostToolUse has wt-hook-memory entries for Read, Edit, Write, Bash, Task, Grep
- **THEN** the script SHALL remove stale entries and exit 0
- **AND** PreToolUse SHALL contain only the Skill/activity-track.sh entry
- **AND** PostToolUse SHALL contain only Read and Bash wt-hook-memory entries
