## MODIFIED Requirements

### Requirement: Memory hooks included in default deploy config
The `wt-deploy-hooks` script SHALL include `wt-hook-memory-recall` (UserPromptSubmit, timeout 15), `wt-hook-memory-save` (Stop, timeout 30), `wt-hook-memory-warmstart` (SessionStart, timeout 10), `wt-hook-memory-pretool` (PreToolUse matcher "Bash", timeout 5), and `wt-hook-memory-posttool` (PostToolUseFailure matcher "Bash", timeout 5) in the default hook configuration alongside the existing `wt-hook-skill` and `wt-hook-stop` hooks.

#### Scenario: Fresh deploy includes all memory hooks
- **WHEN** `wt-deploy-hooks /path/to/project` is called
- **AND** no `.claude/settings.json` exists
- **THEN** the created settings.json SHALL contain all 5 memory hooks across their respective events
- **AND** `wt-hook-memory-warmstart` SHALL be in SessionStart with timeout 10
- **AND** `wt-hook-memory-recall` SHALL be in UserPromptSubmit with timeout 15
- **AND** `wt-hook-memory-pretool` SHALL be in PreToolUse matching "Bash" with timeout 5
- **AND** `wt-hook-memory-posttool` SHALL be in PostToolUseFailure matching "Bash" with timeout 5
- **AND** `wt-hook-memory-save` SHALL be in Stop with timeout 30

#### Scenario: Memory hooks have correct timeouts
- **WHEN** `wt-deploy-hooks` creates or updates settings.json
- **THEN** `wt-hook-memory-warmstart` SHALL have `"timeout": 10`
- **AND** `wt-hook-memory-recall` SHALL have `"timeout": 15`
- **AND** `wt-hook-memory-pretool` SHALL have `"timeout": 5`
- **AND** `wt-hook-memory-posttool` SHALL have `"timeout": 5`
- **AND** `wt-hook-memory-save` SHALL have `"timeout": 30`

### Requirement: Upgrade existing configs with memory hooks
The `wt-deploy-hooks` script SHALL add new memory hooks (warmstart, pretool, posttool) to existing settings.json files that have the base hooks and original memory hooks but are missing the new hooks.

#### Scenario: Existing config without new hooks gets upgraded
- **WHEN** `wt-deploy-hooks /path/to/project` is called
- **AND** settings.json already contains `wt-hook-memory-recall` and `wt-hook-memory-save`
- **AND** settings.json does NOT contain `wt-hook-memory-warmstart`
- **THEN** the script SHALL add SessionStart, PreToolUse, and PostToolUseFailure hook entries
- **AND** SHALL create a backup before modification

#### Scenario: Existing config with all hooks is not modified
- **WHEN** `wt-deploy-hooks /path/to/project` is called
- **AND** settings.json already contains all 5 memory hooks
- **THEN** the script SHALL exit 0 without modification

### Requirement: No-memory flag skips memory hooks
The `wt-deploy-hooks` script SHALL accept a `--no-memory` flag that deploys only the base hooks without any memory hooks.

#### Scenario: Deploy without memory hooks
- **WHEN** `wt-deploy-hooks --no-memory /path/to/project` is called
- **THEN** settings.json SHALL contain `wt-hook-skill` and `wt-hook-stop`
- **AND** SHALL NOT contain any `wt-hook-memory-*` hooks

### Requirement: Documentation of automatic memory hooks
The developer memory documentation SHALL include a section describing all 5 automatic memory hook layers and how they complement each other.

#### Scenario: Docs describe all hook layers
- **WHEN** a developer reads `docs/developer-memory.md`
- **THEN** they SHALL find descriptions of L1 (warmstart), L2 (recall), L3 (pretool), L4 (posttool), and L5 (save)
