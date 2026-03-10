## Why

The orchestration pipeline tracks requirement lifecycle (planned/dispatched/running/merged) but never verifies whether the actual implementation satisfies the assigned requirements. A change can merge with all tasks checked off, tests passing, and build green — yet miss half its assigned REQ-* IDs. There is no coverage enforcement at plan time (uncovered requirements are warnings only), no requirement-aware code review, no final coverage assertion at orchestration completion, and no human-readable report to visualize progress. For complex multi-file specs (60+ requirements, 14+ changes), this means the system cannot reliably answer: "Did we build everything the spec says?"

## What Changes

- **Digest prompt refinement**: Strengthen requirement granularity instructions so Claude produces finer-grained, individually-testable REQ-* IDs instead of lumping behaviors together
- **Requirement-aware code review**: Enrich the `review_change()` prompt with the change's assigned REQ-* IDs and briefs, asking the reviewer to flag any unimplemented requirements
- **Coverage enforcement at plan time**: Make uncovered requirements a hard error (or configurable gate) in `validate_plan()` and `populate_coverage()` instead of a warning
- **Final coverage assertion**: Add a `cmd_coverage()` call at orchestration completion in `monitor_loop()`, reporting uncovered/failed requirements in the summary email
- **HTML orchestration report**: Generate a self-contained HTML report (`wt/orchestration/report.html`) with auto-refresh, showing digest understanding, plan decomposition, execution progress, and requirement traceability — updated every poll cycle

## Capabilities

### New Capabilities
- `orchestration-html-report`: Self-contained HTML report showing digest overview, plan decomposition graph, execution timeline, gate results, and per-requirement coverage traceability. Auto-refreshes via meta tag. Generated at digest/plan/poll/completion phases.

### Modified Capabilities
- `verify-gate`: Add requirement-aware review — inject REQ-* IDs into the code review prompt and flag missing implementations as CRITICAL
- `orchestration-engine`: Add coverage enforcement at plan validation (hard error for uncovered requirements) and final coverage assertion at monitor loop completion

## Impact

- **Files modified**: `lib/orchestration/digest.sh` (prompt refinement), `lib/orchestration/verifier.sh` (review prompt enrichment), `lib/orchestration/planner.sh` (coverage enforcement), `lib/orchestration/monitor.sh` (final coverage + report generation trigger)
- **New file**: `lib/orchestration/reporter.sh` (HTML report generator)
- **Config**: New optional directive `require_full_coverage: true|false` (default: false — opt-in)
- **State**: `init_state()` modified to copy `requirements[]` and `also_affects_reqs[]` from plan to state per change
- **No breaking changes**: All enhancements are additive. `require_full_coverage` defaults to false so existing runs are unaffected. HTML report generation is automatic but non-blocking.
