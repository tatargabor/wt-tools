## Why

The shodh-memory integration is feature-complete (CLI, GUI, OpenSpec hooks, proactive memory) but documentation is minimal — 9 lines in the README Features section and a CLI table. Users have no guide for when or how to use developer memory, no concrete examples, and no explanation of how OpenSpec hooks work automatically. A dedicated documentation page and updated README guide are needed so users can actually discover and benefit from the feature.

## What Changes

- Create `docs/developer-memory.md` — a comprehensive user-facing guide with concrete examples, use case walkthroughs, OpenSpec phase integration, GUI features, and a technical architecture appendix
- Update `docs/readme-guide.md` — add detailed instructions for the Developer Memory sections (Features #6, Use Cases #13, CLI Reference #8) so future README regeneration produces complete memory documentation
- Update `README.md` — expand the Developer Memory feature section and add a memory-focused use case, linking to the deep-dive doc

## Capabilities

### New Capabilities
- `developer-memory-docs`: Documentation for the developer memory system — covers user guide, examples, OpenSpec integration explanation, and readme-guide update instructions

### Modified Capabilities
- `readme-guide`: Add detailed generation instructions for Developer Memory content in Features, Use Cases, and CLI Reference sections

## Impact

- `docs/developer-memory.md` — new file
- `docs/readme-guide.md` — updated with memory documentation instructions
- `README.md` — expanded Developer Memory sections
- No code changes, no behavioral changes — documentation only
