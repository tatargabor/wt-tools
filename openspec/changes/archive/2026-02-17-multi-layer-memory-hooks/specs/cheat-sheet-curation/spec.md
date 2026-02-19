## ADDED Requirements

### Requirement: Auto-promote error fixes to cheat sheet
The Stop hook's haiku extraction step SHALL evaluate extracted error→fix memories for cheat-sheet worthiness and add the `cheat-sheet` tag to entries that describe reusable operational patterns.

#### Scenario: Error fix is reusable (e.g., DB connection pattern)
- **WHEN** the haiku extraction identifies a memory like "DB password is in .env.local, not .env"
- **AND** this describes a reusable operational pattern
- **THEN** the memory SHALL be saved with tags including `cheat-sheet`
- **AND** the `cheat-sheet` tag SHALL be in addition to existing tags

#### Scenario: Error fix is session-specific
- **WHEN** the haiku extraction identifies a memory like "fixed typo in variable name"
- **AND** this is a one-time fix not reusable across sessions
- **THEN** the memory SHALL NOT receive the `cheat-sheet` tag

### Requirement: Convention memories auto-promote to cheat sheet
All memories extracted as `Convention` type (which maps to Learning with `convention` tag) SHALL also receive the `cheat-sheet` tag automatically.

#### Scenario: Convention extracted from session
- **WHEN** the haiku extraction identifies a convention like "all list endpoints return { data, total, page, limit }"
- **THEN** the memory SHALL be saved with tags including both `convention` and `cheat-sheet`

### Requirement: Cheat sheet promotion criteria in haiku prompt
The haiku extraction prompt SHALL include instructions to identify cheat-sheet-worthy entries based on: (1) operational patterns that prevent errors, (2) environment-specific configuration, (3) project-specific conventions, (4) command patterns that must be followed.

#### Scenario: Haiku prompt includes cheat-sheet criteria
- **WHEN** the Stop hook runs haiku extraction
- **THEN** the prompt SHALL instruct haiku to output a `CheatSheet` type for reusable operational patterns
- **AND** CheatSheet entries SHALL be saved as Learning type with `cheat-sheet` tag
- **AND** the extraction SHALL be limited to 2 cheat-sheet entries per session
