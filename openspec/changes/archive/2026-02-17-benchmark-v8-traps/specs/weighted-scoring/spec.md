## ADDED Requirements

### Requirement: Trap category weights
score.sh SHALL assign weights to trap categories:
- **Category A** (code-readable: T1, T3, T5): weight 1
- **Category B** (human override: T2-updated, T4-updated, T6-updated, T7, T8, T10): weight 2
- **Category C** (forward-looking: T9): weight 3

Note: T2, T4, T6 move from category A to B because their correct implementation now depends on C02 corrections (fault format with dot.notation codes, fmtDate consistency, ok+result wrapper).

#### Scenario: Weighted score calculation
- **WHEN** score.sh runs with 8/8 category-A probes and 0/6 category-B probes and 0/1 category-C probes
- **THEN** raw score = 8*1 + 0*2 + 0*3 = 8
- **AND** max score = 8*1 + 6*2 + 1*3 = 23
- **AND** percent = 34%

#### Scenario: Perfect score
- **WHEN** all probes pass
- **THEN** raw = 8 + 12 + 3 = 23, percent = 100%

### Requirement: Comparison output format
score.sh --compare SHALL display per-category subtotals:

```
MemoryProbe v8 Comparison
=========================

Category A (code-readable):
             Mode A    Mode B   Delta
T1 paging     2/3       3/3     +1
T3 remove     2/2       2/2      0
T5 IDs        2/2       2/2      0
Subtotal      6/7       7/7     +1

Category B (human override):
             Mode A    Mode B   Delta
T7 err.code   0/3       3/3     +3
T8 result-key  0/3       3/3     +3
T10 order      0/2       2/2     +2
Subtotal      0/8       8/8     +8

Category C (forward-looking):
             Mode A    Mode B   Delta
T9 batch-POST  0/1       1/1     +1
Subtotal      0/1       1/1     +1

Weighted Score:
  Mode A:  6/23 (26%)
  Mode B: 23/23 (100%)
  Delta: +74%
```

#### Scenario: Comparison with both modes
- **WHEN** `score.sh --compare <dir-a> <dir-b>` runs
- **THEN** output shows per-category breakdown with subtotals
- **AND** output shows weighted final score with percent

### Requirement: n=3 run protocol in run-guide
run-guide.md SHALL document the n=3 protocol:
1. Run each mode 3 times with fresh `init.sh` each time
2. Score each run independently
3. Report median weighted score
4. Include min/max range for variance indication

#### Scenario: Run guide includes n=3 instructions
- **WHEN** a user reads run-guide.md
- **THEN** they find step-by-step instructions for 3 runs per mode
- **AND** instructions for computing median score

### Requirement: JSON output includes categories
score.sh --json SHALL include trap categories and weights in output.

#### Scenario: JSON output structure
- **WHEN** `score.sh <dir> --json` runs
- **THEN** JSON includes `categories: {A: {weight, pass, total}, B: {...}, C: {...}}`
- **AND** JSON includes `weightedScore: {raw, max, percent}`
