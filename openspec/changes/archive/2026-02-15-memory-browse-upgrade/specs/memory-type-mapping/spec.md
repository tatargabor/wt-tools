## MODIFIED Requirements

### Requirement: GUI shows only valid memory types
The RememberNoteDialog type selector SHALL offer only `Learning`, `Decision`, `Context`. The MemoryBrowseDialog SHALL use badge colors for these 3 types in both the card view and the context summary view.

#### Scenario: Remember dialog type options
- **WHEN** user opens the Remember Note dialog
- **THEN** the type dropdown contains exactly: Learning, Decision, Context

#### Scenario: Browse dialog renders badge for each type
- **WHEN** a memory with experience_type Learning is displayed
- **THEN** the badge shows "Learning" with green color
- **WHEN** a memory with experience_type Decision is displayed
- **THEN** the badge shows "Decision" with blue color
- **WHEN** a memory with experience_type Context is displayed
- **THEN** the badge shows "Context" with amber color

#### Scenario: Context summary section headers use type colors
- **WHEN** the context summary view displays a Decisions section header
- **THEN** the header uses the blue Decision badge color
- **WHEN** the summary displays a Learnings section header
- **THEN** the header uses the green Learning badge color
- **WHEN** the summary displays a Context section header
- **THEN** the header uses the amber Context badge color
