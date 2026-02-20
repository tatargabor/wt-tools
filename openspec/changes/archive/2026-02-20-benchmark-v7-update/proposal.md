## Why

The v6 CraftBazaar benchmark showed no measurable memory advantage (Run A: 11.5/13 traps, 11/12 C12 bugs vs Run B: 11/13, 9/12). The 5 P0/P1 test fixes identified in v6-results.md have already been implemented (commit 938c0f6), along with explicit C12 acceptance criteria for Bug 11/12. What remains is wiring the new metrics collection system into benchmark init scripts (to measure injection quality during the benchmark), updating documentation to reflect v7 readiness, and a minor CLAUDE.md refresh.

## What Changes

- **Enable metrics collection** in both init scripts (`init-baseline.sh` and `init-with-memory.sh`) so injection quality data is captured during benchmark runs
- **Update run-guide.md** to reflect v7 status (test fixes done, metrics integration, post-run metrics dashboard)
- **Add post-run metrics collection step** to run-guide.md for analyzing injection quality
- **Minor CLAUDE.md refresh** — ensure recall-then-verify emphasis is strong enough given v6 findings about memory-induced overconfidence

## Capabilities

### New Capabilities
- `benchmark-metrics-integration`: Wire metrics collection into benchmark init scripts and add post-run metrics analysis step to run-guide

### Modified Capabilities

## Impact

- `benchmark/init-with-memory.sh` — enable metrics flag
- `benchmark/init-baseline.sh` — enable metrics flag (for comparison baseline)
- `benchmark/run-guide.md` — v7 status update, metrics collection step
- `benchmark/claude-md/with-memory.md` — minor recall-verify emphasis
