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
   Error codes use SCREAMING_SNAKE format. `ts` is the current ISO timestamp.

5. **Category API** (`src/routes/categories.js`):
   - `GET /categories` — List all non-removed categories
   - `POST /categories` — Create a category (requires `name`)
   - `DELETE /categories/:id` — Soft-delete: set `removedAt = NOW()`, do NOT hard-delete

6. **Event API** (`src/routes/events.js`):
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

7. **Soft-delete convention**: Use `removedAt` column (DATETIME, nullable) on both Event and Category. All list/get queries MUST filter `WHERE removedAt IS NULL`. Use `removedAt` — NOT `deletedAt`.

8. **Success wrapper**: ALL successful API responses (2xx) MUST include `ok: true` at the top level:
   - Single item: `{"ok": true, "event": {...}}`
   - List: `{"ok": true, "entries": [...], "paging": {...}}`
   - Action: `{"ok": true, "removed": true}`

9. **Seed data**: Create `src/db/seed.js` that inserts 3 categories and 8 events with varying severities. Run manually with `node src/db/seed.js`.

10. **Server**: Create `src/server.js` — Express app mounting routes, error middleware, listening on `PORT` env var or 3000.

### Acceptance Criteria

- [ ] Server starts with `node src/server.js` on port 3000
- [ ] `GET /events` returns paginated list with `{ok, entries, paging}` format
- [ ] `GET /events/:id` returns single event with `{ok, event}` format
- [ ] `POST /events` creates event with `evt_*` prefixed ID
- [ ] `DELETE /events/:id` soft-deletes (sets `removedAt`, not hard delete)
- [ ] `GET /categories` returns categories, `POST` creates, `DELETE` soft-deletes
- [ ] Error responses use `{fault: {reason, code, ts}}` format
- [ ] All responses include `ok: true` wrapper
- [ ] `lib/fmt.js` has `fmtDate()` returning `YYYY/MM/DD HH:mm`
- [ ] Seed data exists with 3 categories, 8 events
- [ ] All IDs use prefixed nanoid format

<!-- EVALUATOR NOTES BELOW — NOT INCLUDED IN AGENT INPUT -->

## Evaluator Notes

### Traps Seeded

All 6 project conventions are explicitly stated in requirements. This change SEEDS the traps — the agent should implement all conventions correctly. The real test comes in C03-C05 (probe changes) where conventions must be recalled.

**T1 (Pagination)**: Requirement 6 specifies exact format. Agent must implement `{entries, paging: {current, size, count, pages}}`. Verify this is NOT `{data, total, page, limit}`.

**T2 (Error format)**: Requirement 4 specifies `{fault: {reason, code, ts}}`. Verify NOT `{error: string}` or `{message, code}`.

**T3 (Soft-delete)**: Requirement 7 explicitly says `removedAt` — NOT `deletedAt`. Verify column name in schema and queries.

**T4 (Date helper)**: Requirement 3 specifies `fmtDate()` in `lib/fmt.js`. Verify function exists and returns slash-separated format.

**T5 (ID prefix)**: Requirement 2 specifies `makeId(prefix)` with nanoid. Verify `evt_` and `cat_` prefixes in use.

**T6 (Success wrap)**: Requirement 8 specifies `{ok: true, ...payload}`. Verify ALL responses include it.

### Memory Predictions (Run B)

- **Save**: Agent should save all 6 conventions as Decision memories
- **Save**: Any environment quirks encountered (SQLite WAL, nanoid import)
- **Recall**: None (first change, no prior context)

### Scoring Focus

- Did agent implement all 6 conventions correctly? (Baseline for probes)
- Did agent save conventions to memory? (Run B only — count and quality)
