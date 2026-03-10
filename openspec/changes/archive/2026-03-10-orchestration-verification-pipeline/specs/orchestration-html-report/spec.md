## ADDED Requirements

### Requirement: HTML report generation
The orchestrator SHALL generate a self-contained HTML report at `wt/orchestration/report.html` that provides a browser-viewable overview of the entire orchestration pipeline.

#### Scenario: Report file location and format
- **WHEN** the orchestrator generates a report
- **THEN** it SHALL write to `wt/orchestration/report.html`
- **AND** the file SHALL be self-contained (all CSS inline, no external dependencies)
- **AND** the file SHALL include `<meta http-equiv="refresh" content="15">` for auto-refresh

#### Scenario: Atomic file write
- **WHEN** `generate_report()` writes the HTML file
- **THEN** it SHALL write to a temporary file first via `mktemp`
- **AND** then atomically move it to the final path via `mv`
- **AND** this prevents browsers from reading a partially-written file during auto-refresh

#### Scenario: Report generation timing
- **WHEN** `cmd_digest` completes successfully
- **THEN** `generate_report()` SHALL be called (digest section populated)
- **AND** **WHEN** `cmd_plan` / `populate_coverage()` completes
- **THEN** `generate_report()` SHALL be called (plan + coverage sections added)
- **AND** **WHEN** `monitor_loop` completes a poll cycle
- **THEN** `generate_report()` SHALL be called (execution + coverage updated)
- **AND** **WHEN** orchestration reaches any terminal state (done/time_limit/stopped/replan-exhausted)
- **THEN** `generate_report()` SHALL be called one final time with completion timestamp

#### Scenario: Report generation is non-blocking
- **WHEN** `generate_report()` fails for any reason
- **THEN** the orchestrator SHALL log a warning and continue
- **AND** report generation failure SHALL NOT affect orchestration execution

### Requirement: Digest section in HTML report
The report SHALL display how the system understood the input specification.

#### Scenario: Digest overview rendering
- **WHEN** `wt/orchestration/digest/index.json` exists
- **THEN** the digest section SHALL display: spec source path, file count, total requirement count, domain count, ambiguity count

#### Scenario: Domain breakdown with coverage bars
- **WHEN** `wt/orchestration/digest/requirements.json` and `wt/orchestration/digest/coverage.json` exist
- **THEN** the report SHALL display each domain with: name, requirement count, coverage percentage (merged/total), and a visual progress bar

#### Scenario: Ambiguity listing
- **WHEN** `wt/orchestration/digest/ambiguities.json` contains entries
- **THEN** the report SHALL list each ambiguity with: ID, description, type, and affected requirement IDs

#### Scenario: Missing digest data
- **WHEN** digest files do not exist (non-digest mode orchestration)
- **THEN** the digest section SHALL display "No digest data — running in brief/spec mode"

### Requirement: Plan section in HTML report
The report SHALL display the decomposition of requirements into changes.

#### Scenario: Change table rendering
- **WHEN** `orchestration-plan.json` and `orchestration-state.json` exist
- **THEN** the plan section SHALL display a table with columns: change name, requirement count, spec file count, dependencies, and current status

#### Scenario: Dependency visualization
- **WHEN** changes have `depends_on` relationships
- **THEN** the report SHALL render the dependency structure showing which changes depend on others

#### Scenario: Coverage summary in plan section
- **WHEN** `wt/orchestration/digest/coverage.json` exists
- **THEN** the plan section SHALL display: total requirements, assigned count, uncovered count
- **AND** uncovered requirements SHALL be highlighted in red

### Requirement: Execution section in HTML report
The report SHALL display real-time execution progress.

#### Scenario: Change timeline rendering
- **WHEN** changes have execution data in `orchestration-state.json`
- **THEN** the execution section SHALL display each change with: name, status (color-coded), elapsed time, token usage (`tokens_used` field), and iteration count (from worktree `loop-state.json` if accessible)

#### Scenario: Gate results matrix
- **WHEN** changes have gate results in `orchestration-state.json`
- **THEN** the report SHALL display a matrix with columns: test_result, build_result, scope_check, e2e_result, has_tests
- **AND** each cell SHALL show a checkmark for pass, cross for fail, dash for skip/null

#### Scenario: Active issues listing
- **WHEN** changes have non-success states (verify-failed, stalled, merge-blocked, failed)
- **THEN** the report SHALL list each issue with the change name and relevant context (truncated test_output or build_output from state)

#### Scenario: Execution summary stats
- **WHEN** the report is generated during or after execution
- **THEN** it SHALL display: elapsed time (wall + active), total tokens used (sum of all changes' tokens_used), changes completed/running/pending/failed/merge-blocked

### Requirement: Coverage section in HTML report
The report SHALL display per-requirement traceability with cross-referenced status.

#### Scenario: Requirement traceability table
- **WHEN** `wt/orchestration/digest/requirements.json` and `wt/orchestration/digest/coverage.json` exist
- **THEN** the coverage section SHALL list every requirement with: REQ-ID, title, assigned change name, and effective status

#### Scenario: Effective status cross-reference
- **WHEN** rendering requirement status
- **THEN** the report SHALL cross-reference `coverage.json` (REQ→change mapping + coverage status) with `orchestration-state.json` (change→status)
- **AND** if coverage says "merged" but the change's state is "failed", the effective status SHALL be "failed"
- **AND** if coverage says "running" but the change's state is "merge-blocked", the effective status SHALL be "merge-blocked"

#### Scenario: Status color coding
- **WHEN** rendering requirement effective status
- **THEN** merged SHALL be green (#4caf50), running SHALL be blue (#2196f3), planned/dispatched SHALL be yellow (#ff9800), uncovered SHALL be red (#f44336), failed SHALL be orange (#ff5722), merge-blocked SHALL be orange (#ff5722), removed SHALL be gray (#757575)

#### Scenario: Domain grouping with collapsible sections
- **WHEN** requirements span multiple domains
- **THEN** requirements SHALL be grouped by domain in collapsible `<details>` elements
- **AND** each domain header SHALL show the domain coverage percentage (merged / total non-removed)

#### Scenario: Coverage summary row
- **WHEN** the coverage table is rendered
- **THEN** a summary row SHALL display: total requirements, merged count, running count, pending count, uncovered count, failed count, blocked count

### Requirement: Report styling
The HTML report SHALL use a consistent, readable dark theme.

#### Scenario: Color scheme
- **WHEN** the report is rendered
- **THEN** it SHALL use a dark background with light text
- **AND** status colors: green (#4caf50) for merged/pass, blue (#2196f3) for running, yellow (#ff9800) for pending/warning, red (#f44336) for failed/uncovered, orange (#ff5722) for merge-blocked/failed-change, gray (#757575) for skipped/removed

#### Scenario: Responsive layout
- **WHEN** the report is viewed in a browser
- **THEN** it SHALL be readable at viewport widths from 800px to 1920px
- **AND** tables SHALL use horizontal scrolling if needed on narrow viewports

#### Scenario: Timestamp footer
- **WHEN** the report is generated
- **THEN** a footer SHALL display "Last updated: {ISO-8601 timestamp}" and "Auto-refreshes every 15 seconds"
