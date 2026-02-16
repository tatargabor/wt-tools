# Scoring Rubric

## Per-Change Metrics

Each change is scored on these dimensions after reviewing the session transcript.

### Dead Ends (0-5)

A dead end is when the agent pursues an approach, realizes it doesn't work, and backtracks.

| Score | Description |
|-------|-------------|
| 0 | No dead ends — clean implementation path |
| 1 | One minor dead end (caught and fixed within a few lines) |
| 2 | One significant dead end (wrong approach requiring file rewrites) |
| 3 | Multiple dead ends, but all resolved |
| 4 | Major dead end requiring architectural rethink |
| 5 | Stuck in dead end — change incomplete or deeply flawed |

**Examples:**
- Score 1: Agent uses wrong Prisma syntax, gets error, fixes immediately
- Score 3: Agent builds cart referencing product IDs, realizes it needs variant IDs, refactors cart API
- Score 5: Agent builds flat order model, can't implement per-vendor status in C6, runs out of iterations

### Repeated Mistakes (0-3)

A repeated mistake is when the agent makes the same error that occurred in a previous change (or earlier in the same change).

| Score | Description |
|-------|-------------|
| 0 | No repeated mistakes |
| 1 | One repeated mistake, quickly resolved |
| 2 | Multiple repeated mistakes or one that took significant time |
| 3 | Same critical mistake repeated, indicating no learning across changes |

**Examples:**
- Score 0: Agent remembers to run `prisma generate` after schema changes (no repeat of C1 error)
- Score 1: Agent forgets WAL mode again in C5 but fixes within one iteration
- Score 3: Agent hits SQLITE_BUSY in C2 AND C5, spending multiple iterations debugging each time

### Design Rework (0-3)

Design rework is when the agent needs to change code from a previous change to make the current change work.

| Score | Description |
|-------|-------------|
| 0 | No design rework needed — previous architecture supports current change |
| 1 | Minor adjustments to previous code (adding a field, tweaking an API response) |
| 2 | Significant rework (refactoring a model, rewriting API routes) |
| 3 | Fundamental architectural rework (redesigning core data model) |

**Examples:**
- Score 0: C6 works cleanly because C3 used nested orders
- Score 1: Adding vendorId to product listing API response for C3
- Score 3: Refactoring from flat orders to nested orders in C6 because C3's architecture was wrong

### Test Pass/Fail (per change)

Each change has an acceptance test (`tests/test-NN.sh`). Track:

| Metric | Description |
|--------|-------------|
| First-try pass | Did the test pass on the first run after implementation? (yes/no) |
| Iterations to pass | How many test-fix-retest cycles to achieve a full pass? |
| Checks passed | Number of individual checks passed (e.g., 4/5) |
| Checks failed | Number of individual checks failed |

**For revision/feedback changes (07-12), also track:**

| Metric | Description |
|--------|-------------|
| Repeat-failure | Did the agent reintroduce a pattern the change explicitly rejected? |
| Counter-pattern | Did the agent enhance the old pattern instead of replacing it? |

### Session Length

- **Iterations**: Number of wt-loop iterations spent on this change
- **Tokens**: Total tokens consumed (from `wt-loop history`)
- **Time**: Wall-clock time in minutes

## Revision Change Scoring (C07-C09)

Changes 07-09 revise earlier decisions. Additional scoring:

| Metric | C07 | C08 | C09 |
|--------|-----|-----|-----|
| Found all mutation points | Stock add/remove/clear | Image references across codebase | All money fields |
| Correctly moved/migrated | Stock to checkout | JSON to Image table | Decimal/Float to Int |
| Old code fully removed | Cart stock decrement | Product.images column | Float arithmetic |
| Test pass | test-07.sh | test-08.sh | test-09.sh |

**Key question**: How many iterations did the agent need to find all the affected code? Memory agent should know locations; baseline must search.

## Feedback Change Scoring (C10-C11)

Changes 10-11 correct design decisions. Additional scoring:

| Metric | C10 (Cart UX) | C11 (Dashboard) |
|--------|---------------|-----------------|
| Followed correction exactly | No update button, toast, inline edit, CTA | No tabs, flat list, badges, pagination |
| Avoided repeat-failure trap | No confirm(), no Update button reintroduced | Tabs fully removed (not enhanced) |
| Test iterations to pass | test-10.sh iteration count | test-11.sh iteration count |

**Critical**: These changes are designed so that without memory of "the stakeholder explicitly rejected X," the agent defaults to common patterns (adding Update button, keeping tabs). Track whether the agent fell into the trap.

## Sprint Retro Scoring (C12)

Change 12 has 5 cross-cutting bugs. Score each individually:

| Bug | What to check | Memory value |
|-----|--------------|--------------|
| 1. API format | All list endpoints use `{data:[], total:N}` | Knows all endpoints |
| 2. Payout rounding | Largest-remainder method, sum == payment | Knows payout code location |
| 3. Expired reservation | Returns 400 (not 500) with message | Knows checkout validation |
| 4. Missing index | `@@index([vendorId])` on SubOrder | Knows schema location |
| 5. Seed data | All money values in cents | Knows seed script |

**Expected iteration difference**: Memory agent should fix all 5 in ~1 iteration. Baseline may need 2-3 iterations searching for each location.

## Run B Memory Metrics (additional)

For Run B (with memory) only, also track:

| Metric | Description |
|--------|-------------|
| Memory recalls | Count of `wt-memory recall` invocations |
| Useful recalls | Recalls that visibly influenced agent behavior (from transcript review) |
| Memories saved | Count of `wt-memory remember` invocations |
| Save quality | Were saves specific and actionable, or vague? (High/Medium/Low) |
| Recall efficiency | useful recalls / total recalls |

### How to identify "useful recalls"

A recall is useful if, after receiving recall results, the agent:
- Explicitly references the recalled information
- Adjusts its approach based on recalled knowledge
- Avoids a mistake that the baseline agent made

A recall is NOT useful if:
- The agent recalls but doesn't use the information
- The recalled memories are irrelevant to the current task
- The agent would have done the same thing without the recall

## Aggregate Scoring

After scoring all 12 changes, calculate:

| Aggregate Metric | Calculation |
|-----------------|-------------|
| Total dead ends | Sum across all changes |
| Total repeated mistakes | Sum across all changes |
| Total design rework | Sum across all changes |
| Test pass rate | Changes with first-try pass / 12 |
| Total test iterations | Sum of test-fix cycles across all changes |
| Total iterations | Sum of wt-loop iterations across all changes |
| Total tokens | Sum across all changes |
| Total time | Sum across all changes |
| Revision change score | C07+C08+C09 aggregate |
| Feedback change score | C10+C11 aggregate |
| Sprint retro score | C12 bugs fixed on first try (out of 5) |
| Memory efficiency (Run B) | Useful recalls / total recalls |
| Save rate (Run B) | Memories saved / changes completed |

## Scoring Tips

- Review the full session transcript (`ralph-loop.log`), not just the final code
- Look for moments where the agent backtracks, comments on confusion, or retries
- Compare the agent's approach to the trap documentation — did they fall into the trap?
- For Run B, trace the causal chain: recall → behavior change → better outcome
- When in doubt, score conservatively (lower score = better performance)
- **Run the evaluator scripts** (`benchmark/evaluator/`) for automated schema/API/behavior checks
- **Run the test scripts** (`tests/test-NN.sh`) to get objective pass/fail data
- Focus on C07-C12 for the largest expected delta between runs
