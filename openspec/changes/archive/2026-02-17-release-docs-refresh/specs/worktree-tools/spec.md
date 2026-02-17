## MODIFIED Requirements

### Requirement: wt-openspec documented in CLI Reference
The README CLI Reference SHALL include `wt-openspec` as a user-facing command with its subcommands.

#### Scenario: wt-openspec in CLI table
- **WHEN** a user reads the CLI Reference section
- **THEN** they SHALL see `wt-openspec init`, `wt-openspec status`, and `wt-openspec update` in the Project Management or a dedicated OpenSpec category

### Requirement: readme-guide.md CLI rules include new commands
The `docs/readme-guide.md` CLI Documentation Rules SHALL include `wt-openspec` in the user-facing commands list and `wt-hook-memory-recall`, `wt-hook-memory-save` in the internal/hook scripts list.

#### Scenario: Guide lists all user-facing commands
- **WHEN** a documentation author reads the CLI Documentation Rules in readme-guide.md
- **THEN** `wt-openspec` SHALL be listed among user-facing commands
- **AND** `wt-hook-memory-recall` and `wt-hook-memory-save` SHALL be listed among internal/hook scripts
