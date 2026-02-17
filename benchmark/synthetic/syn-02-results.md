# SYN-02 Results — MemoryProbe Synthetic Benchmark (10 traps, weighted scoring)

**Date**: 2026-02-17
**Benchmark**: MemoryProbe v8 (LogBook API) — 5 sequential changes, 10 convention traps, 3 weighted categories
**Setup**: Claude Code (Opus 4.6), `--max-turns 25`, separate session per change
**Runtime**: ~10 minutes per mode (5 sessions total)

## Weighted Convention Scoring

```
Category A (Code-readable, weight x1):
                 Mode A    Mode B   Delta
  T1   paging     3/ 3      3/ 3     0
  T3   remove     2/ 2      2/ 2     0
  T5   IDs        2/ 2      2/ 2     0
  Subtotal       7/ 7      7/ 7     0

Category B (Human override, weight x2):
                 Mode A    Mode B   Delta
  T2   errors     3/ 3      3/ 3     0
  T4   dates      2/ 2      2/ 2     0
  T6   ok wrap    3/ 3      3/ 3     0
  T7   err.code   3/ 3      3/ 3     0
  T8   result-key 2/ 3      2/ 3     0
  T10  order      1/ 2      1/ 2     0
  Subtotal       14/16      14/16     0

Category C (Forward-looking, weight x3):
                 Mode A    Mode B   Delta
  T9   batch-POST 0/ 1      0/ 1     0
  Subtotal       0/ 1      0/ 1     0

──────────────────────────────────────────
Weighted Score:
  Mode A:  35/42 (83%)
  Mode B:  35/42 (83%)
  Delta:   0%

Unweighted:  21/24 vs 21/24
```

## Test Results (API-level, curl-based)

| Change | Role | Mode A | Mode B |
|--------|------|--------|--------|
| C01 Event CRUD | SEED | (terminated) | (terminated) |
| C02 Tags & Filtering | CORRECT | 6/8 | 6/8 |
| C03 Comments & Activity | PROBE | 12/12 | 3/12 |
| C04 Dashboard & Export | PROBE | 16/17 | 4/17 |
| C05 Bulk Operations | PROBE | 4/16 | 15/16 |

Note: Several sessions showed "Terminated" / "0 bytes output" — sessions were killed before completion. Mode A happened to succeed on C03-C04 while Mode B succeeded on C05, introducing noise.

## Delta: Zero

**No measurable difference between Mode A and Mode B.** Both modes achieve identical convention probe scores across all 10 traps and all 3 categories.

## Root Cause Analysis

### Problem 1: Code persistence acts as alternative memory channel

The core v8 design assumed Category B ("human override") traps would differentiate because C02 Developer Notes corrections override C01 patterns. The theory: only memory carries the correction to C03-C05.

**What actually happens:**

```
C02 Developer Notes → Agent applies correction in C02 code → Code persists in git
                                                                    ↓
C03-C05 agents read existing code (including C02's) → See correction in code → Follow it
```

Specific examples:
- **T7** (dot.notation): C02 tags.js has `err.code = 'tag.not_found'` → C03 reads it, copies pattern
- **T8** (result key): C02 tags.js has `{ ok: true, result: { tag } }` → C03+ copies pattern
- **T10** (order param): C04 dashboard.js used `req.query.order` in both modes

The codebase itself becomes a "memory" — conventions baked into code are readable by any agent that reads existing code before implementing.

### Problem 2: T9 grep pattern bug

The T9 probe (Category C, forward-looking) was the one trap designed to avoid the code-persistence problem. It failed due to a grep pattern mismatch:

```javascript
// What the code does (JS destructuring):
const { eventIds } = req.body;

// What the grep pattern looks for (dot access):
req.body.eventIds
// or: req.body.\w*[Ii]ds
```

The pattern `req\.body\.\w*[Ii]ds` never matches destructured access patterns.

### Problem 3: C05 change file removes T9 ambiguity

Even if the grep pattern worked, T9 wouldn't differentiate because the C05 change file (`05-bulk-operations.md`) explicitly specifies `POST /bulk/archive` — making `req.body` the natural choice for any agent, with or without memory.

### Problem 4: Session instability

Multiple sessions showed "Terminated" with 0 bytes output, indicating the Claude process was killed before completion. This introduced noise in functional test results (Mode A succeeded on different changes than Mode B).

## Lessons for SYN-03

### What works
- Automated grep-based scoring is fast and reproducible
- The 5-session sequential structure is sound
- Category A (code-readable) traps correctly show tie (7/7 both)
- The weight system (x1/x2/x3) is a good framework

### What must change

1. **Corrections must NOT be implemented in C02.** Developer Notes should contain ONLY forward-looking advice for features that don't exist yet (Category C). If a correction is applied in C02 code, it becomes code-readable in C03+ and memory adds no value.

2. **More Category C traps needed.** Currently only T9 is Category C. Need 4-6 forward-looking traps where the knowledge exists only in memory (or in the Developer Notes of a past session that future sessions don't re-read).

3. **Fix grep patterns for JS idioms.** Patterns must handle:
   - Destructuring: `const { ids } = req.body`
   - Shorthand: `{ result: data }`
   - Template literals and various quoting styles

4. **Change files must be ambiguous where traps live.** If C05 says "POST /bulk/archive", both modes will use POST. The change file should say "provide bulk archive capability" and let the agent choose GET vs POST.

5. **Session stability.** Investigate why sessions terminate with 0 bytes. Consider increasing `--max-turns` or adding retry logic.

### Redesign principle

> The ONLY knowledge that differentiates memory from no-memory is knowledge that:
> (a) was shared in a PAST session,
> (b) is NOT visible in any code or spec file, and
> (c) is relevant to a FUTURE implementation decision.
>
> If the agent can derive the answer by reading existing code, memory adds no value.

## Comparison: SYN-01 vs SYN-02

| Metric | SYN-01 (6 traps) | SYN-02 (10 traps) |
|--------|------------------|-------------------|
| Convention delta | +20% (B wins) | 0% (tie) |
| Functional delta | +47% (B wins) | Noisy (session kills) |
| Traps | 6 (T1-T6, flat) | 10 (T1-T10, weighted) |
| Key insight | project-spec redundancy | code-persistence channel |
| Reliability | Medium (n=1) | Low (session instability) |

SYN-01 showed a delta partly because Mode A's sessions failed functionally (C04/C05 didn't work), inflating the apparent benefit of memory. SYN-02's convention-only scoring removes that confound and reveals zero actual convention delta.
