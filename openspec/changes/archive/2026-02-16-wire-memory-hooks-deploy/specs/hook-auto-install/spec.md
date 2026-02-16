## MODIFIED Requirements

### Requirement: Reusable hook deployment script
The system SHALL provide a `bin/wt-deploy-hooks` script that deploys Claude Code hooks to a target directory's `.claude/settings.json`.

#### Scenario: Deploy to directory without settings.json
- **WHEN** `wt-deploy-hooks /path/to/worktree` is called
- **AND** `/path/to/worktree/.claude/settings.json` does not exist
- **THEN** the script SHALL create `.claude/` directory and `settings.json` with UserPromptSubmit hooks (`wt-hook-skill`, `wt-hook-memory-recall`) and Stop hooks (`wt-hook-stop`, `wt-hook-memory-save`)

#### Scenario: Deploy to directory with existing settings.json
- **WHEN** `wt-deploy-hooks /path/to/worktree` is called
- **AND** `/path/to/worktree/.claude/settings.json` already exists
- **AND** it does not contain all four required hooks
- **THEN** the script SHALL merge the hook configuration into the existing file
- **AND** create a `.claude/settings.json.bak` backup before modification

#### Scenario: Deploy to directory with hooks already present
- **WHEN** `wt-deploy-hooks /path/to/worktree` is called
- **AND** `/path/to/worktree/.claude/settings.json` already contains all four hooks (wt-hook-skill, wt-hook-stop, wt-hook-memory-recall, wt-hook-memory-save)
- **THEN** the script SHALL exit 0 without modification

#### Scenario: Deploy with --quiet flag
- **WHEN** `wt-deploy-hooks --quiet /path/to/worktree` is called
- **THEN** the script SHALL suppress success/info messages (only errors printed)

#### Scenario: Deploy with --no-memory flag
- **WHEN** `wt-deploy-hooks --no-memory /path/to/worktree` is called
- **THEN** the script SHALL deploy only `wt-hook-skill` (UserPromptSubmit) and `wt-hook-stop` (Stop)
- **AND** SHALL NOT include `wt-hook-memory-recall` or `wt-hook-memory-save`
