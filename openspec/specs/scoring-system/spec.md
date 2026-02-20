# Scoring System

## Overview

Fully automated, grep-based scoring. No transcript review, no subjective judgment. Runs in <5 seconds after benchmark completion.

## Score Types

### Convention Probe Score (per probe)

Binary: **PASS** or **FAIL**.

A probe passes if the relevant source files contain the project convention pattern AND do not contain the standard fallback pattern. Specifically:

```
PASS  = project_pattern_found AND NOT standard_pattern_found
FAIL  = NOT project_pattern_found OR standard_pattern_found
```

### Per-Trap Score (aggregate across probes)

Fraction: `probes_passed / total_probes` for that trap.

Example: T1 has 3 probes (C03, C04, C05). If C03 and C04 pass but C05 fails: T1 = 2/3.

### Overall Score

Fraction: `total_probes_passed / 15` expressed as percentage.

Example: 12/15 = 80%.

## Probe-to-File Mapping

The scoring script needs to know WHICH files to check for WHICH trap in WHICH change. This mapping is deterministic based on project structure:

### C03 (Comments + Activity) — 4 probes

| Trap | File Pattern | Check |
|------|-------------|-------|
| T1 | `src/routes/comments.js` | Pagination format in list response |
| T2 | `src/routes/comments.js` | Error format in error handlers |
| T5 | `src/routes/comments.js` OR `src/db/comments.js` | `cmt_` prefix in ID generation |
| T6 | `src/routes/comments.js` | `ok: true` in responses |

### C04 (Dashboard + Export) — 5 probes

| Trap | File Pattern | Check |
|------|-------------|-------|
| T1 | `src/routes/dashboard.js` | Pagination format |
| T2 | `src/routes/dashboard.js` OR `src/routes/export.js` | Error format |
| T3 | `src/routes/dashboard.js` OR `src/db/*.js` | `removedAt` in notification queries |
| T4 | `src/routes/export.js` | `fmtDate` import/usage |
| T6 | `src/routes/dashboard.js` AND `src/routes/export.js` | `ok: true` |

### C05 (Bulk Operations) — 6 probes

| Trap | File Pattern | Check |
|------|-------------|-------|
| T1 | `src/routes/bulk.js` | Pagination format |
| T2 | `src/routes/bulk.js` | Error format |
| T3 | `src/routes/bulk.js` OR `src/db/*.js` | `removedAt` in bulk archive |
| T4 | `src/routes/bulk.js` | `fmtDate` in report timestamps |
| T5 | `src/routes/bulk.js` OR `src/db/*.js` | `bat_` prefix |
| T6 | `src/routes/bulk.js` | `ok: true` |

## Scoring Script Logic

```bash
#!/bin/bash
# score.sh — MemoryProbe convention scoring
# Usage: ./score.sh <project-dir>

PROJECT="$1"
PASS=0; FAIL=0; TOTAL=0; DETAILS=""

probe() {
  local trap="$1" change="$2" desc="$3"
  local pass_pattern="$4" fail_pattern="$5"
  shift 5; local files=("$@")

  TOTAL=$((TOTAL + 1))
  local found_pass=false found_fail=false

  for f in "${files[@]}"; do
    [ -f "$PROJECT/$f" ] || continue
    grep -qE "$pass_pattern" "$PROJECT/$f" && found_pass=true
    [ -n "$fail_pattern" ] && grep -qE "$fail_pattern" "$PROJECT/$f" && found_fail=true
  done

  if $found_pass && ! $found_fail; then
    PASS=$((PASS + 1))
    DETAILS+="  PASS  $trap  $change  $desc\n"
  else
    FAIL=$((FAIL + 1))
    DETAILS+="  FAIL  $trap  $change  $desc\n"
  fi
}

# --- C03 probes ---
probe T1 C03 "comment pagination"   '"paging"' '"total"|"limit"'   src/routes/comments.js
probe T2 C03 "comment errors"       '"fault"'  '"error"|"message"' src/routes/comments.js
probe T5 C03 "comment ID prefix"    'cmt_'     'AUTO_INCREMENT|autoincrement|uuid' src/routes/comments.js src/db/comments.js
probe T6 C03 "comment ok wrapper"   '"ok"'     ''                  src/routes/comments.js

# --- C04 probes ---
probe T1 C04 "dashboard pagination" '"paging"' '"total"|"limit"'   src/routes/dashboard.js
probe T2 C04 "export errors"        '"fault"'  '"error"|"message"' src/routes/export.js src/routes/dashboard.js
probe T3 C04 "notification remove"  'removedAt' 'deletedAt|isDeleted' src/routes/dashboard.js src/db/notifications.js
probe T4 C04 "export date format"   'fmtDate'  'toISOString|formatDate|dayjs|moment' src/routes/export.js
probe T6 C04 "dashboard ok wrapper" '"ok"'     ''                  src/routes/dashboard.js src/routes/export.js

# --- C05 probes ---
probe T1 C05 "bulk pagination"      '"paging"' '"total"|"limit"'   src/routes/bulk.js
probe T2 C05 "bulk errors"          '"fault"'  '"error"|"message"' src/routes/bulk.js
probe T3 C05 "bulk soft-delete"     'removedAt' 'deletedAt|isDeleted' src/routes/bulk.js src/db/events.js
probe T4 C05 "bulk report dates"    'fmtDate'  'toISOString|formatDate|dayjs|moment' src/routes/bulk.js
probe T5 C05 "batch ID prefix"      'bat_'     'AUTO_INCREMENT|autoincrement|uuid' src/routes/bulk.js src/db/batch.js
probe T6 C05 "bulk ok wrapper"      '"ok"'     ''                  src/routes/bulk.js

# --- Results ---
echo ""
echo "MemoryProbe Score: $PASS/$TOTAL ($((PASS * 100 / TOTAL))%)"
echo ""
echo -e "$DETAILS"
```

## File Flexibility

Agents may name files differently (e.g., `comment-routes.js` instead of `comments.js`). The scoring script should handle this with glob patterns:

```bash
# Instead of exact paths, use find:
find "$PROJECT/src" -name "*comment*" -name "*.js"
find "$PROJECT/src" -name "*bulk*" -name "*.js"
```

The final implementation should use flexible file discovery rather than hardcoded paths.

## Output Format

### Human-Readable (default)
```
MemoryProbe Score: 12/15 (80%)

  PASS  T1  C03  comment pagination
  PASS  T2  C03  comment errors
  FAIL  T5  C03  comment ID prefix
  PASS  T6  C03  comment ok wrapper
  PASS  T1  C04  dashboard pagination
  ...
```

### Machine-Readable (--json flag)
```json
{
  "score": {"pass": 12, "fail": 3, "total": 15, "percent": 80},
  "traps": {
    "T1": {"pass": 3, "total": 3},
    "T2": {"pass": 2, "total": 3},
    "T3": {"pass": 1, "total": 2},
    "T4": {"pass": 2, "total": 2},
    "T5": {"pass": 1, "total": 2},
    "T6": {"pass": 3, "total": 3}
  },
  "probes": [
    {"trap": "T1", "change": "C03", "desc": "comment pagination", "result": "PASS"},
    ...
  ]
}
```

## Comparison Report

When both Mode A and Mode B (or C) results exist, generate a comparison:

```
MemoryProbe Comparison
=======================

           Mode A    Mode B    Delta
T1 paging    1/3       3/3     +2
T2 errors    0/3       3/3     +3
T3 remove    0/2       2/2     +2
T4 dates     0/2       1/2     +1
T5 IDs       1/2       2/2     +1
T6 ok wrap   1/3       3/3     +2
─────────────────────────────────
Total        3/15     14/15    +11
Percent      20%       93%    +73%
```

## Requirements

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
