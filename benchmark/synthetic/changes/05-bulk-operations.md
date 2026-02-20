# Change 05: Bulk Operations & Cleanup

## Agent Input

### Overview

Add bulk operations for efficient event management and a cleanup mechanism for old archived events. Follow all existing project conventions.

### Requirements

1. **Bulk archive** (`src/routes/bulk.js`):
   - `POST /bulk/archive` — Archive multiple events at once. Body: `{"eventIds": ["evt_xxx", ...]}`.
     - Soft-delete all specified events.
     - Return the count of archived events.
     - Return 400 if `eventIds` is empty or missing.
     - Return 409 if any event is already archived (do not archive any — atomic).
   - Each bulk operation gets a unique batch ID for tracking.

2. **Bulk tag**:
   - `POST /bulk/tag` — Add a tag to multiple events. Body: `{"eventIds": [...], "tagId": "tag_xxx"}`.
     - Return the count of events tagged.
     - Return 400 if inputs are invalid.

3. **Bulk status**:
   - `GET /bulk/history` — Paginated list of past bulk operations. Each entry shows: batch ID, operation type, count, timestamp. Follow existing pagination conventions.

4. **Purge old events**:
   - `POST /bulk/purge` — Hard-delete events that were soft-deleted more than 90 days ago. Body: `{"olderThanDays": 90}` (default 90, minimum 30).
     - Return the count of permanently deleted events.
     - Return 400 if `olderThanDays` is less than 30.

5. **Batch tracking**: Create a `Batch` table (see project spec). Record each bulk operation (archive, tag, purge) as a batch entry.

6. **Report endpoint**:
   - `GET /bulk/report` — Summary of bulk operations: total batches, events archived, events purged, events tagged. Include formatted timestamps for last operation of each type.

### Acceptance Criteria

- [ ] `POST /bulk/archive` soft-deletes multiple events atomically
- [ ] `POST /bulk/tag` tags multiple events
- [ ] `GET /bulk/history` returns paginated batch history
- [ ] `POST /bulk/purge` hard-deletes old soft-deleted events
- [ ] Batch tracking records all bulk operations
- [ ] `GET /bulk/report` returns summary with formatted timestamps
- [ ] Error responses follow existing format
- [ ] All endpoints follow existing project conventions

<!-- EVALUATOR NOTES BELOW — NOT INCLUDED IN AGENT INPUT -->

## Evaluator Notes

### Convention Probes

Final PROBE change. Highest convention density — tests all 5 categories.

**A1 (Pagination)**: `GET /bulk/history` must use `{entries, paging: {current, size, count, pages}}`.

**A2 (ID prefix)**: Batch IDs must use `bat_` prefix per project spec.

**A3 (Success wrap)**: All responses must include `{ok: true}`.

**B1 (Error codes)**: Validation errors must use dot.notation (e.g., `bulk.empty_ids`, `bulk.invalid_days`), not SCREAMING_SNAKE.

**B2 (Response nesting)**: All responses must use `result` wrapper.

**B4 (removedAt)**: Bulk archive must SET `removedAt` (not `deletedAt`). Purge must check `removedAt` for age calculation. The requirement says "soft-delete" but NOT which field. Does the agent use `removedAt` (C02 reinforcement) or default to `deletedAt`?

**C2 (nanoid length)**: Batch IDs must use nanoid(16) or longer (C02 debug finding about collision risk). The standard `makeId` uses nanoid(12) for entity IDs, but batch IDs should be longer. Does the agent create a `makeId('bat', 16)` variant or just use the default?

**C3 (body-parser limit)**: Bulk endpoints receive large payloads. The test sends a ~500KB JSON body. Without the `{ limit: '1mb' }` configuration on the bulk router, Express returns 413. Does the agent configure this?

**D2 (DB query layer)**: Does the agent create `db/bulk.js` for SQL queries? Or inline SQL in routes?

**E2 (Bulk limit)**: Bulk endpoints must reject >100 items. The test sends 150 eventIds and expects 400 with `bulk.limit_exceeded` error code. This is a stakeholder constraint — not documented anywhere except C02 Developer Notes.

**E3 (Max results)**: `GET /bulk/history?size=2000` must return at most 1000 entries. The test requests size=2000 and verifies the response has ≤1000 entries.

### Memory Predictions (Run B)

- **Recall**: All conventions + C2 (nanoid(16)), C3 (body-parser limit), E2 (100 item cap), E3 (1000 max results)
- **Expected advantage**: This is the furthest change from C01 — maximum memory value. C2, C3, E2, E3 are all impossible to derive from code. Baseline agents will use default nanoid(12), default body-parser (100kb), no item limits, and no max results cap.

### Scoring

13 probes: A1, A2, A3, B1, B2, B4, C2, C3, D2, E2, E3

This change has the most probes and the highest expected delta between modes. Categories C and E together account for 4 probes × x3 weight = 12 weighted points — more than all of C03's probes combined.
