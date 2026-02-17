## MODIFIED Requirements

### Requirement: CLI Reference Section
The guide SHALL include a complete CLI reference for `wt-memory` and `wt-memory-hooks` with all subcommands, flags, and examples.

#### Scenario: CLI completeness
- **WHEN** a user reads the CLI Reference
- **THEN** they find entries for: `health`, `remember` (with --type and --tags), `recall` (with --limit, --mode, --tags), `list`, `status` (with --json), `projects`, `forget` (with --all, --older-than, --tags, --pattern), `context`, `brain`, `get`, `export`, `import`, `sync`, `migrate`, `repair`, `audit` (with --threshold, --json), `dedup` (with --threshold, --dry-run, --interactive), and `wt-memory-hooks` commands (`install`, `check`, `remove`)

#### Scenario: Audit command documented
- **WHEN** a user reads the CLI Reference Diagnostics section
- **THEN** they find `wt-memory audit [--threshold N] [--json]` with description: "Report memory health: duplicate clusters, redundancy stats, top clusters"

#### Scenario: Dedup command documented
- **WHEN** a user reads the CLI Reference Diagnostics section
- **THEN** they find `wt-memory dedup [--threshold N] [--dry-run] [--interactive]` with description: "Remove duplicate memories, keeping best per cluster with merged tags"

### Requirement: Setup Section
The guide SHALL include setup instructions covering `pip install shodh-memory`, `wt-memory-hooks install`, graceful degradation behavior, and step-by-step happy-flow guides for common setup scenarios.

#### Scenario: Setup steps
- **WHEN** a user reads the Setup section
- **THEN** they find: installation command, hooks installation command, and a note that everything silently no-ops if shodh-memory is not installed

#### Scenario: Fresh project init flow
- **WHEN** a user reads the Quick Setup Flows subsection
- **THEN** they find a numbered sequence for initializing a fresh project with OpenSpec and memory: pip install shodh-memory, wt-project init (deploys hooks+commands+skills), wt-openspec init, wt-memory-hooks install, wt-memory-hooks check

#### Scenario: Add memory to existing project flow
- **WHEN** a user reads the Quick Setup Flows subsection
- **THEN** they find a numbered sequence for adding memory to an existing OpenSpec project: pip install shodh-memory (if needed), wt-project init (re-run to update deployment), wt-memory-hooks install, wt-memory-hooks check

#### Scenario: Re-install hooks after update flow
- **WHEN** a user reads the Quick Setup Flows subsection
- **THEN** they find a numbered sequence for re-installing memory hooks after `wt-openspec update`: wt-openspec update, wt-memory-hooks install, wt-memory-hooks check

### Requirement: GUI Documentation
The guide SHALL document the GUI memory features: the [M] button, Browse Memories dialog, Remember Note dialog, hook installation from the menu, and include a screenshot showing the M/O/R status badges.

#### Scenario: GUI features listed
- **WHEN** a user reads the GUI section
- **THEN** they find descriptions of the browse dialog (search + card view), remember dialog (type + content + tags), and menu-based hook installation

#### Scenario: GUI screenshot present
- **WHEN** a user reads the GUI section
- **THEN** they see a screenshot showing the Control Center with [M], [O], and [R] status badges in the project header rows

### Requirement: Automatic hooks documentation includes staging
The guide SHALL document the staging+debounce pattern used by `wt-hook-memory-save` for transcript extraction, explaining that it prevents duplicate memories by staging extractions and committing on session switch.

#### Scenario: Staging pattern documented
- **WHEN** a user reads the automatic hooks section for wt-hook-memory-save
- **THEN** they find a description of the staging mechanism: extractions written to `.wt-tools/.staged-extract-*`, committed when a different transcript is detected, debounced at 5-minute intervals

### Requirement: Developer Memory CLI documentation in README
The README CLI Reference SHALL document all user-facing `wt-memory` subcommands including audit, dedup, sync, proactive, stats, and cleanup.

#### Scenario: All wt-memory subcommands listed
- **WHEN** a user reads the Developer Memory CLI table in README
- **THEN** they SHALL see entries for: remember, recall, list, status, forget, context, brain, get, export, import, repair, sync, sync push, sync pull, sync status, proactive, stats, cleanup, audit, dedup

#### Scenario: Audit and dedup in README CLI table
- **WHEN** a user reads the Developer Memory CLI table in README
- **THEN** they SHALL see `wt-memory audit` described as diagnostic report and `wt-memory dedup` described as duplicate removal

### Requirement: README guide includes audit and dedup in mandatory list
The `docs/readme-guide.md` mandatory Developer Memory CLI list SHALL include `wt-memory audit` and `wt-memory dedup`.

#### Scenario: Mandatory list updated
- **WHEN** the README is generated using readme-guide.md
- **THEN** the mandatory CLI list includes `wt-memory audit` and `wt-memory dedup` alongside existing commands

## ADDED Requirements

### Requirement: Comparison with Claude Code built-in memory
The guide SHALL include a section explaining how wt-memory differs from Claude Code's built-in memory system (CLAUDE.md files + auto memory), positioned after the Quick Start section.

#### Scenario: Comparison section exists
- **WHEN** a user reads the guide after Quick Start
- **THEN** they find a "How wt-memory Differs from Claude Code Memory" section

#### Scenario: Complementary framing
- **WHEN** a user reads the comparison section
- **THEN** they understand that CLAUDE.md/auto memory provides instructions (always loaded, deterministic) while wt-memory provides experience (searched on demand, semantic), and they are complementary

#### Scenario: Comparison table
- **WHEN** a user reads the comparison section
- **THEN** they find a table comparing at minimum: storage mechanism, recall method, structure, scale, worktree behavior, team sharing, and lifecycle management

#### Scenario: Worktree sharing difference highlighted
- **WHEN** a user reads the comparison section
- **THEN** they understand that Claude auto memory gives separate memory per worktree while wt-memory shares across worktrees of the same repo

### Requirement: wt-project init documentation in README
The README Quick Start and CLI Reference SHALL reflect the enhanced `wt-project init` behavior that deploys hooks, commands, and skills per-project.

#### Scenario: Quick Start mentions deploy
- **WHEN** a user reads the README Quick Start step for `wt-project init`
- **THEN** they understand it registers the project AND deploys wt-tools hooks, commands, and skills to the project's `.claude/` directory

#### Scenario: CLI Reference updated
- **WHEN** a user reads the Worktree Management CLI table for `wt-project`
- **THEN** the description mentions that `init` deploys hooks, commands, and skills (not just registers)
