## ADDED Requirements

### Requirement: Change 12 — Sprint retrospective fixes
Create `benchmark/changes/12-sprint-retro.md` that bundles 5 cross-cutting bugs into a single fix task.

Agent input lists 5 bugs (NO hints about which files to change):
1. API list endpoint response format inconsistency — standardize to `{ data: [...], total: N }`
2. Payout rounding off-by-one with 3+ vendors — implement largest-remainder method
3. Expired reservation checkout returns 500 instead of 400 with helpful message
4. Missing `@@index([vendorId])` on SubOrder table
5. Seed data mixes dollars and cents after C09 migration

Evaluator notes must specify:
- **Memory prediction**: This is the HARDEST memory test. Agent needs to know: (a) which endpoints return which format, (b) where payout split is calculated, (c) where reservation validation happens in checkout, (d) the SubOrder model location, (e) the seed script path and its money values.
- **Expected time difference**: Memory agent should fix all 5 in ~1 iteration. No-memory agent may need 2-3 iterations as it searches for each location.
- **Measurable**: `test-12.sh` runs all 5 checks

#### Scenario: All bugs fixed in single iteration
- **WHEN** memory-enabled agent processes C12
- **THEN** all 5 bugs are fixed and test-12.sh passes on first try

#### Scenario: No-memory agent needs multiple iterations
- **WHEN** baseline agent processes C12
- **THEN** likely fixes 3-4 bugs, test-12.sh partially fails, needs follow-up iteration

---

### Requirement: Bug descriptions are vague on purpose
Each bug in C12 describes the SYMPTOM, not the location. Examples:
- "API list endpoints return different formats" — doesn't say WHICH endpoints
- "Payout rounding is off" — doesn't say which function or file
- "Checkout returns 500 on expired reservation" — doesn't say where the error handling is missing

This forces the agent to KNOW or SEARCH. Memory makes knowing cheaper than searching.

#### Scenario: Vague bug description
- **WHEN** agent reads "API list endpoints return different formats"
- **THEN** must identify ALL list endpoints across the codebase (products, vendors, orders, coupons, sub-orders) and check each one
