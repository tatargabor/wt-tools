## 1. Add memory hooks to SKILL.md

- [x] 1.1 Add "Save to developer memory" step (step 10) after "Display summary" (step 9) in `.claude/skills/openspec-bulk-archive-change/SKILL.md` — adapted for batch: per-change completion Context + batch-level Decisions and Learnings (conflict resolutions, batch patterns)
- [x] 1.2 Add memory health check guard (skip silently on failure) matching the regular archive pattern

## 2. Add memory hooks to command file

- [x] 2.1 Add identical "Save to developer memory" step (step 10) to `.claude/commands/opsx/bulk-archive.md` — must be identical content to SKILL.md step
- [x] 2.2 Verify both files have identical memory sections (diff check)

## 3. Documentation

- [x] 3.1 Update `docs/` if any memory-related docs reference which skills have memory hooks
- [x] 3.2 Update `docs/readme-guide.md` if bulk-archive is mentioned
- [x] 3.3 Update `README.md` if bulk-archive memory coverage is referenced
