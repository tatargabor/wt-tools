## Why

The automatic memory hooks (`wt-hook-memory-save`, `wt-hook-memory-recall`) produce low-quality memories that don't effectively help autonomous agents. Memories are verbose (680-1700 chars), redundant (3 per change), and the recall query is too generic to surface relevant context. The benchmark showed 19 memories saved but no measurable improvement in agent behavior.

## What Changes

- **Save hook**: Condense from 3 memories/change to 1 concise memory (~200 chars) containing only the **Choice** lines from design.md
- **Recall hook**: Replace generic prompt-based query with OpenSpec-aware query that detects pending changes and recalls relevant prior decisions
- **Recall output format**: Change from raw memory dump to actionable context that tells the agent what to maintain consistency with

## Capabilities

### New Capabilities
- `condensed-memory-save`: Save hook extracts only **Choice** lines from design.md decisions, producing one concise memory per change
- `smart-memory-recall`: Recall hook uses OpenSpec status to build targeted queries for pending changes, outputs actionable context

### Modified Capabilities

## Impact

- `bin/wt-hook-memory-save` — rewrite extraction logic
- `bin/wt-hook-memory-recall` — rewrite query building and output formatting
- No API changes, no breaking changes — hooks remain compatible with existing settings.json config
