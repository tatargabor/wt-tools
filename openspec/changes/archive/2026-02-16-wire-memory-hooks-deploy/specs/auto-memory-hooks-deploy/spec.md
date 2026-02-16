## ADDED Requirements

### Requirement: Memory hooks included in default deploy config
The `wt-deploy-hooks` script SHALL include `wt-hook-memory-recall` (UserPromptSubmit, timeout 15) and `wt-hook-memory-save` (Stop, timeout 30) in the default hook configuration alongside the existing `wt-hook-skill` and `wt-hook-stop` hooks.

#### Scenario: Fresh deploy includes memory hooks
- **WHEN** `wt-deploy-hooks /path/to/project` is called
- **AND** no `.claude/settings.json` exists
- **THEN** the created settings.json SHALL contain `wt-hook-memory-recall` in the UserPromptSubmit hooks array
- **AND** SHALL contain `wt-hook-memory-save` in the Stop hooks array

#### Scenario: Memory hooks have correct timeouts
- **WHEN** `wt-deploy-hooks` creates or updates settings.json
- **THEN** `wt-hook-memory-recall` SHALL have `"timeout": 15`
- **AND** `wt-hook-memory-save` SHALL have `"timeout": 30`

### Requirement: Upgrade existing configs with memory hooks
The `wt-deploy-hooks` script SHALL add memory hooks to existing settings.json files that have the base hooks but are missing memory hooks.

#### Scenario: Existing config without memory hooks gets upgraded
- **WHEN** `wt-deploy-hooks /path/to/project` is called
- **AND** settings.json already contains `wt-hook-skill` and `wt-hook-stop`
- **AND** settings.json does NOT contain `wt-hook-memory-save`
- **THEN** the script SHALL append memory hooks to the existing hook arrays
- **AND** SHALL create a backup before modification

#### Scenario: Existing config with memory hooks is not modified
- **WHEN** `wt-deploy-hooks /path/to/project` is called
- **AND** settings.json already contains all four hooks
- **THEN** the script SHALL exit 0 without modification

### Requirement: No-memory flag skips memory hooks
The `wt-deploy-hooks` script SHALL accept a `--no-memory` flag that deploys only the base hooks without memory hooks.

#### Scenario: Deploy without memory hooks
- **WHEN** `wt-deploy-hooks --no-memory /path/to/project` is called
- **THEN** settings.json SHALL contain `wt-hook-skill` and `wt-hook-stop`
- **AND** SHALL NOT contain `wt-hook-memory-recall` or `wt-hook-memory-save`

### Requirement: Documentation of automatic memory hooks
The developer memory documentation SHALL include a section describing the automatic memory hooks and how they complement skill-level hooks.

#### Scenario: Docs describe auto-save hook
- **WHEN** a developer reads `docs/developer-memory.md`
- **THEN** they SHALL find a section explaining that `wt-hook-memory-save` automatically saves design choices after commits

#### Scenario: Docs describe auto-recall hook
- **WHEN** a developer reads `docs/developer-memory.md`
- **THEN** they SHALL find a section explaining that `wt-hook-memory-recall` automatically recalls past decisions before agent responses
