## MODIFIED Requirements

### Requirement: Topic-based recall from prompt text
The recall hook SHALL extract topic keywords from the user's prompt text and use them as the recall query. If an OpenSpec change name is detected (opsx:ff, opsx:apply, opsx:explore, opsx:new, opsx:continue, or openspec- prefixed skills), it SHALL be included in the query. The hook SHALL NOT use change-boundary detection or debounce — it SHALL recall on every prompt. The benchmark CLAUDE.md for Run B SHALL use the "Persistent Memory" pattern (hook-driven automatic recall) instead of manual `wt-memory recall` instructions.

#### Scenario: Benchmark Run B uses hook-driven recall
- **WHEN** the benchmark init-with-memory.sh bootstraps a project
- **THEN** the CLAUDE.md SHALL contain the "Persistent Memory" section
- **AND** SHALL NOT contain manual `wt-memory recall` instructions
- **AND** SHALL instruct the agent to cite memory when it directly answers a question

#### Scenario: Benchmark Run B does not use deprecated wt-memory-hooks
- **WHEN** the benchmark init-with-memory.sh runs
- **THEN** it SHALL NOT call `wt-memory-hooks install`
- **AND** SHALL NOT check for `wt-memory-hooks` in prerequisites
