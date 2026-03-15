## MODIFIED Requirements

### Requirement: Dispatch context includes design information
The dispatcher SHALL inject design context into the agent's proposal. The design context SHALL now include three sections (previously two): Design Tokens, Relevant Component Hierarchies, AND matched Figma Source Files.

#### Scenario: Figma sources available for UI change
- **WHEN** dispatching a change with UI scope and `docs/figma-raw/*/sources/` exists
- **THEN** the proposal SHALL contain Design Tokens, matched Component Hierarchy, AND matched Figma source file contents
- **AND** total design context SHALL NOT exceed 500 lines

#### Scenario: No figma-raw sources (only snapshot)
- **WHEN** dispatching a change with `design-snapshot.md` but no `sources/` directory
- **THEN** the proposal SHALL contain Design Tokens and Component Hierarchy only (existing behavior unchanged)

#### Scenario: Infrastructure change with no UI scope
- **WHEN** dispatching a change with scope containing only "prisma", "jest", "config" terms
- **THEN** no source files SHALL be injected (only tokens if design snapshot exists)

### Requirement: Context budget allocation
The total design context injected into proposals SHALL respect a 500-line budget allocated as: Design Tokens (~100 lines), Component Hierarchy (max 100 lines), Source Files (max 300 lines).

#### Scenario: All three sections present
- **WHEN** tokens are 80 lines, hierarchy is 120 lines, sources are 400 lines
- **THEN** hierarchy SHALL be truncated to 100 lines and sources to 300 lines
- **AND** total SHALL NOT exceed 500 lines
