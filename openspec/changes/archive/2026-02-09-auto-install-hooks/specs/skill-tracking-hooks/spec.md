## MODIFIED Requirements

### Requirement: Project hook deployment via install
The `install.sh` script SHALL deploy Claude Code hooks to all registered projects using the `wt-deploy-hooks` script.

#### Scenario: Fresh install with registered projects
- **WHEN** user runs `install.sh`
- **AND** `projects.json` contains registered projects
- **THEN** `wt-deploy-hooks` SHALL be called for each project's main repo path

#### Scenario: Project already has settings.json
- **WHEN** a project already has `.claude/settings.json` with other settings
- **THEN** `wt-deploy-hooks` SHALL merge hooks without overwriting existing settings
- **AND** a backup SHALL be created before modification

#### Scenario: No registered projects
- **WHEN** user runs `install.sh`
- **AND** `projects.json` does not exist or has no projects
- **THEN** `install_project_hooks()` SHALL skip gracefully with an info message

### Requirement: Hook deployment on wt-add
The `wt-add` command SHALL deploy Claude Code hooks when registering a new project using the `wt-deploy-hooks` script.

#### Scenario: Add new project deploys hooks
- **WHEN** user runs `wt-add /path/to/repo`
- **AND** the repository is successfully registered
- **THEN** `wt-deploy-hooks` SHALL be called on the project root

#### Scenario: Add worktree to existing project
- **WHEN** user runs `wt-add` for a worktree whose main repo already has hooks deployed
- **THEN** no duplicate hook deployment SHALL occur for the main repo
