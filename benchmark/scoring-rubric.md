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

### First-Try Test Pass (yes/no)

Did the implementation pass all acceptance criteria on the first attempt (first `npm test` run or first manual verification)?

### Session Length

- **Iterations**: Number of wt-loop iterations spent on this change
- **Tokens**: Total tokens consumed (from `wt-loop history`)
- **Time**: Wall-clock time in minutes

## Run B Memory Metrics (additional)

For Run B (with memory) only, also track:

| Metric | Description |
|--------|-------------|
| Memory recalls | Count of `wt-memory recall` invocations |
| Useful recalls | Recalls that visibly influenced agent behavior (from transcript review) |
| Memories saved | Count of `wt-memory remember` invocations |
| Save quality | Were saves specific and actionable, or vague? (High/Medium/Low) |

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

After scoring all 6 changes, calculate:

| Aggregate Metric | Calculation |
|-----------------|-------------|
| Total dead ends | Sum across all changes |
| Total repeated mistakes | Sum across all changes |
| Total design rework | Sum across all changes |
| First-try pass rate | Count of passes / 6 |
| Total iterations | Sum across all changes |
| Total tokens | Sum across all changes |
| Total time | Sum across all changes |
| Memory efficiency (Run B) | Useful recalls / total recalls |
| Save rate (Run B) | Memories saved / changes completed |

## Scoring Tips

- Review the full session transcript (`ralph-loop.log`), not just the final code
- Look for moments where the agent backtracks, comments on confusion, or retries
- Compare the agent's approach to the trap documentation — did they fall into the trap?
- For Run B, trace the causal chain: recall → behavior change → better outcome
- When in doubt, score conservatively (lower score = better performance)
