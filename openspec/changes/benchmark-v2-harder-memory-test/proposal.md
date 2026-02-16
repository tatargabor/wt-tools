## Why

The shodh-memory benchmark v1 showed no meaningful difference between memory-enabled and baseline agents. Root cause: the 6 sequential changes have "organic" traps (errors the agent _might_ hit) but no **forced contradictions**. Real-world projects have stakeholders who change their mind, reviewers who reject code, and sprint retros that surface cross-cutting bugs. V2 adds all of these.

## What Changes

- **Add 3 "revision" changes (07-09)** that explicitly reverse or modify decisions from earlier changes — stock reservation rethink, images table migration, integer cents everywhere
- **Add 2 "feedback" changes (10-11)** that simulate real-world pushback: a code review rejection with specific fixes required, and a design correction where the stakeholder says "nem erre gondoltam" (that's not what I meant)
- **Add 1 "sprint retro" change (12)** that bundles 4 cross-cutting bugs from different changes into a single fix-it-all task — the hardest memory test
- **Add acceptance test scripts** per change that run during the benchmark (not just post-hoc) — the agent must make these tests pass, creating measurable pass/fail signals
- **Add automated evaluator scripts** for post-benchmark scoring
- **Reduce memory hook overhead** — targeted recall on change boundaries only

## Capabilities

### New Capabilities
- `revision-changes`: Three change definitions (07-09) that force requirement reversals
- `feedback-changes`: Two change definitions (10-11) that simulate code review rejection and design corrections with acceptance tests that prove correctness
- `sprint-retro-change`: One change definition (12) that bundles cross-cutting bugs requiring memory of 4+ earlier changes
- `acceptance-tests`: Per-change test scripts (shell/curl) that the agent must make pass — these run DURING the benchmark as verification
- `evaluator-scripts`: Post-benchmark evaluation scripts for automated scoring
- `targeted-recall`: Smarter recall hook that only fires on change boundaries
- `benchmark-scoring-automation`: Scripts to collect and compare results

### Modified Capabilities
- (none — existing specs are not changed, only benchmark/ files)

## Impact

- `benchmark/changes/` — 6 new change files (07-12)
- `benchmark/tests/` — per-change acceptance test scripts
- `benchmark/evaluator/` — post-benchmark scoring scripts
- `bin/wt-hook-memory-recall` — targeted recall on change boundaries
- `benchmark/claude-md/` — update to reference 12 changes
- `benchmark/init-*.sh` — include new changes + test scripts
- `benchmark/scoring-rubric.md` — updated scoring with test pass/fail
