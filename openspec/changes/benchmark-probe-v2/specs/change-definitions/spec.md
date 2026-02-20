## ADDED Requirements

### Requirement: C01 establishes baseline conventions in code

C01 (Event CRUD) SHALL establish these patterns in working code:
- Pagination: `{entries: [...], paging: {current, size, count, pages}}`
- Errors: `{fault: {reason, code: "SCREAMING_SNAKE", ts}}`
- Success: `{ok: true, ...payload}` (flat, no `result` wrapper)
- IDs: prefixed nanoid — `evt_` + `nanoid(12)`, `cat_` + `nanoid(12)`
- Dates: `fmtDate()` helper in `lib/fmt.js` returns `YYYY/MM/DD HH:mm`
- Soft-delete: `removedAt` column
- DB layer: queries in `db/events.js`, called from `routes/events.js`
- Error handling: centralized middleware in `middleware/errors.js`

C01 code SHALL intentionally use SCREAMING_SNAKE error codes and flat response format to create conflict with C02 corrections.

#### Scenario: C01 produces working CRUD API

- **WHEN** C01 is implemented and test-01.sh runs
- **THEN** all event and category CRUD operations pass
- **AND** the code establishes all A-type conventions

### Requirement: C02 plants knowledge across all 5 categories via Developer Notes

C02 (Tags & Filtering) SHALL include a "Developer Notes" section containing knowledge items for categories B through E. The notes SHALL be written as natural code review feedback, not as a formal list.

The Developer Notes SHALL be structured as:

1. **Convention corrections (B-type):**
   - "Switch error codes from SCREAMING_SNAKE to dot.notation starting C03"
   - "Wrap response data in a `result` key starting C03"
   - "Use `?order=newest|oldest` for sort params, not `?sort=desc|asc`"
   - "Always use `removedAt` for soft-delete (never `deletedAt` or `deleted`)"

2. **Debug findings (C-type):**
   - "SQLite throws BUSY errors under concurrent writes. Set `busy_timeout(3000)` in db setup. We lost 2 hours debugging this."
   - "nanoid(8) caused ID collisions in production batch operations. Use nanoid(16) for any batch/bulk IDs."
   - "Express body-parser default limit is 100kb. Bulk endpoints need `limit: '1mb'` or large payloads get 413."

3. **Architecture rationale (D-type):**
   - "Categories are flat — we tried hierarchical and it was a UX disaster. Don't add parent/child to categories."
   - "Keep SQL queries in db/*.js modules. Routes should call db functions, not inline SQL."
   - "Error handling goes in middleware/errors.js. Don't add try-catch blocks in individual routes."

4. **Stakeholder constraints (E-type):**
   - "Mobile app v2 (in production) consumes GET /events and expects ISO 8601 createdAt. Don't change date format."
   - "Ops team requirement: bulk endpoints must reject >100 items per request."
   - "Monitoring shows timeouts above 5MB response. Cap list endpoint results at 1000 max."

C02 itself SHALL NOT apply B-type corrections — those take effect starting C03. C02 tags implementation uses C01 conventions.

#### Scenario: C02 Developer Notes are agent-visible but not in code

- **WHEN** the agent reads C02's change definition file
- **THEN** all 14 knowledge items (4B + 3C + 3D + 3E) are present in the Developer Notes section
- **AND** the notes are phrased as natural review feedback
- **AND** none of this knowledge is present in project-spec.md or C01 code

### Requirement: C03 probes conventions, architecture, and override knowledge

C03 (Comments & Activity Log) SHALL test:
- A1: Pagination format on comment list
- A2: ID prefixes for comments (`cmt_`) and activity entries (`act_`)
- A3: Success wrapper on all responses
- B1: Error codes use dot.notation (not SCREAMING_SNAKE from C01)
- B2: Response data wrapped in `result` key
- D2: SQL queries in db/comments.js, not inline in routes
- D3: Error handling via middleware, not per-route try-catch

Total C03 probes: 9 (3A + 2B + 0C + 2D + 0E)

#### Scenario: C03 requirements say "follow existing conventions" without specifying details

- **WHEN** the agent reads C03 change definition
- **THEN** the requirements SHALL say "follow existing project conventions" and "use existing error format"
- **AND** the requirements SHALL NOT repeat specific convention details
- **AND** the agent must recall or discover the correct conventions

### Requirement: C04 probes all categories including debug and stakeholder

C04 (Dashboard & Export) SHALL test:
- A1: Pagination on dashboard/recent and notifications
- A3: Success wrapper
- A4: Date helper fmtDate() for timeline and export dates
- B1: Error codes use dot.notation
- B2: Response wrapping with `result` key
- B3: Sort parameter uses `?order=newest|oldest` on dashboard/recent
- C1: busy_timeout set in db setup (tested via concurrent dashboard queries)
- D1: Dashboard category aggregation is flat (no hierarchy)
- D2: SQL queries in db modules
- E1: GET /events createdAt stays ISO 8601 (export must not change it)

Total C04 probes: 12 (3A + 3B + 1C + 2D + 1E — missing A2 since no new entities with IDs)

Wait — C04 has notifications with IDs. Correction:
- A2: Notification IDs use `ntf_` prefix

Total C04 probes: 13 (4A + 3B + 1C + 2D + 1E — but we said A1,A2,A3,A4 = 4A)

#### Scenario: C04 includes natural trigger for debug trap C1

- **WHEN** test-04.sh runs the C1 probe
- **THEN** it SHALL send multiple concurrent write requests to the dashboard/notification system
- **AND** verify the server does not return SQLITE_BUSY errors

### Requirement: C05 probes all categories with maximum density

C05 (Bulk Operations) SHALL test:
- A1: Pagination on bulk/history
- A2: Batch IDs use `bat_` prefix
- A3: Success wrapper
- B1: Error codes use dot.notation
- B2: Response wrapping with `result` key
- B4: Bulk archive uses `removedAt` for soft-delete
- C2: Batch IDs use nanoid(16) not nanoid(8)
- C3: Body-parser limit set to '1mb' (large bulk payload doesn't 413)
- D2: SQL queries in db/bulk.js module
- E2: Bulk endpoints reject >100 items
- E3: Bulk history list capped at 1000 results

Total C05 probes: 13 (3A + 3B + 2C + 1D + 2E)

#### Scenario: C05 stakeholder constraints are testable

- **WHEN** test-05.sh runs the E2 probe
- **THEN** it SHALL POST a bulk operation with 150 items
- **AND** verify the server returns 400 with error code `bulk.limit_exceeded`

- **WHEN** test-05.sh runs the E3 probe
- **THEN** it SHALL request bulk/history with `?size=2000`
- **AND** verify the response contains at most 1000 entries

### Requirement: Evaluator notes are stripped from agent-visible files

Each change definition file SHALL have evaluator notes below a `<!-- EVALUATOR NOTES BELOW -->` marker. The init script SHALL strip everything below this marker when copying change files to the agent-visible directory.

#### Scenario: Agent cannot see evaluator notes

- **WHEN** init.sh copies change files to the target project
- **THEN** everything below `<!-- EVALUATOR NOTES BELOW` SHALL be removed
- **AND** a verification step SHALL grep for "EVALUATOR NOTES" and fail if found
