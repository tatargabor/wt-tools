# MemoryProbe — Synthetic Memory Benchmark

Tests whether shodh-memory improves convention compliance across fresh agent sessions.

## How It Works

5 small API changes, each run as a **separate Claude session** (fresh context). Change 01 establishes 6 non-standard project conventions. Changes 03-05 test whether the agent follows those conventions without being reminded.

```
C01 (SEED)  →  C02 (GAP)  →  C03 (PROBE)  →  C04 (PROBE)  →  C05 (PROBE)
 establish      unrelated      test recall     test recall     test recall
 conventions    work           4 probes        5 probes        6 probes
```

**Memory is the only bridge between sessions.** Without it, agents must discover conventions by reading existing code.

## Quick Start

```bash
# 1. Bootstrap two runs
./scripts/init.sh --mode a --target ~/bench/probe-a
./scripts/init.sh --mode b --target ~/bench/probe-b

# 2. Run both (each ~30 min)
./scripts/run.sh ~/bench/probe-a
./scripts/run.sh ~/bench/probe-b

# 3. Score and compare
./scripts/score.sh ~/bench/probe-a
./scripts/score.sh ~/bench/probe-b
./scripts/score.sh --compare ~/bench/probe-a ~/bench/probe-b
```

## Three Modes

| Mode | Memory | Changes | Time | What It Tests |
|------|--------|---------|------|---------------|
| A (baseline) | none | C01-C05 | ~30 min | Baseline convention compliance |
| B (full memory) | save + recall | C01-C05 | ~30 min | Save quality + recall effectiveness |
| C (pre-seeded) | recall only | C03-C05 | ~20 min | Pure recall (perfect memories injected) |

## Six Convention Traps

| # | Convention | Project Standard | LLM Default |
|---|-----------|-----------------|-------------|
| T1 | Pagination | `{entries, paging: {current,size,count,pages}}` | `{data, total, page, limit}` |
| T2 | Errors | `{fault: {reason, code, ts}}` | `{error: string}` |
| T3 | Soft-delete | `removedAt` | `deletedAt` |
| T4 | Date helper | `fmtDate()` from `lib/fmt.js` | `toISOString()` |
| T5 | ID format | `evt_` + nanoid | auto-increment / UUID |
| T6 | Success wrap | `{ok: true, ...payload}` | bare payload |

## Scoring

Fully automated grep-based scoring. 15 convention probes across C03-C05.

```
MemoryProbe Score: 12/15 (80%)
  PASS  T1  C03  comment pagination
  PASS  T2  C03  comment errors
  FAIL  T5  C03  comment ID prefix
  ...
```

## Files

- `project-spec.md` — LogBook domain spec
- `changes/` — 5 change definitions (agent input + evaluator notes)
- `tests/` — acceptance test scripts (curl-based)
- `claude-md/` — CLAUDE.md variants (baseline vs with-memory)
- `scripts/` — init, run, pre-seed, score
- `scoring-rubric.md` — trap definitions and grep patterns
- `run-guide.md` — detailed execution protocol
