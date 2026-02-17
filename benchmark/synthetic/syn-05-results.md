# SYN-05 Results (MemoryProbe v9 + post-session extraction)

**Date**: 2026-02-17
**Benchmark**: MemoryProbe v9
**Model**: Claude Opus 4.6
**Run mode**: Sequential (concurrent runs cause Claude CLI failures)

## Scores

```
MemoryProbe v9 Comparison
==================================================

Category A (Code-readable, weight x1):
                 Mode A    Mode B   Delta
  T1   paging     3/ 3      3/ 3     0
  T2   errors     3/ 3      3/ 3     0
  T3   remove     2/ 2      2/ 2     0
  T5   IDs        2/ 2      2/ 2     0
  T6   ok wrap    3/ 3      3/ 3     0
  Subtotal       13/13      13/13     0

Category B (Code + memory nuance, weight x2):
                 Mode A    Mode B   Delta
  T4   dates      2/ 2      2/ 2     0
  Subtotal       2/ 2      2/ 2     0

Category C (Memory-only, weight x3):
                 Mode A    Mode B   Delta
  T7   err.code   0/ 3      3/ 3     +3
  T8   result-key 0/ 3      2/ 3     +2
  T9   batch-POST 1/ 1      1/ 1     0
  T10  order      0/ 2      0/ 2     0
  Subtotal       1/ 9      6/ 9     +5

──────────────────────────────────────────────────
Weighted Score:
  Mode A:  20/44 (45%)
  Mode B:  35/44 (79%)
  Delta:   +34%

Unweighted:  16/24 vs 21/24
```

## Verdict: +34% Delta — Memory System Demonstrates Clear Value

### What Changed from SYN-03 (0% delta)

SYN-03 root cause: agent never saved memories (0 `wt-memory remember` calls in all sessions).

SYN-05 fix: **post-session extraction** (`post-session-save.sh`). After each session, the runner mechanically extracts:
- C01: Code conventions from implemented files (pagination, error format, ok wrapper, ID format, dates, soft-delete)
- C02: Developer Notes corrections from the change file (dot.notation errors, result key, batch POST, order param)

This ensures forward-looking advice gets into memory regardless of whether the agent runs step 8.

### Memory Contents (10 memories)

| Source | Count | Examples |
|--------|-------|---------|
| C01 code conventions | 6 | Pagination `{entries, paging}`, error `{fault}`, `ok: true`, makeId, fmtDate, removedAt |
| C02 Developer Notes | 4 | T7: dot.notation errors, T8: result key wrapper, T9: batch POST body, T10: ?order=newest |

### Per-Trap Analysis

| Trap | Cat | Mode A | Mode B | Explanation |
|------|-----|--------|--------|-------------|
| T1-T6 | A | 13/13 | 13/13 | Code-readable — both modes discover from existing code |
| T4 | B | 2/2 | 2/2 | fmtDate scope — both modes find lib/fmt.js in code |
| **T7** | **C** | **0/3** | **3/3** | **dot.notation** — memory correction recalled, all 3 changes applied it |
| **T8** | **C** | **0/3** | **2/3** | **result key** — recalled and applied in C03+C05, missed in C04 dashboard |
| T9 | C | 1/1 | 1/1 | batch POST — C05 change file explicitly says POST, no memory needed |
| T10 | C | 0/2 | 0/2 | order param — memory exists but not recalled/applied (see below) |

### T10 Investigation

The sort/order correction was saved to memory but the agent didn't apply it. Possible reasons:
- The recall queries didn't surface the sort/order memory prominently
- The agent didn't connect "order param" advice to the dashboard's recent/timeline endpoints
- C04/C05 change files don't mention sorting, so the agent used defaults

### Session Timing

| Change | Mode A | Mode B |
|--------|--------|--------|
| C01 | 92s | 144s |
| C02 | 132s | ~130s |
| C03 | 155s | 178s |
| C04 | 137s | 171s |
| C05 | 69s | 109s |
| **Total** | **625s (10m)** | **778s (12m)** |

Mode B is ~25% slower due to recall overhead (3 wt-memory recall calls per session).

### Key Lessons

1. **Agents don't save memories voluntarily.** Even with explicit CLAUDE.md instructions ("you MUST save"), agents use all turns on implementation. Post-session extraction is necessary.
2. **Post-session extraction works.** Mechanically extracting corrections from change files and saving to memory produces genuine recall in subsequent sessions.
3. **Category C traps are the strongest signal.** A→A, B→B, but C shows clear Mode A=1/9 vs Mode B=6/9 separation.
4. **Concurrent Claude CLI runs fail.** Two `claude -p` processes running simultaneously causes one or both to exit immediately. Must run sequentially.
5. **T9 (batch POST) is a weak trap.** The C05 change file explicitly mentions POST, making it discoverable without memory. Consider removing from scoring.
6. **T10 recall is fragile.** Memory exists but isn't applied — the recall query may not surface it, or the agent doesn't connect it to the implementation context.

### Comparison Across Runs

| Run | Mode A | Mode B | Delta | Issue |
|-----|--------|--------|-------|-------|
| SYN-01 | 47% | 58% | +11% | v7 design, no weighted scoring |
| SYN-02 | 83% | 83% | 0% | Code persistence + probe leak |
| SYN-03 | 45% | 45% | 0% | Agent never saved memories |
| SYN-04 | 45% | 38% | -7% | Tainted (mid-run fixes) |
| **SYN-05** | **45%** | **79%** | **+34%** | **Post-session extraction works** |

### Next Steps for Publishable Results

1. **Run n=3**: Need at least 3 runs to show consistency
2. **Fix T10**: Improve recall queries or memory content for sort/order
3. **Remove T9**: It's not measuring memory (C05 change file says POST)
4. **Consider Mode C**: Pre-seeded memories as upper bound comparison
