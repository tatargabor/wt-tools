# MemoryProbe v9 Scoring Rubric

## Design Principles

1. **Convention probes are NOT in test scripts.** Test scripts (run during agent sessions) contain only functional checks. Convention probes live in `score.sh` and run post-hoc on source code. This prevents the agent from learning conventions from test failure messages.

2. **C02 corrections say "starting C03".** Developer Notes corrections are explicitly deferred to future changes. C02 code uses OLD conventions (SCREAMING_SNAKE, flat format). Only memory carries corrections to C03+.

3. **Category B/C traps are memory-unique.** The knowledge exists only in C02 Developer Notes → memory. It is NOT visible in any code or spec file that C03-C05 agents read.

## Trap Categories

### Category A: Code-readable (weight x1)
Conventions visible in existing C01 code. Both modes can discover them by reading code. Memory reinforces but isn't unique.

### Category B: Human override (weight x2)
Conventions reinforced in C02 but already present in C01 code. The C02 Developer Notes add nuance (e.g., "ALL dates" not just display dates) but the base convention is code-readable.

### Category C: Forward-looking (weight x3)
Corrections from C02 Developer Notes for features that don't exist yet OR that override established code patterns. No code shows the corrected convention. Only memory carries this knowledge to C03-C05.

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

### T2: Error Response Format [Category A]

| | Project Convention | Common Default |
|---|---|---|
| Wrapper key | `fault` | `error`, `errors` |
| Message field | `reason` | `message`, `msg` |
| Code field | `code` | `code`, `status` |
| Extra | `ts` (ISO timestamp) | none |

### T3: Soft-Delete Field Name [Category A]

| | Project Convention | Common Default |
|---|---|---|
| Column name | `removedAt` | `deletedAt`, `isDeleted`, `deleted` |

### T4: Date Formatting Helper [Category B]

| | Project Convention | Common Default |
|---|---|---|
| Function | `fmtDate()` from `lib/fmt.js` | inline formatting, `toISOString` |
| Scope | ALL dates in responses (C02 correction) | Only display dates |

### T5: ID Prefix Format [Category A]

| | Project Convention | Common Default |
|---|---|---|
| Format | `<prefix>_<nanoid(12)>` via `makeId()` | auto-increment, UUID |

### T6: Success Response Wrapper [Category A]

| | Project Convention | Common Default |
|---|---|---|
| Wrapper | `{ok: true, ...payload}` | bare payload |

### T7: Error Code Format [Category C]

| | C02 Correction (C03+) | C01/C02 Code | LLM Default |
|---|---|---|---|
| Format | dot.notation: `event.not_found` | SCREAMING_SNAKE: `EVT_NOT_FOUND` | SCREAMING_SNAKE or HTTP status only |

**Source**: C02 Developer Notes correction #1. Says "starting C03". C02 code still uses SCREAMING_SNAKE. project-spec.md says SCREAMING_SNAKE.

**Pass pattern**: `err.code = 'entity.action'` or similar dot.notation
**Fail pattern**: `err.code = 'ENTITY_ACTION'` SCREAMING_SNAKE

### T8: Response Nesting with result Key [Category C]

| | C02 Correction (C03+) | C01/C02 Code | LLM Default |
|---|---|---|---|
| List response | `{ok: true, result: {entries, paging}}` | `{ok: true, entries, paging}` | `{data: [...]}` |
| Single response | `{ok: true, result: {event: {...}}}` | `{ok: true, event: {...}}` | `{event: {...}}` |

**Source**: C02 Developer Notes correction #2. Says "starting C03". C02 code uses flat format.

**Pass pattern**: `result:` key wrapping entity data in response
**Fail pattern**: (absence of result key — flat format)

### T9: Batch POST Body [Category C]

| | C02 Advice | LLM Default |
|---|---|---|
| Batch IDs | POST body: `{ids: [...]}` | GET query: `?ids=1,2,3` or POST body |

**Source**: C02 Developer Notes advice #3. No code exists for batch ops until C05.

**Pass pattern**: `req.body` access in bulk routes (dot or destructuring)
**Fail pattern**: `req.query.ids` or `req.query.*Ids`

### T10: Sort/Order Parameter [Category C]

| | C02 Convention (C03+) | LLM Default |
|---|---|---|
| Parameter name | `?order=newest\|oldest` | `?sort=desc\|asc` or `?sortBy=` |
| Values | `newest`, `oldest` | `asc`, `desc` |

**Source**: C02 Developer Notes correction #4. No code implements ordering until C04+.

**Pass pattern**: `req.query.order` or `order` with `newest`/`oldest`
**Fail pattern**: `req.query.sort`

## Probe Matrix

```
        T1  T2  T3  T5  T6  │  T4  │  T7  T8  T9  T10  │ Total
        [A  x1]              │[B x2]│  [C  x3]           │
C03      x   x       x   x  │      │   x   x            │   6
C04      x   x   x       x  │  x   │   x   x        x   │   8
C05      x   x   x   x   x  │  x   │   x   x    x   x   │  10
─────────────────────────────┼──────┼─────────────────────┼──────
Total    3   3   2   2   3  │  2   │   3   3    1    2   │  24
Weight   x1                 │  x2  │   x3                │
WPoints  13                 │   4  │   27                │  44
```

## Weighted Scoring Formula

```
Raw    = Cat_A_pass * 1 + Cat_B_pass * 2 + Cat_C_pass * 3
Max    = Cat_A_total * 1 + Cat_B_total * 2 + Cat_C_total * 3
Score  = Raw / Max * 100%
```

For v9: Max = 13*1 + 2*2 + 9*3 = 13 + 4 + 27 = 44

## Expected Deltas

| Category | Mode A (expected) | Mode B (expected) | Delta |
|----------|------------------|------------------|-------|
| A (code-readable) | 10-13/13 | 13/13 | +0-3 |
| B (date helper scope) | 0-2/2 | 2/2 | +0-2 |
| C (memory-only) | 0-3/9 | 7-9/9 | +4-9 |
| **Weighted total** | **10-22/44 (23-50%)** | **38-44/44 (86-100%)** | **+36-64%** |

Category C provides the strongest signal because the knowledge is ONLY in memory. No code shows dot.notation, result key, or order parameter before C03.

## Interpreting Results

| Weighted Score | Interpretation |
|---------------|---------------|
| 0-25% | No recall — agent used defaults only |
| 25-50% | Code-reading only — Category A passes, C fail |
| 50-75% | Partial memory — some corrections recalled |
| 75-90% | Strong memory — most corrections applied |
| 90-100% | Excellent — all conventions + corrections applied |

**Expected Mode A**: 20-46% (Category A + some B from code reading)
**Expected Mode B**: 85-100% (all categories, depends on save quality)
**Delta target**: +40-65% weighted (publishable if consistent across n=3)

## Key Design Change from v8

In v8 (SYN-02), C02 corrections said "apply in this change and all future changes." This caused the corrections to be baked into C02 code, making them readable by C03-C05 agents even without memory. Result: 0% delta.

In v9 (SYN-03), C02 corrections say "starting C03, don't apply to C02." C02 code keeps OLD conventions. Only memory carries corrections forward.

Additionally, convention probes were removed from test scripts to prevent the agent from learning conventions from test failure messages.
