## Context

The CraftBazaar A-B benchmark tests memory value by having two agents build a full e-commerce app (12 changes, 14 traps). It works but is slow (~5 hours), noisy (coding ability dominates), and requires manual scoring. v6 showed Run A (no memory) outperforming Run B — the signal is too weak.

MemoryProbe is a focused synthetic benchmark that isolates memory value by testing **convention recall across fresh sessions**.

## Goals / Non-Goals

**Goals:**
- Run complete benchmark in <1 hour (all 3 modes combined)
- Fully automated scoring — zero manual transcript review
- Clear, unambiguous memory advantage signal (>30% delta expected)
- Simple to set up (single init script) and reproduce

**Non-Goals:**
- Testing agent coding ability (all changes are trivially simple)
- Testing memory save quality (Mode C pre-seeds memories directly)
- Testing OpenSpec workflow integration
- Replacing CraftBazaar benchmark (MemoryProbe is complementary, not a replacement)

## Decisions

### 1. Domain: LogBook — Event Logging API

**Choice**: Minimal event logging REST API (events, categories, tags, comments).

**Why**: Simple enough to implement in 5-10 minutes per change, complex enough to need multiple endpoints with consistent conventions. No business logic complexity — the cognitive load is on conventions, not architecture.

**Stack**: Node.js + Express + better-sqlite3. No ORM (avoids Prisma quirks which are a separate variable). No frontend (API-only, tested with curl).

### 2. Six Non-Standard Convention Traps

**Choice**: All traps are project conventions that differ from industry-standard patterns.

**Why**: Standard patterns are in LLM training data. An agent without memory would naturally use `{data, total}` pagination, `{error: string}` errors, `deletedAt` for soft-delete. By using non-standard alternatives, we ensure that **only memory (or code reading) can produce the correct convention**.

The 6 conventions (see trap-design spec for details):

| # | Convention | Project Standard | Common Default |
|---|-----------|-----------------|----------------|
| T1 | Pagination | `{entries, paging: {current, size, count, pages}}` | `{data, total, page, limit}` |
| T2 | Errors | `{fault: {reason, code, ts}}` | `{error: string}` or `{message, code}` |
| T3 | Soft-delete | `removedAt` column | `deletedAt` or `isDeleted` |
| T4 | Date format | `fmtDate()` from `lib/fmt.js` → `YYYY/MM/DD HH:mm` | `toISOString()` or `toLocaleString()` |
| T5 | ID prefix | `evt_`, `cat_`, `cmt_` + nanoid | auto-increment or plain UUID |
| T6 | Success wrap | `{ok: true, ...payload}` | bare payload or `{success: true, data}` |

**Signal strength**: Each convention is unique enough that an LLM would never guess it. `fault.reason` instead of `error.message`? `removedAt` instead of `deletedAt`? `entries` instead of `data`? These are project-specific choices.

### 3. Separate Sessions Per Change

**Choice**: Each change runs as an independent `claude` invocation. No shared context window.

**Why**: In CraftBazaar, all changes run in one loop — C01's conventions stay in the 200K context window for C05. This means even non-memory agents "remember" conventions. Separate sessions force memory to be the only bridge.

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│ Session  │    │ Session  │    │ Session  │    │ Session  │    │ Session  │
│   C01    │    │   C02    │    │   C03    │    │   C04    │    │   C05    │
│  (SEED)  │    │  (GAP)   │    │ (PROBE)  │    │ (PROBE)  │    │ (PROBE)  │
└────┬─────┘    └────┬─────┘    └────┬─────┘    └────┬─────┘    └────┬─────┘
     │               │               │               │               │
     │  Memory saves  │               │  Memory recalls               │
     └──────────────▶ │ ─────────────▶└──────────────▶└──────────────▶│
                      │                                               │
     ← fresh context ─┤── fresh context ──┤── fresh context ──┤── fresh context ─┤
```

**Caveat**: Non-memory agents CAN discover conventions by reading existing code (grep/read C01's files). This is realistic — in real work, agents read existing code too. But memory gives **faster, more reliable** access. The delta measures this advantage.

### 4. Three Test Modes

**Choice**: Three modes that test different aspects of memory.

```
MODE A: Baseline (no memory)
  Sessions: C01 → C02 → C03 → C04 → C05
  Memory: disabled
  Tests: save=NO, recall=NO
  Time: ~25-35 min

MODE B: Full memory (save + recall)
  Sessions: C01 → C02 → C03 → C04 → C05
  Memory: enabled (save in C01-C02, recall in C03-C05)
  Tests: save=YES, recall=YES
  Time: ~25-35 min

MODE C: Pre-seeded recall only
  Setup: inject 6 convention memories via script
  Sessions: C03 → C04 → C05 (skip seed changes)
  Memory: enabled (recall only)
  Tests: save=NO, recall=YES
  Time: ~15-20 min
```

**Why Mode C?** Isolates recall from save. If Mode B scores low, is it because the agent didn't save conventions, or because recall didn't work? Mode C answers this by pre-seeding perfect memories.

### 5. Automated Grep-Based Scoring

**Choice**: Every convention probe has an exact grep pattern. No transcript review, no subjective judgment.

**Why**: The CraftBazaar rubric requires reading transcripts and scoring dead-ends/rework (0-5 scales). This is slow and subjective. MemoryProbe scores are binary per probe: the convention was followed (PASS) or not (FAIL).

Scoring script runs in <5 seconds:
```
T1 pagination: grep -r 'paging.*current.*size.*count' src/routes/
T2 errors:     grep -r 'fault.*reason' src/routes/ src/middleware/
T3 soft-delete: grep -r 'removedAt' src/db/ src/routes/
T4 date helper: grep -r 'fmtDate' src/routes/
T5 ID prefix:  grep -r "evt_\|cat_\|cmt_\|tag_" src/
T6 success wrap: grep -r '"ok".*true\|ok: true' src/routes/
```

### 6. No OpenSpec / No wt-loop

**Choice**: Direct `claude` CLI invocations. No OpenSpec workflow, no wt-loop automation.

**Why**: Fewer moving parts = cleaner signal. OpenSpec adds its own cognitive overhead (artifact creation, skill hooks). The benchmark should test memory, not OpenSpec proficiency.

Execution:
```bash
# Per change
claude --dangerously-skip-permissions -p "$(cat docs/changes/0N.md)" --max-turns 30
```

## Risks / Trade-offs

- **[Code reading bypass]** Non-memory agents can discover conventions by reading C01's code. This is realistic but reduces the memory delta. Mitigation: conventions span multiple files (not all in one place), so discovering ALL 6 requires thorough exploration.
- **[Small sample size]** 3 probe changes × 6 traps = 18 probes. Enough for a clear signal but not for statistical significance. Mitigation: run multiple times if needed.
- **[LLM variance]** Same agent, same prompt, different results each time. Mitigation: Mode C (pre-seeded) reduces variance by eliminating the save step. Can also average over 3 runs.
- **[Convention bleed from file reading]** Agent might read `lib/fmt.js` and discover `fmtDate()` even without memory. Mitigation: this IS what we're testing — memory should be faster/more reliable than code exploration, not the only way.
