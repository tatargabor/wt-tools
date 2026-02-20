## Context

MemoryProbe v1 (current `benchmark/synthetic/`) tests 10 convention traps across 3 categories (A: code-readable, B: human-override, C: forward-looking). Results show +34% memory advantage but only test "does the agent remember format conventions?" Real-world cross-session knowledge loss is much broader: debug findings, architecture decisions, stakeholder constraints. CraftBazaar full benchmark (12 changes) is too expensive and shows no memory advantage because most traps are code-readable.

Current MemoryProbe structure (keep): C01 establishes patterns → C02 introduces corrections/knowledge → C03-C05 probe whether the agent remembers.

## Goals / Non-Goals

**Goals:**
- Expand trap categories from 2 effective (A, B) to 5 (A, B, C, D, E) covering all real-world memory types
- Keep total runtime ~35-40 minutes (5 changes, ~25 max-turns each)
- Keep token budget ~400-450K per run
- Design traps that are **impossible to discover from code alone** (types C, D, E)
- Maintain automated bash-based scoring (no manual annotation needed)
- Target >50% weighted delta between baseline and memory runs

**Non-Goals:**
- Changing the project domain (keep LogBook — simple enough to implement quickly)
- Testing memory latency/performance (shodh benchmarks cover that)
- Testing multi-agent coordination
- Replacing CraftBazaar benchmark (that tests different things: scale, drift, UI)

## Decisions

### Decision 1: Five trap categories with asymmetric weights

| Category | Weight | Description | Why this weight |
|----------|--------|-------------|-----------------|
| A: Code-readable | x1 | Conventions visible in C01 code | Baseline can find these by reading code |
| B: Human override | x2 | C02 corrections that override C01/spec | Conflicts with existing code — memory needed |
| C: Debug knowledge | x3 | Bug/workaround findings from C02 | Impossible to derive from code — only experience |
| D: Architecture decision | x2 | Why X not Y choices from C02 | Agent might choose Y without memory — testable |
| E: Stakeholder constraint | x3 | External requirements from C02 | Invisible in code — pure memory signal |

**Alternative**: Equal weights. Rejected because A-type traps are trivially solvable by code reading, inflating baseline scores and hiding the memory signal.

### Decision 2: C02 Developer Notes as unified knowledge source

All non-code knowledge (types B-E) is planted in C02's "Developer Notes" section. This mirrors real-world code review — a senior dev shares context that doesn't go into code.

**Structure of C02 Developer Notes:**
1. Convention corrections (B) — "switch error format from X to Y"
2. Debug findings (C) — "we hit bug X, workaround is Y"
3. Architecture rationale (D) — "we chose X because Y failed"
4. Stakeholder constraints (E) — "external system requires X"

### Decision 3: Trap design principles

Each trap MUST satisfy all three criteria:
1. **Code-invisible**: The knowledge is NOT derivable from reading C01 code or project-spec.md
2. **Natural pitfall**: Without memory, the agent will choose the "obvious" solution which is wrong
3. **Bash-testable**: Can be verified with curl + jq/grep in a test script

### Decision 4: Keep LogBook domain, extend project-spec.md

Keep the LogBook event logging domain. Extend project-spec.md with:
- SQLite WAL mode mention (but NOT the busy_timeout trick — that's debug knowledge)
- Express body-parser defaults (but NOT the limit increase — that's stakeholder knowledge)
- The spec should look "normal" — traps hide in what the spec DOESN'T say

### Decision 5: Concrete trap inventory

**C02 Developer Notes will plant these 14 knowledge items:**

**B-type (Human override, x2):**
- B1: Error codes → dot.notation (override SCREAMING_SNAKE from C01/spec)
- B2: Response wrapping → `result` key (override flat format from C01)
- B3: Sort parameter → `?order=newest|oldest` not `?sort=desc|asc`
- B4: Soft-delete field → `removedAt` (spec says it but agent might use `deletedAt`)

**C-type (Debug knowledge, x3):**
- C1: SQLite BUSY under concurrent writes → set `busy_timeout(3000)` in db setup
- C2: nanoid collision → use `nanoid(16)` not `nanoid(8)` for batch IDs
- C3: Express body-parser → set `limit: '1mb'` for bulk endpoints (default 100kb causes 413)

**D-type (Architecture decision, x2):**
- D1: Categories are flat (not hierarchical) → dashboard must NOT add parent/child
- D2: SQL queries go in `db/*.js` modules → routes should call db functions, not inline SQL
- D3: Centralized error handler in middleware → don't add try-catch per route

**E-type (Stakeholder constraint, x3):**
- E1: Mobile app expects ISO 8601 dates on GET /events → don't change createdAt format
- E2: Ops team limit → bulk endpoints max 100 items per request
- E3: Monitoring alert → list endpoints max 1000 results regardless of `size` param

**A-type (Code-readable, x1) — derived from C01 code:**
- A1: Pagination format `{entries, paging: {current, size, count, pages}}`
- A2: ID prefix convention (`evt_`, `cat_`, `cmt_`, `tag_` + nanoid)
- A3: Success wrapper `{ok: true, ...}`
- A4: Date helper `fmtDate()` from `lib/fmt.js`

**Total: 14 traps, probed across C03-C05 = ~35+ individual probes**

### Decision 6: Probe distribution across C03-C05

| Change | A probes | B probes | C probes | D probes | E probes | Total |
|--------|----------|----------|----------|----------|----------|-------|
| C03: Comments + Activity | A1,A2,A3 | B1,B2 | - | D2,D3 | - | 9 |
| C04: Dashboard + Export | A1,A3,A4 | B1,B2,B3 | C1 | D1,D2 | E1 | 12 |
| C05: Bulk Operations | A1,A2,A3 | B1,B2,B4 | C2,C3 | D2 | E2,E3 | 13 |

C05 has the most probes and the highest expected delta (furthest from C01).

### Decision 7: Scoring formula

```
Raw    = A_pass*1 + B_pass*2 + C_pass*3 + D_pass*2 + E_pass*3
Max    = A_total*1 + B_total*2 + C_total*3 + D_total*2 + E_total*3

Expected max = 10*1 + 13*2 + 3*3 + 6*2 + 3*3 = 10+26+9+12+9 = 66
```

Expected scores:
- Mode A (baseline): ~25-35/66 (38-53%) — gets most A, some B from code reading
- Mode B (memory): ~50-60/66 (76-91%) — gets most everything except edge cases
- Delta: **+30-40%** (stronger than v1's +34% due to C/D/E traps)

## Risks / Trade-offs

- [C-type traps are hard to test with curl] → Design C1 (busy_timeout) as a concurrent write test using background curl, C2/C3 as payload/format checks
- [Too many traps may overwhelm C02 Developer Notes] → Keep notes natural and grouped logically (review feedback → debug findings → architecture → stakeholder)
- [Agent may read spec and ignore Developer Notes] → Notes are in the change file, not the spec — agent must read the change to implement it
- [Scoring script complexity] → Keep each probe as a simple function: start server, curl, check response with jq, pass/fail
