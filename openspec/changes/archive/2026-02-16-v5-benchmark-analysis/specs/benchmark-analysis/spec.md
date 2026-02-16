## ADDED Requirements

### Requirement: Overall metrics table
The analysis SHALL include an aggregate metrics table comparing Run A and Run B with: changes completed, total iterations, total tokens, test pass rate, trap score, and memory count.

#### Scenario: Aggregate comparison
- **WHEN** the v5-results.md is complete
- **THEN** the top-level table shows all aggregate metrics with delta and delta-% columns

### Requirement: Per-change test results
The analysis SHALL document test pass/fail for each change from the results JSON files.

#### Scenario: All changes scored
- **WHEN** results/change-NN.json exists
- **THEN** the analysis records test_pass and test_fail counts for that change in both runs

### Requirement: Convention trap scoring (TRAP-H/I/J/K)
The analysis SHALL score each new convention trap across all relevant changes using code inspection.

#### Scenario: TRAP-H formatPrice audit
- **WHEN** analyzing TRAP-H
- **THEN** check each change's code for: (1) formatPrice imports/usage, (2) inline .toFixed(2) occurrences, and record PASS/FAIL per change per run

#### Scenario: TRAP-I pagination audit
- **WHEN** analyzing TRAP-I
- **THEN** check each list API endpoint for { data, total, page, limit } format and record PASS/FAIL per change per run

#### Scenario: TRAP-J error codes audit
- **WHEN** analyzing TRAP-J
- **THEN** check each API error response for errors.ts constant imports and record PASS/FAIL per change per run

#### Scenario: TRAP-K soft delete audit
- **WHEN** analyzing TRAP-K
- **THEN** check each product query for deletedAt IS NULL filter and record PASS/FAIL per change per run

### Requirement: Original trap scoring (A/B/D/E/F/G)
The analysis SHALL score the v4 traps using the same methodology as v4-results.md.

#### Scenario: Each original trap scored
- **WHEN** analyzing traps A, B, D, E, F, G
- **THEN** record PASS/PARTIAL/FAIL for each run and compare with v4 results

### Requirement: Memory quality audit
The analysis SHALL categorize all Run B memories by value (high/medium/low) and identify gaps.

#### Scenario: Memory categorization
- **WHEN** auditing Run B memories
- **THEN** classify each memory as high-value (influenced behavior), medium-value (correct but unused), or low-value (noise/duplicate)

#### Scenario: Code map effectiveness
- **WHEN** auditing code map memories
- **THEN** count how many changes have code maps (agent vs hook-generated) and assess if they provided location information for later changes

#### Scenario: Convention memory gaps
- **WHEN** checking for convention memories
- **THEN** report whether explicit memories exist for: formatPrice utility, pagination format, errors.ts pattern, soft delete convention

### Requirement: v4 to v5 comparison
The analysis SHALL include a cross-version comparison table showing improvement or regression on each metric.

#### Scenario: Version comparison
- **WHEN** the analysis is complete
- **THEN** a comparison table shows v4 Run A, v4 Run B, v5 Run A, v5 Run B side by side for: trap score, iterations, memory count, memory noise rate

### Requirement: Improvement recommendations
The analysis SHALL list 3-5 prioritized, actionable recommendations for the memory system.

#### Scenario: Recommendations are actionable
- **WHEN** listing recommendations
- **THEN** each includes: the gap observed, evidence from v5 data, concrete suggested change (code/config/prompt level), and expected impact
