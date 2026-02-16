## ADDED Requirements

### Requirement: Discover-Save-Tell ordering in all investigation-capable skills
All OpenSpec skills that involve investigation (reading code, running commands, verifying behavior) SHALL include a "Discover → Save → Tell" instruction. This is a one-liner referencing the pattern, not a full instruction block. The affected skills are: explore, ff, apply, continue, and verify.

#### Scenario: Skill file includes discovery ordering instruction
- **WHEN** the explore, ff, apply, continue, or verify SKILL.md is read
- **THEN** it contains an instruction about immediate discovery saving using the "Discover → Save → Tell" pattern
- **THEN** the instruction is concise (1-3 lines, not a full section)

#### Scenario: Non-investigation skills are not modified
- **WHEN** the archive, bulk-archive, sync, or new SKILL.md is read
- **THEN** it does NOT contain the discovery ordering instruction (these skills don't investigate)
