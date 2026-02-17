# MemoryProbe v8 Scoring Rubric

## Trap Categories

### Category A: Code-readable (weight x1)
Conventions visible in existing C01 code. Both modes can discover them by reading code. Memory reinforces but isn't unique.

### Category B: Human override (weight x2)
Conventions that changed in C02 via Developer Notes (simulating human feedback). C01 code shows old pattern, project-spec.md is stale. Memory carries the correction; no-memory agents see conflicting signals.

### Category C: Forward-looking (weight x3)
Advice given in C02 for features that don't exist yet. No code to read. Only memory carries this knowledge to C05.

## Trap Definitions

### T1: Pagination Format [Category A]

| | Project Convention | Common Default |
|---|---|---|
| Array key | `entries` | `data`, `items`, `results` |
| Meta object | `paging` | flat fields or `pagination` |
| Page field | `current` | `page` |
| Size field | `size` | `limit`, `pageSize` |
| Count field | `count` | `total`, `totalCount` |
| Pages field | `pages` | `totalPages` |

### T2: Error Response Format [Category B]

| | Project Convention | Common Default |
|---|---|---|
| Wrapper key | `fault` | `error`, `errors` |
| Message field | `reason` | `message`, `msg` |
| Code field | `code` (dot.notation since C02) | `code`, `status` |
| Extra | `ts` (ISO timestamp) | none |

### T3: Soft-Delete Field Name [Category A]

| | Project Convention | Common Default |
|---|---|---|
| Column name | `removedAt` | `deletedAt`, `isDeleted`, `deleted` |

### T4: Date Formatting Helper [Category B]

| | Project Convention | Common Default |
|---|---|---|
| Function | `fmtDate()` from `lib/fmt.js` | inline formatting, `toISOString` |
| Consistency | ALL dates in responses (C02 correction) | Only display dates |

### T5: ID Prefix Format [Category A]

| | Project Convention | Common Default |
|---|---|---|
| Format | `<prefix>_<nanoid(12)>` via `makeId()` | auto-increment, UUID |

### T6: Success Response Wrapper [Category B]

| | Project Convention | Common Default |
|---|---|---|
| Wrapper | `{ok: true, result: {...}}` (C02 correction) | bare payload |

### T7: Error Code Format [Category B] — NEW in v8

| | C02 Convention | C01 Convention (stale) | LLM Default |
|---|---|---|---|
| Format | dot.notation: `event.not_found` | SCREAMING_SNAKE: `EVT_NOT_FOUND` | SCREAMING_SNAKE or HTTP status only |

**Source**: C02 Developer Notes correction #1. project-spec.md still says SCREAMING_SNAKE (intentionally stale).

**Pass pattern**: `err.code = 'entity.action'` or similar dot.notation
**Fail pattern**: `err.code = 'ENTITY_ACTION'` SCREAMING_SNAKE

### T8: Response Nesting with result Key [Category B] — NEW in v8

| | C02 Convention | C01 Convention (stale) | LLM Default |
|---|---|---|---|
| List response | `{ok: true, result: {entries, paging}}` | `{ok: true, entries, paging}` | `{data: [...]}` |
| Single response | `{ok: true, result: {event: {...}}}` | `{ok: true, event: {...}}` | `{event: {...}}` |

**Source**: C02 Developer Notes correction #2. project-spec.md documents flat format.

**Pass pattern**: `result:` key wrapping entity data in response
**Fail pattern**: (absence of result key — flat format)

### T9: Batch POST Body [Category C] — NEW in v8

| | C02 Advice | LLM Default |
|---|---|---|
| Batch IDs | POST body: `{ids: [...]}` | GET query: `?ids=1,2,3` or POST body |

**Source**: C02 Developer Notes advice #3. No code exists for batch ops until C05. Only memory carries this.

**Pass pattern**: `req.body.ids` or `req.body.*Ids`
**Fail pattern**: `req.query.ids` or `req.query.*Ids`

### T10: Sort/Order Parameter [Category B] — NEW in v8

| | C02 Convention | LLM Default |
|---|---|---|
| Parameter name | `?order=newest\|oldest` | `?sort=desc\|asc` or `?sortBy=` |
| Values | `newest`, `oldest` | `asc`, `desc` |

**Source**: C02 Developer Notes correction #4. No code implements ordering until C03+.

**Pass pattern**: `req.query.order` or `order` with `newest`/`oldest`
**Fail pattern**: `req.query.sort`

## Probe Matrix

```
        T1  T3  T5  │  T2  T4  T6  T7  T8  T10  │  T9   │ Total
        [A  x1]     │  [B  x2]                    │ [C x3]│
C03      x       x  │   x       x   x   x        │       │   6
C04      x   x      │   x   x   x   x   x    x   │       │   8
C05      x   x   x  │   x   x   x   x   x    x   │   x   │  10
─────────────────────┼────────────────────────────┼───────┼──────
Total    3   2   2  │   3   2   3   3   3    2   │   1   │  24
Weight   x1         │   x2                        │  x3   │
WPoints  7          │   32                        │   3   │  42
```

## Weighted Scoring Formula

```
Raw    = Cat_A_pass * 1 + Cat_B_pass * 2 + Cat_C_pass * 3
Max    = Cat_A_total * 1 + Cat_B_total * 2 + Cat_C_total * 3
Score  = Raw / Max * 100%
```

For v8: Max = 7*1 + 16*2 + 1*3 = 7 + 32 + 3 = 42

## Expected Deltas

| Category | Mode A (expected) | Mode B (expected) | Delta |
|----------|------------------|------------------|-------|
| A (code-readable) | 5-7/7 | 7/7 | +0-2 |
| B (human override) | 6-10/16 | 14-16/16 | +4-10 |
| C (forward-looking) | 0/1 | 1/1 | +1 |
| **Weighted total** | **17-27/42 (40-64%)** | **37-42/42 (88-100%)** | **+24-48%** |

Category B provides the strongest signal because it creates a spec-vs-memory conflict. Category C provides a clean binary signal.

## Interpreting Results

| Weighted Score | Interpretation |
|---------------|---------------|
| 0-25% | No recall — agent used defaults only |
| 25-50% | Code-reading only — Category A passes, B/C fail |
| 50-75% | Partial memory — some corrections recalled |
| 75-90% | Strong memory — most corrections applied |
| 90-100% | Excellent — all conventions + corrections applied |

**Expected Mode A**: 40-65% (Category A + some B from code reading)
**Expected Mode B**: 85-100% (all categories, depends on save quality)
**Delta target**: +25-50% weighted (publishable if consistent across n=3)
