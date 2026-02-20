# Change 02: Tags & Filtering

## Agent Input

### Overview

Add a tagging system to LogBook. Events can have multiple tags, and users can filter events by tag, category, severity, and date range.

### Requirements

1. **Tag model**: Create a `Tag` table (see project spec) and an `EventTag` join table for the many-to-many relationship.

2. **Tag API** (`src/routes/tags.js`):
   - `GET /tags` — List all tags (no pagination needed — tags are few)
   - `POST /tags` — Create a tag (requires `name`, must be unique)
   - `DELETE /tags/:id` — Hard-delete a tag and its EventTag associations

3. **Event tagging**:
   - `POST /events/:id/tags` — Attach a tag to an event. Body: `{"tagId": "tag_xxx"}`. Return 409 if already attached.
   - `DELETE /events/:id/tags/:tagId` — Remove a tag from an event.
   - `GET /events/:id` — Include `tags` array in the event response (list of `{id, name}`).

4. **Event filtering** — Enhance `GET /events`:
   - `?category=cat_xxx` — Filter by category ID
   - `?severity=critical` — Filter by severity level
   - `?tag=tag_xxx` — Filter by tag (events that have this tag)
   - `?from=2026-01-01&to=2026-02-01` — Filter by date range (inclusive)
   - Filters are combinable (AND logic)
   - Pagination still applies on top of filters

5. **Seed tags**: Add 5 tags to the seed script (`deployment`, `incident`, `release`, `maintenance`, `security`) and assign 2-3 tags to each existing event.

### Developer Notes (from code review of C01)

We reviewed the C01 implementation and have feedback for the team. Some are corrections to apply in future changes, some are things we learned the hard way. **Do NOT apply these to C02 itself** — the C02 API spec is finalized. These take effect starting C03.

#### Convention Corrections

1. **Error code format**: Starting in C03, switch from SCREAMING_SNAKE error codes (like `EVT_NOT_FOUND`) to **dot.notation** format. Use lowercase with dots: `event.not_found`, `comment.invalid_body`, `export.unsupported_format`. The SCREAMING_SNAKE convention was inherited from an old Java service and doesn't match our frontend's error handling library. Don't change C01/C02 error codes.

2. **Response nesting**: Starting in C03, wrap entity data in a `result` key. This helps the frontend team distinguish payload from metadata.
   - List responses: `{"ok": true, "result": {"entries": [...], "paging": {...}}}`
   - Single-item responses: `{"ok": true, "result": {"comment": {...}}}`
   - Action responses: `{"ok": true, "result": {"removed": true}}`
   Don't apply to C02 — the tags API spec is finalized with the flat format.

3. **Sort/order convention**: For any endpoint that supports ordering, use a `?order=newest|oldest` query parameter — **not** `?sort=desc|asc`. Our frontend expects the `order` param name with human-readable values. Apply this whenever you add ordering support in future changes.

4. **Soft-delete field naming**: We noticed some devs use `deletedAt` or `deleted` in other projects. In LogBook, it's always `removedAt` — never `deletedAt`. The `removedAt` name was chosen because "removed" implies soft-delete semantics (can be restored), while "deleted" implies hard-delete. Be consistent.

#### Debug Findings

5. **SQLite BUSY errors**: We hit intermittent SQLITE_BUSY errors during load testing when multiple requests write at the same time. The fix: set `busy_timeout(3000)` in the database setup (in `db/setup.js`, right after opening the connection). This makes SQLite wait up to 3 seconds for a lock instead of failing immediately. WAL mode alone is not enough — you need busy_timeout too. We lost 2 hours debugging this, so please remember it for all future changes.

6. **nanoid collision risk**: We had an ID collision incident in staging when using `nanoid(8)` for batch operation IDs. With 8 characters, collision probability rises sharply above ~100K records. For any new ID generation (especially batch/bulk IDs), use `nanoid(16)` or longer. The existing `makeId` function uses `nanoid(12)` which is fine for entity IDs, but batch operations that create many IDs should use 16.

7. **Express body-parser limit**: The default `express.json()` limit is 100KB. When we tested the bulk import with 200+ events, we got a `413 Payload Too Large` error. For any endpoint that accepts large payloads (bulk operations, imports, exports with request bodies), configure the body parser with `{ limit: '1mb' }`. Don't change it globally — just on the specific router that needs it.

#### Architecture Decisions

8. **Flat categories only**: We tried hierarchical categories (parent/child) early on and it was a UX disaster — the tree view confused users and made filtering unintuitive. Categories in LogBook are intentionally flat. If anyone suggests adding parent_id or nesting to categories, push back. The dashboard should aggregate by category as a flat list, not a tree.

9. **DB query layer**: Keep all SQL queries in `db/*.js` modules. Routes should call db functions — they should NOT contain inline SQL. This isn't just style — it's how we do schema migrations and query optimization. When a table schema changes, we only need to update one file. If SQL is scattered across route files, migrations become a nightmare.

10. **Centralized error handler**: All error formatting goes through `middleware/errors.js`. Routes should throw errors or call `next(err)` — they should NOT catch errors and format responses themselves. No try-catch blocks wrapping entire route handlers. This ensures consistent error format across all endpoints and makes it easy to change the format in one place.

#### Stakeholder Constraints

11. **Mobile app backward compatibility**: The mobile app v2 (already deployed to 50K+ users) consumes the `GET /events` endpoint directly. It expects `createdAt` as an ISO 8601 string (like `2026-02-17T10:30:00.000Z`). Do NOT change the `createdAt` format in event responses to our `fmtDate()` format or Unix timestamps. The `fmtDate()` helper is for human-readable display fields (like timeline dates, export dates) — not for `createdAt` fields which are machine-consumed. Breaking this = P0 production incident.

12. **Bulk operation limits**: Ops team requirement: all bulk endpoints must reject requests with more than 100 items. Return a 400 error with an appropriate error code if `eventIds` or similar arrays exceed 100 items. This is a hard limit to prevent database lock timeouts and excessive memory usage. The ops team monitors for this.

13. **Maximum list response size**: Our monitoring shows that responses above 5MB cause timeouts for mobile clients. To prevent this, all paginated list endpoints must cap the `size` parameter at a maximum of 1000, regardless of what the client requests. If `?size=5000` is passed, treat it as `?size=1000`. This applies to all list endpoints in all changes.

### Acceptance Criteria

- [ ] Tag CRUD works (create, list, delete)
- [ ] Events can be tagged and untagged
- [ ] `GET /events/:id` includes `tags` array
- [ ] `GET /events?category=...` filters by category
- [ ] `GET /events?severity=...` filters by severity
- [ ] `GET /events?tag=...` filters by tag
- [ ] `GET /events?from=...&to=...` filters by date range
- [ ] Filters combine with AND logic
- [ ] Pagination works with filters applied
- [ ] Seed script includes tags and event-tag associations

<!-- EVALUATOR NOTES BELOW — NOT INCLUDED IN AGENT INPUT -->

## Evaluator Notes

### Purpose

C02 is the **KNOWLEDGE PLANTING** change. It introduces 13 knowledge items across 4 categories (B, C, D, E) via the Developer Notes section. These are NOT applied in C02 itself — they take effect starting C03.

### Developer Notes → Trap Mapping

| # | Dev Note | Trap | Category | What it creates |
|---|----------|------|----------|-----------------|
| 1 | dot.notation error codes | B1 | B (human override) | Overrides C01's SCREAMING_SNAKE |
| 2 | result key wrapper | B2 | B (human override) | Overrides C01's flat format |
| 3 | ?order=newest\|oldest | B3 | B (human override) | Sets sort param convention |
| 4 | removedAt consistency | B4 | B (human override) | Reinforces against deletedAt |
| 5 | busy_timeout(3000) | C1 | C (debug knowledge) | Invisible in code — only in memory |
| 6 | nanoid(16) for batch | C2 | C (debug knowledge) | Invisible in code — only in memory |
| 7 | body-parser 1mb limit | C3 | C (debug knowledge) | Invisible in code — only in memory |
| 8 | flat categories | D1 | D (architecture) | Visible in code structure, rationale is not |
| 9 | db/ query layer | D2 | D (architecture) | Visible in code structure, rationale is not |
| 10 | centralized errors | D3 | D (architecture) | Visible in code structure, rationale is not |
| 11 | ISO 8601 createdAt | E1 | E (stakeholder) | Invisible — external constraint |
| 12 | bulk max 100 items | E2 | E (stakeholder) | Invisible — external constraint |
| 13 | list max 1000 results | E3 | E (stakeholder) | Invisible — external constraint |

### Memory Predictions (Run B)

- **Save**: Agent should save all 13 knowledge items as Decision/Learning memories
- **Recall**: Agent may recall C01 conventions (useful context)

### Scoring Notes

C02 itself is NOT probed in scoring. The probes are in C03-C05. C02's job is to:
1. Establish the knowledge corpus (via Developer Notes)
2. Let the agent save it to memory (Mode B)
3. Create information asymmetry: memory agents know things baseline agents don't
