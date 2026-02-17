# Trap Design

## Overview

Six non-standard project conventions, each seeded in C01 and probed in C03-C05. Every convention is chosen to be:
- **Unique**: No LLM would generate it from training data alone
- **Grepable**: Detectable with a simple pattern match
- **Meaningful**: A real project choice, not arbitrary nonsense

## Trap Matrix

| Trap | Seeded | Probed | Probe Count |
|------|--------|--------|-------------|
| T1: Pagination | C01 (GET /events) | C03 (GET /comments), C04 (GET /stats), C05 (GET /bulk) | 3 |
| T2: Error format | C01 (validation errors) | C03 (comment errors), C04 (export errors), C05 (bulk errors) | 3 |
| T3: Soft-delete | C01 (event archive) | C04 (notification cleanup), C05 (bulk archive) | 2 |
| T4: Date helper | C01 (event timestamps) | C04 (export dates), C05 (bulk report dates) | 2 |
| T5: ID prefix | C01 (evt_, cat_) | C03 (cmt_), C05 (batch IDs: bat_) | 2 |
| T6: Success wrap | C01 (all responses) | C03, C04, C05 (all new endpoints) | 3 |
| **Total** | | | **15** |

## T1: Pagination Format

### Convention
All list endpoints return:
```json
{
  "entries": [...],
  "paging": {
    "current": 1,
    "size": 20,
    "count": 157,
    "pages": 8
  }
}
```

Query parameters: `?page=1&size=20`

### Why This Is Non-Standard
Common patterns:
- `{data: [...], total: N, page: N, limit: N}` — most REST APIs
- `{items: [...], pagination: {page, pageSize, total}}` — some frameworks
- `{results: [...], count: N, next: URL}` — Django REST

Our pattern uses `entries` (not `data`/`items`/`results`), nested `paging` object (not flat), and `size`/`count`/`pages` (not `limit`/`total`/`totalPages`).

### Grep Detection
```bash
# PASS: project convention
grep -c '"paging"' "$file" && grep -c '"entries"' "$file"

# FAIL: standard patterns
grep -c '"data".*\[' "$file"       # data array
grep -c '"total"' "$file"          # flat total
grep -c '"limit"' "$file"          # limit parameter
```

### C01 Seed
C01 requirements explicitly specify:
> "All list endpoints MUST return: `{entries: [...], paging: {current, size, count, pages}}`. Query params: `?page=1&size=20`. This is a project convention."

### Probe Points
- **C03**: `GET /events/:id/comments` — paginated comment list
- **C04**: `GET /dashboard/recent` — paginated recent activity
- **C05**: `GET /events/bulk/status` — paginated bulk operation results

## T2: Error Response Format

### Convention
All error responses return:
```json
{
  "fault": {
    "reason": "Event not found",
    "code": "EVT_NOT_FOUND",
    "ts": "2026-02-17T10:30:00Z"
  }
}
```

### Why This Is Non-Standard
Common patterns:
- `{error: "message"}` — Express default
- `{message: "...", code: "..."}` — many APIs
- `{errors: [{field, message}]}` — validation

Our pattern nests under `fault` (not `error`), uses `reason` (not `message`), and includes `ts` timestamp.

### Grep Detection
```bash
# PASS
grep -c '"fault"' "$file" && grep -c '"reason"' "$file"

# FAIL
grep -c '"error"' "$file"          # standard error key
grep -c '"message"' "$file"        # standard message key (in error context)
```

### C01 Seed
> "All error responses MUST use: `{fault: {reason: string, code: string, ts: string}}`. Error codes use SCREAMING_SNAKE format. Include ISO timestamp in `ts`."

### Probe Points
- **C03**: 404 on missing comment, 400 on invalid comment body
- **C04**: 400 on invalid date range, 404 on missing export
- **C05**: 400 on empty bulk selection, 409 on already-archived events

## T3: Soft-Delete Field

### Convention
Soft-deleted records use `removedAt` (DATETIME, nullable) column. Queries filter `WHERE removedAt IS NULL`.

### Why This Is Non-Standard
Common patterns:
- `deletedAt` — Prisma, Laravel, Rails
- `isDeleted` — boolean flag
- `deleted` — boolean flag

`removedAt` is uncommon. Most developers and LLMs default to `deletedAt`.

### Grep Detection
```bash
# PASS
grep -c 'removedAt' "$file"

# FAIL
grep -c 'deletedAt\|isDeleted\|is_deleted' "$file"
```

### C01 Seed
> "Soft-delete: add `removedAt` (DATETIME, nullable) column. Filter all queries with `WHERE removedAt IS NULL`. Use `removedAt` — NOT `deletedAt`."

### Probe Points
- **C04**: Notification dismiss uses `removedAt` (not hard delete)
- **C05**: Bulk archive sets `removedAt`, bulk purge hard-deletes where `removedAt < 90 days ago`

## T4: Date Helper Function

### Convention
All human-readable dates use `fmtDate(date)` from `lib/fmt.js`:
```js
// lib/fmt.js
function fmtDate(date) {
  const d = new Date(date);
  const Y = d.getFullYear();
  const M = String(d.getMonth() + 1).padStart(2, '0');
  const D = String(d.getDate()).padStart(2, '0');
  const h = String(d.getHours()).padStart(2, '0');
  const m = String(d.getMinutes()).padStart(2, '0');
  return `${Y}/${M}/${D} ${h}:${m}`;
}
```

Output: `2026/02/17 14:30` (slash-separated, 24h, no seconds)

### Why This Is Non-Standard
Common patterns:
- `new Date().toISOString()` — ISO 8601
- `date.toLocaleDateString()` — locale-dependent
- `dayjs(date).format('YYYY-MM-DD')` — dash-separated
- Custom formatters usually named `formatDate`, `formatTimestamp`

Our function is named `fmtDate` (abbreviated), uses slash separators, and lives in `lib/fmt.js`.

### Grep Detection
```bash
# PASS
grep -c "fmtDate\|require.*fmt\|from.*fmt" "$file"

# FAIL
grep -c 'toISOString\|toLocaleDateString\|formatDate\|dayjs\|moment' "$file"
```

### C01 Seed
> "Create `lib/fmt.js` with `fmtDate(date)` — returns `YYYY/MM/DD HH:mm` (slash-separated, 24h, no seconds). Use this for ALL human-readable timestamps in API responses."

### Probe Points
- **C04**: CSV export uses `fmtDate()` for event timestamps
- **C05**: Bulk operation report includes formatted timestamps via `fmtDate()`

## T5: ID Prefix Format

### Convention
All entity IDs use the format `<prefix>_<nanoid(12)>`:
- Events: `evt_a1b2c3d4e5f6`
- Categories: `cat_x7y8z9w0v1u2`
- Comments: `cmt_<nanoid>`
- Tags: `tag_<nanoid>`
- Batches: `bat_<nanoid>`

Generated at insert time using `nanoid` package.

### Why This Is Non-Standard
Common patterns:
- Auto-increment integers (`1, 2, 3...`)
- Plain UUIDs (`550e8400-e29b-41d4-a716-446655440000`)
- CUID/ULID (no prefix)

Prefixed IDs (like Stripe's `cus_`, `pi_`) are known but the specific prefixes and nanoid combination are project-specific.

### Grep Detection
```bash
# PASS (in ID generation code)
grep -c "evt_\|cat_\|cmt_\|tag_\|bat_" "$file"
grep -c 'nanoid' "$file"

# FAIL
grep -c 'uuid\|UUID\|AUTO_INCREMENT\|autoincrement\|SERIAL' "$file"
```

### C01 Seed
> "All entity IDs use prefixed nanoid: `evt_<nanoid(12)>` for events, `cat_<nanoid(12)>` for categories. Install `nanoid` package. Generate at insert time."

### Probe Points
- **C03**: Comment IDs use `cmt_<nanoid>`
- **C05**: Batch operation IDs use `bat_<nanoid>`

## T6: Success Response Wrapper

### Convention
All successful responses wrap payload in `{ok: true, ...payload}`:
```json
// Single item
{"ok": true, "event": {...}}

// List (combined with T1 pagination)
{"ok": true, "entries": [...], "paging": {...}}

// Action result
{"ok": true, "archived": 5}
```

### Why This Is Non-Standard
Common patterns:
- Bare payload: `{id: 1, name: "..."}` — most REST APIs
- `{success: true, data: {...}}` — some APIs
- `{status: "ok", result: {...}}` — RPC-style

Our pattern uses `ok: true` spread into the response (not nested under `data`).

### Grep Detection
```bash
# PASS
grep -c '"ok".*true\|ok: true\|{ok:' "$file"

# FAIL (if ok is absent from responses)
grep -c 'res.json({' "$file"  # Count total responses
# Then check: does EVERY res.json include ok?
```

### C01 Seed
> "ALL successful responses MUST include `ok: true` at the top level: `{ok: true, ...payload}`. This applies to every endpoint — CRUD, list, action results."

### Probe Points
- **C03**: Comment CRUD responses include `ok: true`
- **C04**: Dashboard and export responses include `ok: true`
- **C05**: Bulk operation responses include `ok: true`

## Expected Results

### Per-Trap Expected Delta

| Trap | Mode A (baseline) | Mode B (memory) | Mode C (pre-seeded) |
|------|-------------------|-----------------|---------------------|
| T1 Pagination | ~30% pass | ~90% pass | ~95% pass |
| T2 Errors | ~10% pass | ~85% pass | ~90% pass |
| T3 Soft-delete | ~20% pass | ~80% pass | ~85% pass |
| T4 Date helper | ~15% pass | ~75% pass | ~80% pass |
| T5 ID prefix | ~25% pass | ~85% pass | ~90% pass |
| T6 Success wrap | ~20% pass | ~80% pass | ~85% pass |
| **Aggregate** | **~20% (3/15)** | **~83% (12-13/15)** | **~88% (13-14/15)** |

**Why Mode A won't be 0%**: Agents may discover conventions by reading existing C01 code. Some agents are thorough and grep before implementing. But they won't find ALL 6 conventions consistently.

**Why Mode B won't be 100%**: Memory save quality varies. Agent may not save all conventions, or recall may return irrelevant results. Also, agent may recall but not apply correctly.

**Why Mode C should be highest**: Pre-seeded memories are perfectly written — no save quality variance. Tests pure recall effectiveness.
