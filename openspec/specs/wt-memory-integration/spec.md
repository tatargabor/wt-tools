## ADDED Requirements

### Requirement: Memory seed file format
The system SHALL support a `wt/knowledge/memory-seed.yaml` file containing project-essential memories to bootstrap new memory stores.

#### Scenario: Valid seed file
- **WHEN** a memory seed file exists at `wt/knowledge/memory-seed.yaml`
- **THEN** it contains a `version` field (integer) and a `seeds` array
- **AND** each seed has `type` (Context, Decision, or Learning), `content` (string), and `tags` (comma-separated string)

#### Scenario: Seed file example
- **WHEN** a project maintains a seed file
- **THEN** it contains 10-30 essential memories covering: tech stack, key conventions, cross-cutting concerns, and known pitfalls

### Requirement: Auto-import seeds on project init
`wt-project init` SHALL import memory seeds when the memory store is empty and a seed file exists.

#### Scenario: Fresh install with seeds
- **WHEN** `wt-project init` runs
- **AND** `wt/knowledge/memory-seed.yaml` exists
- **AND** the project's memory store is empty (no memories)
- **THEN** all seeds are imported into the memory store with `source:seed` appended to each seed's existing tags
- **AND** duplicate detection is based on content text only (ignoring tags and type)
- **AND** the output displays "Imported N memory seeds"

#### Scenario: Non-empty memory store
- **WHEN** `wt-project init` runs
- **AND** the project's memory store already has memories
- **THEN** seeds are NOT auto-imported (to avoid duplicates)
- **AND** the output displays "Memory store not empty — skip seed import. Use 'wt-memory seed' to force."

#### Scenario: No seed file
- **WHEN** `wt-project init` runs
- **AND** `wt/knowledge/memory-seed.yaml` does not exist
- **THEN** the seed import step is silently skipped

### Requirement: Explicit seed import command
`wt-memory seed` SHALL import seeds from the seed file, skipping duplicates.

#### Scenario: Import with duplicate detection
- **WHEN** user runs `wt-memory seed`
- **AND** `wt/knowledge/memory-seed.yaml` exists
- **THEN** each seed is checked against existing memories by content hash
- **AND** only new seeds are imported
- **AND** the output displays "Imported N new seeds, skipped M existing"

#### Scenario: No seed file
- **WHEN** user runs `wt-memory seed`
- **AND** `wt/knowledge/memory-seed.yaml` does not exist
- **THEN** the command prints "No seed file found at wt/knowledge/memory-seed.yaml"

### Requirement: Memory sync uses wt work directory
The `wt-memory sync` commands SHALL use `wt/.work/memory/` as the working directory for sync operations when the `wt/` directory exists.

#### Scenario: Sync push working files
- **WHEN** `wt-memory sync push` runs
- **AND** `wt/.work/` directory exists
- **THEN** the export JSON is written to `wt/.work/memory/export.json`
- **AND** sync state is tracked in `wt/.work/memory/.sync-state`
- **AND** the sync state is per-working-directory (each clone maintains independent sync state)

#### Scenario: Migrate existing sync state
- **WHEN** `wt-memory sync push` or `pull` runs with `wt/` present
- **AND** `wt/.work/memory/.sync-state` does not exist
- **AND** `.sync-state` exists in the legacy storage path (`~/.local/share/wt-tools/memory/<project>/`)
- **THEN** the legacy `.sync-state` is copied to `wt/.work/memory/.sync-state`
- **AND** subsequent sync operations use the new location

#### Scenario: Sync pull staging
- **WHEN** `wt-memory sync pull` runs
- **AND** `wt/.work/` directory exists
- **THEN** pulled data is staged in `wt/.work/memory/import-staging/`

#### Scenario: Fallback without wt directory
- **WHEN** sync commands run in a project without `wt/` directory
- **THEN** the existing behavior is preserved (temp dirs, memory store dir for state)
