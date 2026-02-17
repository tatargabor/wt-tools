## Approach

For each skill file, compare the current content against `bin/wt-<tool> --help` output and add all missing subcommands, flags, and options. Preserve the existing skill file structure and agent instructions — just fill in the gaps.

## Design Decisions

### Keep passthrough pattern for complex CLIs
For `memory.md`, the skill already uses a passthrough pattern for `audit` and `dedup` (run CLI, display output). Extend this to all CLI subcommands rather than re-implementing logic in the skill. Group by category as the CLI help does.

### Fix incorrect type names
The skill currently references `Observation` and `Event` as memory types. These are legacy aliases — the real types are `Decision`, `Learning`, `Context`. Update all references.

### Don't over-document flags for simple wrappers
For `new.md`, `work.md`, `close.md`, `merge.md` — these are thin wrappers that pass $ARGUMENTS through. Add the missing flags to the documentation but keep the passthrough execution pattern.

### Flag name corrections
`merge.md` documents `--target` but the CLI uses `--to`. Fix to match actual CLI.

## Files Changed

| File | Change Type |
|------|------------|
| `.claude/commands/wt/memory.md` | Major rewrite — add 15+ missing subcommands, fix types |
| `.claude/commands/wt/loop.md` | Add 5 missing flags |
| `.claude/commands/wt/merge.md` | Add 2 flags, fix --target→--to |
| `.claude/commands/wt/work.md` | Add 3 missing flags |
| `.claude/commands/wt/new.md` | Add 4 missing flags |
