## CHANGED Requirements

### Requirement: Arithmetic operations must be safe under set -e
All `(( var++ ))` and `(( var-- ))` expressions in `bin/wt-hook-memory` SHALL use `|| true` to prevent `set -e` from terminating the process when the expression evaluates to 0.

#### Scenario: Counter increment from zero
- **GIVEN** a counter variable initialized to 0
- **WHEN** the counter is incremented with `(( count++ )) || true`
- **THEN** the script SHALL continue execution regardless of the pre-increment value

#### Scenario: Background extraction completes
- **GIVEN** a Stop event with a valid transcript path
- **WHEN** `_stop_run_extraction_bg` runs in the background
- **THEN** `_stop_migrate_staged` SHALL complete without crashing
- **AND** `_stop_raw_filter` SHALL execute afterward
- **AND** the extraction log SHALL contain a "Raw filter complete" entry
