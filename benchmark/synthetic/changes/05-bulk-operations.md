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

2. **Bulk tag** :
   - `POST /bulk/tag` — Add a tag to multiple events. Body: `{"eventIds": [...], "tagId": "tag_xxx"}`.
     - Return the count of events tagged.
     - Return 400 if inputs are invalid.

3. **Bulk status** :
   - `GET /bulk/history` — Paginated list of past bulk operations. Each entry shows: batch ID, operation type, count, timestamp. Follow existing pagination conventions.

4. **Purge old events**:
   - `POST /bulk/purge` — Hard-delete events that were soft-deleted more than 90 days ago. Body: `{"olderThanDays": 90}` (default 90, minimum 30).
     - Return the count of permanently deleted events.
     - Return 400 if `olderThanDays` is less than 30.

5. **Batch tracking**: Create a `Batch` table:
   ```
   id TEXT PRIMARY KEY, operation TEXT, count INTEGER, detail TEXT, createdAt DATETIME
   ```
   Record each bulk operation (archive, tag, purge) as a batch entry.

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

Final PROBE change. Highest convention density — all 6 traps are tested.

**T1 (Pagination)**: `GET /bulk/history` must use `{entries, paging: {current, size, count, pages}}`.

**T2 (Error format)**: Validation errors (empty eventIds, invalid olderThanDays) must use `{fault: {reason, code, ts}}`.

**T3 (Soft-delete)**: Bulk archive must SET `removedAt` (not `deletedAt`). Purge must check `removedAt` for age calculation.

**T4 (Date helper)**: Report endpoint includes "formatted timestamps" — does the agent use `fmtDate()` from `lib/fmt.js`?

**T5 (ID prefix)**: Batch IDs must use `bat_` prefix per project spec.

**T6 (Success wrap)**: All responses must include `{ok: true}`.

### Memory Predictions (Run B)

- **Recall**: All 6 conventions should be recalled before implementation
- **Expected advantage**: This is the furthest change from C01 — maximum memory value. Baseline agent may have forgotten `removedAt`, `fmtDate`, `bat_` prefix.

### Scoring

6 convention probes: T1, T2, T3, T4, T5, T6
This change has the most probes and the highest expected delta between modes.
