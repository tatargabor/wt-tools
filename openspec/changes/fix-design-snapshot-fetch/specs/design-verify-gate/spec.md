## MODIFIED Requirements

### Requirement: design_snapshot_dir threaded through verifier call chain

The `design_snapshot_dir` parameter SHALL be threaded from the engine through the full verification pipeline: `poll_change()` → `handle_change_done()` → `review_change()`. Without this threading, `review_change()` never receives the snapshot dir and the design compliance section is always empty.

#### Scenario: handle_change_done receives design_snapshot_dir
- **WHEN** `handle_change_done()` is called from the poll loop
- **THEN** it receives `design_snapshot_dir` (defaulting to `os.getcwd()` from the engine)
- **AND** passes it to `review_change()`

#### Scenario: poll_change threads design_snapshot_dir
- **WHEN** `poll_change()` detects a change is done
- **THEN** it passes `design_snapshot_dir` to `handle_change_done()`

### Requirement: Design compliance section in code review

The verifier SHALL include a design compliance section in the code review prompt when a `design-snapshot.md` exists. The placeholder `pass` in `review_change()` SHALL be replaced with an actual call to `build_design_review_section()` via bash bridge subprocess.

#### Scenario: Review with design snapshot
- **WHEN** `review_change()` runs for a change
- **AND** `design_snapshot_dir` is provided and contains `design-snapshot.md`
- **THEN** the verifier calls `build_design_review_section()` via bash subprocess
- **AND** the returned design compliance section is included in the review prompt template
- **AND** the review prompt instructs the reviewer to compare Tailwind classes against design token values

#### Scenario: Review without design snapshot
- **WHEN** `review_change()` runs for a change
- **AND** `design_snapshot_dir` is empty or contains no `design-snapshot.md`
- **THEN** `design_compliance` remains an empty string
- **AND** the review proceeds without a design compliance section

#### Scenario: build_design_review_section fails gracefully
- **WHEN** `review_change()` calls `build_design_review_section()` via bash subprocess
- **AND** the subprocess returns non-zero (e.g., malformed snapshot)
- **THEN** `design_compliance` remains an empty string
- **AND** the review proceeds without design compliance (non-fatal)
- **AND** a warning is logged
