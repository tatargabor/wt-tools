## ADDED Requirements

### Requirement: Convention Pattern Extraction
The memory save hook SHALL extract convention patterns from session transcripts and save them as explicit Learning memories. A convention is a cross-cutting pattern established in a change that future changes must follow (e.g., "use formatPrice() for all price display", "filter deletedAt IS NULL in all queries").

#### Scenario: Convention extracted from session
- **WHEN** the transcript extraction LLM identifies a convention pattern established during the session
- **THEN** the convention SHALL be saved as a Learning memory with tags `phase:auto-extract,source:hook,convention,change:<name>`

#### Scenario: Convention limit per session
- **WHEN** the LLM extracts conventions from a session
- **THEN** the total number of convention saves SHALL be capped at 2 per session (in addition to the existing 5-insight cap)

#### Scenario: No conventions found
- **WHEN** the session does not establish any cross-cutting conventions
- **THEN** no convention memories SHALL be saved (the hook SHALL NOT fabricate conventions)
