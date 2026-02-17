## Context

MemoryProbe v7 runs 5 sequential Claude Code sessions building a LogBook API. Each session implements one change in a fresh context. The benchmark compares Mode A (no memory) vs Mode B (shodh-memory). v7 showed +20% convention adherence but the signal is weak: all conventions are in `project-spec.md` which both modes read.

The v7 trap design:
```
C01 (SEED)  → establishes 6 conventions explicitly
C02 (GAP)   → tags, no convention probes
C03-C05 (PROBE) → test if conventions carry over
```

Problem: conventions carry over via project-spec.md, not memory. Memory is redundant.

## Goals / Non-Goals

**Goals:**
- Add trap categories that ONLY memory can solve (not code-reading, not spec-reading)
- Simulate real developer workflow: human gives feedback that changes conventions
- Keep runtime under 20 minutes per mode
- Maintain automated scoring (no manual review)
- Make results publishable with statistical confidence (n=3)

**Non-Goals:**
- Changing the LogBook domain or adding more changes (5 is enough)
- Testing memory save quality (only testing recall value)
- Comparing different memory implementations (only shodh-memory vs none)

## Decisions

### D1: C02 becomes "Correction" change

C02 change file gets a "Developer Notes" section simulating human feedback from C01 code review. This is the core mechanism for creating memory-unique knowledge.

**Rationale**: In real dev, humans share corrections that override docs and defaults. This is exactly what memory should capture. A "gap" change wastes the C02 session.

### D2: Three new trap categories

| Category | Source | In code? | In spec? | In memory? | Weight |
|----------|--------|----------|----------|------------|--------|
| A: Code-readable | C01 code | yes | yes | yes | x1 |
| B: Human override | C02 corrections | mixed¹ | stale² | yes | x2 |
| C: Forward-looking | C02 advice | no | no | yes | x3 |

¹ C01 code shows old pattern, C02 code shows new — mixed signals
² project-spec.md still documents the OLD convention

**Specific traps:**

**T7 (Human override — error codes)**: C01 uses `EVT_NOT_FOUND` (SCREAMING_SNAKE). C02 Developer Notes say: "We're switching to dot.notation: `event.not_found`." project-spec.md still says SCREAMING_SNAKE. Memory agent uses dot.notation; no-memory agent sees conflicting signals.

Grep probe: `grep -E '\.[a-z_]+\.' <file>` for dot.notation vs `grep -E '[A-Z]+_[A-Z]+' <file>` for SCREAMING_SNAKE.

**T8 (Human override — response nesting)**: C02 Developer Notes say: "Wrap entity data in a `result` key: `{ok: true, result: {entries: [...], paging: {...}}}` not `{ok: true, entries: [...], paging: {...}}`." This is a subtle change. C01 code uses the flat format. project-spec.md documents flat format.

Grep probe: `grep -E 'result[[:space:]]*:' <file>` for nested vs absence for flat.

**T9 (Forward-looking — batch POST)**: C02 Developer Notes say: "When we add bulk endpoints, use POST with body `{ids: [...]}`, not GET with query params. Express doesn't parse array query params reliably." This advice has NO code backing — bulk ops don't exist yet. Only memory carries this to C05.

Grep probe: `grep -E 'req\.body\.ids|req\.body\.\w*Ids' <file>` for POST body vs `grep -E 'req\.query\.ids' <file>` for query params.

**T10 (Human override — sort convention)**: C02 Developer Notes say: "For ordered lists, support `?order=newest|oldest` parameter, not `?sort=desc|asc`. Our frontend team expects `order`." No code implements this yet (C02's tags don't need ordering), so C03-C05 agents must remember or not.

Grep probe: `grep -E "order.*newest|order.*oldest|req\.query\.order" <file>` for convention vs `grep -E "sort.*desc|sort.*asc|req\.query\.sort" <file>` for default.

### D3: project-spec.md stays but becomes intentionally stale

**Alternative considered**: Remove conventions from project-spec.md entirely.
**Rejected**: That's unrealistic. Real projects have docs that become outdated — the benchmark should test whether the agent follows stale docs or fresh human input.

The spec keeps the C01-era conventions. C02's corrections override some of them. This creates the realistic conflict: spec says X, human said Y, code shows both.

### D4: Weighted scoring formula

```
Raw score:  category_A * 1 + category_B * 2 + category_C * 3
Max score:  A_total * 1 + B_total * 2 + C_total * 3
Percent:    raw / max * 100
```

This weights memory-unique traps higher. A perfect score on code-readable traps with zero on memory traps gives a low percentage.

### D5: n=3 run protocol

Each mode runs 3 times. Report median score. This addresses the n=1 problem from v7 and accounts for LLM non-determinism. Total benchmark time: ~60 min per mode (3 x 20 min).

### D6: Test scripts combine curl + grep probes

v7 had separate curl tests (API behavior) and grep probes (source code). v8 merges them:
- Functional tests: curl checks (endpoints work, correct HTTP codes)
- Convention probes: grep on source files
- Correction probes: grep for new patterns (dot.notation, result wrapper, order param)
- Forward probes: grep for advice-following (POST body for batch)

All in the same test-NN.sh scripts, scored separately in score.sh.

## Risks / Trade-offs

**[Risk] Correction traps are too easy to infer** → Some agents might see C02 code patterns and follow them even without memory. Mitigation: C02 only implements tags — the corrections mention patterns that C02 itself barely uses. The new patterns aren't strongly established in code.

**[Risk] Too many traps dilutes the signal** → Going from 6 to 10 traps. Mitigation: Weighted scoring ensures the high-value traps dominate the score. Code-readable traps are baseline; the real comparison is on override/forward traps.

**[Risk] dot.notation error codes break test expectations** → The test scripts expect specific error formats. Mitigation: Update test scripts to accept both formats but probe for the preferred one.

**[Risk] n=3 runs take too long** → 3 runs * 2 modes * ~10 min = ~60 min total. Acceptable for a release benchmark. Can parallelize A and B runs.

**[Trade-off] Stale spec is a confound** → The stale spec tests memory vs spec-reading, not just memory vs nothing. This is intentional: in real dev, outdated docs are the primary competitor to memory.
