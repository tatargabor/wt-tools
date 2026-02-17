# MemoryProbe v8 — Synthetic Memory Benchmark

Tests whether shodh-memory improves convention compliance across fresh agent sessions.

## How It Works

5 small API changes, each run as a **separate Claude session** (fresh context). C01 establishes conventions, C02 introduces **corrections** (simulating human feedback that overrides earlier patterns). C03-C05 test whether the agent applies the corrected conventions.

```
C01 (SEED)  →  C02 (CORRECT)  →  C03 (PROBE)  →  C04 (PROBE)  →  C05 (PROBE)
 establish      human feedback     test recall     test recall     test recall
 conventions    + corrections      6 probes        8 probes        10 probes
```

**Memory is the only bridge between sessions.** Without it, agents must discover conventions by reading existing code — but C02 corrections create conflicts that only memory can resolve.

## Quick Start

```bash
# 1. Bootstrap two runs
./scripts/init.sh --mode a --target ~/bench/probe-a
./scripts/init.sh --mode b --target ~/bench/probe-b

# 2. Run both (each ~30 min)
./scripts/run.sh ~/bench/probe-a
./scripts/run.sh ~/bench/probe-b

# 3. Score and compare
./scripts/score.sh --compare ~/bench/probe-a ~/bench/probe-b
```

## Three Modes

| Mode | Memory | Changes | Time | What It Tests |
|------|--------|---------|------|---------------|
| A (baseline) | none | C01-C05 | ~30 min | Baseline convention compliance |
| B (full memory) | save + recall | C01-C05 | ~30 min | Save quality + recall effectiveness |
| C (pre-seeded) | recall only | C03-C05 | ~20 min | Pure recall (perfect memories injected) |

## Ten Convention Traps — Three Categories

### Category A: Code-readable (weight x1)

Conventions visible in existing C01 code. Memory reinforces but isn't unique.

| # | Convention | Project Standard | LLM Default |
|---|-----------|-----------------|-------------|
| T1 | Pagination | `{entries, paging: {current,size,count,pages}}` | `{data, total, page, limit}` |
| T3 | Soft-delete | `removedAt` | `deletedAt` |
| T5 | ID format | `evt_` + nanoid via `makeId()` | auto-increment / UUID |

### Category B: Human override (weight x2)

Conventions changed in C02 via Developer Notes. Code and spec show old pattern; memory carries the correction.

| # | Convention | C02 Correction | Old Pattern (C01/spec) |
|---|-----------|---------------|----------------------|
| T2 | Errors | `{fault: {reason, code, ts}}` | same (reinforced) |
| T4 | Date helper | `fmtDate()` for ALL dates | only display dates |
| T6 | Success wrap | `{ok: true, result: {...}}` | `{ok: true, ...payload}` |
| T7 | Error codes | `dot.notation` (`event.not_found`) | `SCREAMING_SNAKE` |
| T8 | Response nesting | `{ok: true, result: {entries, paging}}` | flat format |
| T10 | Sort parameter | `?order=newest\|oldest` | `?sort=desc\|asc` |

### Category C: Forward-looking (weight x3)

Advice given in C02 for features that don't exist yet. No code to read. Only memory carries this.

| # | Convention | C02 Advice | LLM Default |
|---|-----------|-----------|-------------|
| T9 | Batch IDs | POST body: `{ids: [...]}` | GET query: `?ids=1,2,3` |

## Weighted Scoring

24 convention probes across C03-C05. Max weighted score: **42 points**.

```
Raw   = Cat_A_pass * 1 + Cat_B_pass * 2 + Cat_C_pass * 3
Score = Raw / 42 * 100%
```

Category B provides the strongest signal (spec-vs-memory conflict). Category C provides a clean binary signal.

## Files

- `project-spec.md` — LogBook domain spec (intentionally stale after C02)
- `changes/` — 5 change definitions (C02 includes Developer Notes with corrections)
- `tests/` — acceptance test scripts (curl-based, include convention probes)
- `claude-md/` — CLAUDE.md variants (baseline vs with-memory)
- `scripts/` — init, run, pre-seed, score
- `scoring-rubric.md` — trap definitions, probe matrix, and category weights
- `run-guide.md` — detailed execution protocol (includes n=3 publication protocol)
