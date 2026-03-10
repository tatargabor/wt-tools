## ADDED Requirements

### Requirement: Coverage enforcement at plan time
The orchestrator SHALL optionally enforce full requirement coverage when validating a digest-mode plan.

#### Scenario: Full coverage required (opt-in)
- **WHEN** `populate_coverage()` completes in digest mode
- **AND** `require_full_coverage` directive is true
- **AND** `uncovered[]` array is non-empty
- **THEN** `populate_coverage()` SHALL return non-zero (return 1)
- **AND** `cmd_plan` SHALL check the return code via `if ! populate_coverage "$PLAN_FILENAME"` and fail with an error listing the uncovered REQ-* IDs
- **AND** the error message SHALL suggest: "Re-run plan or set require_full_coverage: false to proceed"

#### Scenario: Coverage enforcement disabled (default)
- **WHEN** `require_full_coverage` directive is false (the default)
- **AND** `uncovered[]` array is non-empty
- **THEN** `populate_coverage()` SHALL emit a warning (existing behavior) and return 0
- **AND** `cmd_plan` SHALL proceed normally

#### Scenario: Non-digest mode skips enforcement
- **WHEN** the orchestration is NOT in digest mode
- **THEN** coverage enforcement SHALL be skipped entirely regardless of `require_full_coverage` value

#### Scenario: Directive resolution
- **WHEN** resolving `require_full_coverage`
- **THEN** the orchestrator SHALL read it from the directives JSON object (parsed from orchestration config YAML), defaulting to `false`
- **AND** it SHALL be read in `cmd_plan` using the same pattern as other directives: `$(echo "$directives" | jq -r '.require_full_coverage // false')`

#### Scenario: Cross-cutting REQ without primary owner
- **WHEN** a REQ-* ID appears in one or more changes' `also_affects_reqs[]` but in no change's `requirements[]`
- **THEN** `populate_coverage()` SHALL include it in `uncovered[]`
- **AND** the warning/error message SHALL note which also_affects changes reference it

### Requirement: Final coverage assertion at ALL orchestration exit paths
The monitor loop SHALL check and report requirement coverage status at every exit path.

#### Scenario: Coverage check on auto-replan done (no new work)
- **WHEN** `auto_replan` finds no new work and orchestration is done (monitor.sh ~line 365)
- **AND** `wt/orchestration/digest/coverage.json` exists
- **THEN** the monitor loop SHALL call `final_coverage_check()` before setting status to done

#### Scenario: Coverage check on normal completion (no auto-replan)
- **WHEN** all changes reach terminal state and auto_replan is false (monitor.sh ~line 399)
- **AND** `wt/orchestration/digest/coverage.json` exists
- **THEN** the monitor loop SHALL call `final_coverage_check()`

#### Scenario: Coverage check on time limit exit
- **WHEN** orchestration exits due to time limit (monitor.sh ~line 139)
- **AND** `wt/orchestration/digest/coverage.json` exists
- **THEN** the monitor loop SHALL call `final_coverage_check()` and include results in time-limit summary

#### Scenario: Coverage check on replan-exhausted exit
- **WHEN** auto-replan fails after MAX_REPLAN_RETRIES (monitor.sh ~line 383)
- **AND** `wt/orchestration/digest/coverage.json` exists
- **THEN** the monitor loop SHALL call `final_coverage_check()`

#### Scenario: Coverage check on external stop
- **WHEN** orchestration is externally stopped (monitor.sh ~line 145, status=stopped/done)
- **AND** `wt/orchestration/digest/coverage.json` exists
- **THEN** the monitor loop SHALL call `final_coverage_check()`

#### Scenario: final_coverage_check() behavior
- **WHEN** `final_coverage_check()` is called
- **THEN** it SHALL read `wt/orchestration/digest/coverage.json` and `orchestration-state.json`
- **AND** categorize requirements into: merged, running, planned, uncovered, failed (change failed), blocked (change merge-blocked)
- **AND** emit a `COVERAGE_GAP` event if any requirements are uncovered, failed, or blocked
- **AND** return a formatted summary string for inclusion in notifications/emails
- **AND** log the summary via `info` or `warn` depending on gap count

#### Scenario: Coverage included in summary email
- **WHEN** `send_summary_email()` is called at orchestration completion
- **THEN** a `build_coverage_summary()` helper SHALL read `$DIGEST_DIR/coverage.json` and state, produce a formatted string (total/merged/uncovered/failed/blocked counts + uncovered ID list), and pass it to the email template
- **AND** `send_summary_email()` does NOT need to know `$DIGEST_DIR` — the caller builds the summary before calling

#### Scenario: No digest data
- **WHEN** `wt/orchestration/digest/coverage.json` does not exist
- **THEN** `final_coverage_check()` SHALL return empty string and skip silently

### Requirement: Report generation hook in monitor loop
The monitor loop SHALL trigger HTML report generation at each poll cycle.

#### Scenario: Report generation in poll loop
- **WHEN** the monitor loop completes a poll cycle
- **AND** `generate_report` function is defined (reporter.sh sourced)
- **THEN** it SHALL call `generate_report` after processing all changes and before checkpoint check
- **AND** report generation failure SHALL be logged but SHALL NOT interrupt the poll loop
- **AND** the call SHALL be wrapped in: `generate_report 2>/dev/null || log_warn "Report generation failed"`

#### Scenario: Report generation at cmd_digest completion
- **WHEN** `cmd_digest` completes successfully
- **THEN** it SHALL call `generate_report` (directly in digest.sh, not in monitor_loop)

#### Scenario: Report generation at cmd_plan completion
- **WHEN** `cmd_plan` / `populate_coverage()` completes successfully
- **THEN** it SHALL call `generate_report` (directly in planner.sh, not in monitor_loop)

#### Scenario: Report generation at every terminal exit
- **WHEN** the monitor loop reaches any of its 5 break paths
- **THEN** it SHALL call `generate_report` one final time before breaking
