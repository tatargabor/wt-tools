## ADDED Requirements

### Requirement: Five trap categories with scoring weights

The benchmark SHALL define exactly 5 trap categories:

| ID | Name | Weight | Description |
|----|------|--------|-------------|
| A | Code-readable | x1 | Conventions visible in C01 source code |
| B | Human override | x2 | Corrections from C02 that override C01/spec conventions |
| C | Debug knowledge | x3 | Bug findings and workarounds shared in C02 review |
| D | Architecture decision | x2 | Design rationale shared in C02 that constrains future choices |
| E | Stakeholder constraint | x3 | External system requirements shared in C02 |

Categories C and E SHALL have the highest weight (x3) because they are impossible to derive from code inspection alone.

#### Scenario: Weighted scoring produces expected baseline vs memory delta

- **WHEN** scoring a baseline run (no memory) and a memory run
- **THEN** the baseline SHOULD score 38-53% weighted (mostly A + some B from code reading)
- **AND** the memory run SHOULD score 76-91% weighted (all categories)
- **AND** the delta SHOULD be >30%

### Requirement: Each trap satisfies three design criteria

Every trap in the benchmark SHALL satisfy:
1. **Code-invisible**: The knowledge required to pass is NOT present in C01 code, project-spec.md, or any file the agent can read (except C02 Developer Notes and recalled memories)
2. **Natural pitfall**: Without memory, the agent's default behavior produces a testably wrong result
3. **Bash-testable**: The probe can be verified by a bash script using curl + jq/grep against the running server

#### Scenario: A-type trap is code-readable

- **WHEN** evaluating an A-type trap (e.g., pagination format)
- **THEN** the correct answer SHALL be discoverable by reading C01 source code
- **AND** a baseline agent that reads existing code SHOULD pass

#### Scenario: C-type trap is code-invisible

- **WHEN** evaluating a C-type trap (e.g., SQLite busy_timeout)
- **THEN** the correct answer SHALL NOT be present in any project file
- **AND** only an agent with memory of C02 Developer Notes can know the required workaround

### Requirement: Fourteen traps across five categories

The benchmark SHALL include exactly 14 traps:

**A-type (4 traps, x1 weight):**
- A1: Pagination format `{entries, paging: {current, size, count, pages}}`
- A2: ID prefix convention (entity-specific prefixes + nanoid)
- A3: Success wrapper `{ok: true, ...}`
- A4: Date helper `fmtDate()` from `lib/fmt.js`

**B-type (4 traps, x2 weight):**
- B1: Error codes use dot.notation not SCREAMING_SNAKE
- B2: Response body wraps payload in `result` key
- B3: Sort parameter uses `?order=newest|oldest` not `?sort=desc|asc`
- B4: Soft-delete uses `removedAt` field name consistently

**C-type (3 traps, x3 weight):**
- C1: SQLite busy_timeout(3000) required for concurrent writes
- C2: Use nanoid(16) not nanoid(8) for batch IDs (collision risk)
- C3: Express body-parser limit must be '1mb' for bulk endpoints

**D-type (3 traps, x2 weight):**
- D1: Categories are flat — dashboard must not add hierarchy
- D2: SQL queries in db/*.js modules — routes call db functions
- D3: Centralized error handler in middleware — no per-route try-catch

**E-type (3 traps, x3 weight):**
- E1: Mobile app requires ISO 8601 dates on GET /events
- E2: Bulk endpoints max 100 items per request
- E3: List endpoints max 1000 results regardless of size param

#### Scenario: All traps have probes in C03-C05

- **WHEN** the benchmark is scored
- **THEN** every trap SHALL be probed at least once across C03, C04, and C05
- **AND** each probe SHALL have a corresponding check in a test script
