## ADDED Requirements

### Requirement: Weighted scoring formula

The scoring script SHALL calculate weighted scores using:

```
Raw    = sum(A_pass) * 1 + sum(B_pass) * 2 + sum(C_pass) * 3 + sum(D_pass) * 2 + sum(E_pass) * 3
Max    = A_total * 1 + B_total * 2 + C_total * 3 + D_total * 2 + E_total * 3
Score  = Raw / Max * 100%
```

With the 14-trap, 35-probe design:
- A_total across C03-C05: ~10 probes
- B_total across C03-C05: ~8 probes (some traps probed multiple times)
- C_total across C03-C05: 3 probes
- D_total across C03-C05: 5 probes
- E_total across C03-C05: 3 probes

#### Scenario: Score calculation example

- **WHEN** a run passes 8A, 5B, 1C, 3D, 1E probes
- **THEN** Raw = 8*1 + 5*2 + 1*3 + 3*2 + 1*3 = 8+10+3+6+3 = 30
- **AND** the percentage is 30/Max * 100%

### Requirement: Per-category breakdown in output

The scoring script SHALL output both overall weighted score and per-category breakdown:

```
Category A (code-readable, x1):  8/10  (80%)
Category B (human-override, x2): 5/8   (63%)
Category C (debug-knowledge, x3): 1/3  (33%)
Category D (architecture, x2):   3/5   (60%)
Category E (stakeholder, x3):    1/3   (33%)

Weighted Score: 30/66 (45%)
```

#### Scenario: Breakdown shows category-level performance

- **WHEN** score.sh runs against a completed benchmark directory
- **THEN** it SHALL display pass/total for each of the 5 categories
- **AND** the overall weighted percentage

### Requirement: Comparison mode

The scoring script SHALL support comparing two runs:

```bash
./scripts/score.sh --compare <dir-a> <dir-b>
```

Output SHALL show side-by-side category scores and overall delta.

#### Scenario: Comparison output

- **WHEN** score.sh --compare is run with two directories
- **THEN** it SHALL display a table with Mode A scores, Mode B scores, and deltas for each category
- **AND** highlight categories where the delta is largest

### Requirement: JSON output for scripting

The scoring script SHALL support `--json` flag for machine-readable output containing:
- Per-change probe results (pass/fail for each probe ID)
- Per-category totals
- Weighted score
- Run metadata (mode, timestamp, directory)

#### Scenario: JSON output is parseable

- **WHEN** score.sh --json is run
- **THEN** the output SHALL be valid JSON
- **AND** contain `categories`, `probes`, `weighted_score`, and `metadata` fields

### Requirement: Probe verification uses curl and jq

Each probe SHALL be implemented as a bash function that:
1. Makes HTTP requests to the running server using curl
2. Checks response content using jq for JSON parsing
3. Returns PASS (exit 0) or FAIL (exit 1) with a descriptive message
4. Is idempotent (can be re-run without side effects)

#### Scenario: Probe function structure

- **WHEN** a probe function runs
- **THEN** it SHALL output "PASS: <probe-id> — <description>" or "FAIL: <probe-id> — <description>"
- **AND** the exit code SHALL be 0 for pass, 1 for fail

### Requirement: Concurrent write test for C1 probe

The C1 (busy_timeout) probe SHALL:
1. Send 10 concurrent POST requests using background curl processes
2. Wait for all to complete
3. Check that none returned SQLITE_BUSY or 500 errors
4. Pass if all requests succeeded

#### Scenario: C1 probe tests concurrent write safety

- **WHEN** test-04.sh runs the C1 probe
- **THEN** it SHALL launch 10 concurrent notification creation requests
- **AND** verify all return 2xx status codes
- **AND** FAIL if any return 500 with SQLITE_BUSY or similar error
