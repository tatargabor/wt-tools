## MODIFIED Requirements

### Requirement: Cheat sheet promotion criteria in haiku prompt
The haiku extraction prompt SHALL include instructions to identify cheat-sheet-worthy entries based on: (1) soft operational patterns and project conventions, (2) environment-specific configuration hints, (3) command patterns that aid productivity. The prompt SHALL explicitly exclude hard constraints, credentials, and mandatory rules from cheat-sheet promotion — those belong in `.claude/rules.yaml` instead.

#### Scenario: Haiku prompt includes cheat-sheet criteria
- **WHEN** the Stop hook runs haiku extraction
- **THEN** the prompt SHALL instruct haiku to output a `CheatSheet` type for reusable soft conventions
- **AND** CheatSheet entries SHALL be saved as Learning type with `cheat-sheet` tag
- **AND** the extraction SHALL be limited to 2 cheat-sheet entries per session

#### Scenario: Credential-like content is NOT promoted to cheat-sheet
- **WHEN** the haiku extraction identifies content like "DB password is X" or "use login Y for table Z"
- **THEN** this SHALL NOT receive the `cheat-sheet` tag
- **AND** haiku MAY note in the extracted insight that a rule entry may be appropriate

#### Scenario: Soft convention IS promoted to cheat-sheet
- **WHEN** the haiku extraction identifies a convention like "pytest needs PYTHONPATH=. to run correctly"
- **THEN** this SHALL receive the `cheat-sheet` tag as before
