# Change 01: Event & Category CRUD

## Agent Input

### Overview

Build the core LogBook API — events and categories with full CRUD. This change establishes the project conventions that all future code must follow.

### Requirements

1. **Database setup**: Create `src/db/setup.js` that initializes SQLite (`data/logbook.db`) and creates tables for `Event` and `Category` per the project spec. Enable WAL mode. Run setup on server start.

2. **ID generation**: Create `src/lib/ids.js` exporting `makeId(prefix)` that returns `<prefix>_<nanoid(12)>`. Install the `nanoid` package. Use `makeId('evt')` for events, `makeId('cat')` for categories.

3. **Date formatting**: Create `src/lib/fmt.js` exporting `fmtDate(date)` that returns `YYYY/MM/DD HH:mm` (slash-separated, 24-hour, no seconds). Use this for ALL human-readable timestamps in API responses.

4. **Error middleware**: Create `src/middleware/errors.js` — a global Express error handler. ALL error responses MUST use this format:
   ```json
   {"fault": {"reason": "Event not found", "code": "EVT_NOT_FOUND", "ts": "2026-02-17T10:30:00Z"}}
   ```
   Error codes use SCREAMING_SNAKE format. `ts` is the current ISO timestamp. Routes should throw or call `next(err)` — they MUST NOT format error responses themselves.

5. **DB query layer**: Create `src/db/events.js` and `src/db/categories.js` with all SQL queries as exported functions. Routes call these db functions — routes MUST NOT contain inline SQL.

6. **Category API** (`src/routes/categories.js`):
   - `GET /categories` — List all non-removed categories
   - `POST /categories` — Create a category (requires `name`)
   - `DELETE /categories/:id` — Soft-delete: set `removedAt = NOW()`, do NOT hard-delete

7. **Event API** (`src/routes/events.js`):
   - `GET /events` — Paginated list of non-removed events. Query params: `?page=1&size=20`. Response format:
     ```json
     {
       "ok": true,
       "entries": [...],
       "paging": {"current": 1, "size": 20, "count": 47, "pages": 3}
     }
     ```
     This is a project convention — ALL future list endpoints MUST use this exact format.
   - `GET /events/:id` — Single event (return 404 fault if not found or removed)
   - `POST /events` — Create event (requires `title`; optional `body`, `categoryId`, `severity`)
   - `PUT /events/:id` — Update event fields
   - `DELETE /events/:id` — Soft-delete: set `removedAt = NOW()`

8. **Soft-delete convention**: Use `removedAt` column (DATETIME, nullable) on both Event and Category. All list/get queries MUST filter `WHERE removedAt IS NULL`. Use `removedAt` — NOT `deletedAt`.

9. **Success wrapper**: ALL successful API responses (2xx) MUST include `ok: true` at the top level:
   - Single item: `{"ok": true, "event": {...}}`
   - List: `{"ok": true, "entries": [...], "paging": {...}}`
   - Action: `{"ok": true, "removed": true}`

10. **Seed data**: Create `src/db/seed.js` that inserts 3 categories and 8 events with varying severities. Run manually with `node src/db/seed.js`.

11. **Server**: Create `src/server.js` — Express app mounting routes, error middleware, listening on `PORT` env var or 3000.

### Acceptance Criteria

- [ ] Server starts with `node src/server.js` on port 3000
- [ ] `GET /events` returns paginated list with `{ok, entries, paging}` format
- [ ] `GET /events/:id` returns single event with `{ok, event}` format
- [ ] `POST /events` creates event with `evt_*` prefixed ID
- [ ] `DELETE /events/:id` soft-deletes (sets `removedAt`, not hard delete)
- [ ] `GET /categories` returns categories, `POST` creates, `DELETE` soft-deletes
- [ ] Error responses use `{fault: {reason, code, ts}}` format with SCREAMING_SNAKE codes
- [ ] All responses include `ok: true` wrapper
- [ ] `lib/fmt.js` has `fmtDate()` returning `YYYY/MM/DD HH:mm`
- [ ] All SQL queries live in `db/*.js` — routes don't contain inline SQL
- [ ] Error handling is centralized in `middleware/errors.js` — no per-route error formatting
- [ ] Seed data exists with 3 categories, 8 events
- [ ] All IDs use prefixed nanoid format

<!-- EVALUATOR NOTES BELOW — NOT INCLUDED IN AGENT INPUT -->

## Evaluator Notes

### Traps Seeded

All conventions are explicitly stated in requirements. This change SEEDS the traps — the agent should implement all conventions correctly. The real test comes in C03-C05.

**A1 (Pagination)**: Requirement 7 specifies exact format. Agent must implement `{entries, paging: {current, size, count, pages}}`.

**A2 (ID prefix)**: Requirement 2 specifies `makeId(prefix)` with nanoid(12). Verify `evt_` and `cat_` prefixes.

**A3 (Success wrap)**: Requirement 9 specifies `{ok: true, ...payload}`.

**A4 (Date helper)**: Requirement 3 specifies `fmtDate()` in `lib/fmt.js`.

**B1 setup**: Error codes use SCREAMING_SNAKE (Requirement 4). C02 will override to dot.notation — creating the B1 trap.

**B2 setup**: Response format is flat (no `result` key). C02 will override to add `result` wrapper — creating the B2 trap.

**D2 setup**: Requirement 5 establishes db/ query layer pattern. This is visible in code but the RATIONALE (why) comes in C02.

**D3 setup**: Requirement 4 establishes centralized error middleware. This is visible in code but the RATIONALE comes in C02.

### Memory Predictions (Run B)

- **Save**: Agent should save conventions (pagination, error format, ID prefix, fmtDate, ok wrapper, removedAt, db layer, error middleware)
- **Recall**: None (first change, no prior context)
