# MemoryProbe Scoring Rubric

## Trap Definitions

### T1: Pagination Format

| | Project Convention | Common Default |
|---|---|---|
| Array key | `entries` | `data`, `items`, `results` |
| Meta object | `paging` | flat fields or `pagination` |
| Page field | `current` | `page` |
| Size field | `size` | `limit`, `pageSize` |
| Count field | `count` | `total`, `totalCount` |
| Pages field | `pages` | `totalPages` |

**Pass pattern**: `"paging"` AND `"entries"` in response handler
**Fail pattern**: `"total"` or `"limit"` as response keys (not query params)

### T2: Error Response Format

| | Project Convention | Common Default |
|---|---|---|
| Wrapper key | `fault` | `error`, `errors` |
| Message field | `reason` | `message`, `msg` |
| Code field | `code` (SCREAMING_SNAKE) | `code`, `status` |
| Extra | `ts` (ISO timestamp) | none |

**Pass pattern**: `"fault"` AND `"reason"` in error handlers
**Fail pattern**: `"error"` or `"message"` as error response keys

### T3: Soft-Delete Field Name

| | Project Convention | Common Default |
|---|---|---|
| Column name | `removedAt` | `deletedAt`, `isDeleted`, `deleted` |
| Type | DATETIME, nullable | varies |
| Filter | `WHERE removedAt IS NULL` | `WHERE deletedAt IS NULL` |

**Pass pattern**: `removedAt` in queries/schema
**Fail pattern**: `deletedAt`, `isDeleted`, `is_deleted`

### T4: Date Formatting Helper

| | Project Convention | Common Default |
|---|---|---|
| Function | `fmtDate()` | `formatDate()`, inline formatting |
| Location | `lib/fmt.js` | various |
| Format | `YYYY/MM/DD HH:mm` | ISO 8601, locale-dependent |

**Pass pattern**: `fmtDate` import or usage
**Fail pattern**: `toISOString`, `formatDate`, `dayjs`, `moment`

### T5: ID Prefix Format

| | Project Convention | Common Default |
|---|---|---|
| Format | `<prefix>_<nanoid(12)>` | auto-increment, UUID |
| Events | `evt_` | plain ID |
| Comments | `cmt_` | plain ID |
| Batches | `bat_` | plain ID |

**Pass pattern**: Entity-specific prefix (e.g., `cmt_`, `bat_`)
**Fail pattern**: `AUTO_INCREMENT`, `autoincrement`, `uuid()`

### T6: Success Response Wrapper

| | Project Convention | Common Default |
|---|---|---|
| Wrapper | `{ok: true, ...payload}` | bare payload |
| On list | `{ok: true, entries: [...], paging: {...}}` | `{data: [...], total: N}` |
| On action | `{ok: true, archived: 5}` | `{success: true}` or bare |

**Pass pattern**: `"ok"` in response objects
**Fail pattern**: (absence of `ok` — harder to detect, checked via test scripts)

## Probe Matrix

```
        T1   T2   T3   T4   T5   T6   Total
C03      x    x              x    x    4
C04      x    x    x    x         x    5
C05      x    x    x    x    x    x    6
────────────────────────────────────────
Total    3    3    2    2    2    3    15
```

## Expected Deltas

| Trap | Mode A | Mode B | Delta | Signal |
|------|--------|--------|-------|--------|
| T1 Pagination | ~1/3 | ~3/3 | +2 | High |
| T2 Errors | ~0/3 | ~3/3 | +3 | Very high |
| T3 Soft-delete | ~0/2 | ~2/2 | +2 | Very high |
| T4 Date helper | ~0/2 | ~2/2 | +2 | High |
| T5 ID prefix | ~1/2 | ~2/2 | +1 | Medium |
| T6 Ok wrapper | ~1/3 | ~3/3 | +2 | High |
| **Total** | **~3/15** | **~15/15** | **+12** | |
| **Percent** | **~20%** | **~100%** | **+80%** | |

T2 (fault) and T3 (removedAt) are the highest-signal traps — no agent would naturally use these non-standard terms.

## Interpreting Results

| Score Range | Interpretation |
|-------------|---------------|
| 0-20% | No convention recall — agent used defaults |
| 20-40% | Partial recall — found some by reading code |
| 40-70% | Good recall — memory working but inconsistent |
| 70-90% | Strong recall — memory effective |
| 90-100% | Excellent recall — conventions consistently applied |

**Expected Mode A**: 0-35% (some conventions discoverable via code reading)
**Expected Mode B**: 70-100% (depends on save quality)
**Expected Mode C**: 85-100% (pre-seeded = perfect save quality)

**If Mode B < Mode A**: Memory is adding noise or false confidence. Investigate save quality.
**If Mode C >> Mode B**: Save quality is the bottleneck, not recall. Improve memory hooks.
**If Mode C ~ Mode A**: Recall mechanism is broken. Check `wt-memory recall` behavior.
