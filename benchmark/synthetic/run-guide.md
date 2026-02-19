# MemoryProbe v8 Run Guide

## Prerequisites

- Node.js v18+
- Claude Code CLI (`claude`)
- `wt-memory` (for modes B, C, and D)
- ~2 GB disk space (per run)
- Internet for npm install

## Quick Comparison (Mode A vs Mode B)

```bash
# Bootstrap both runs
cd benchmark/synthetic
./scripts/init.sh --mode a --target ~/bench/probe-a
./scripts/init.sh --mode b --target ~/bench/probe-b

# Run both (can run in parallel on different terminals)
./scripts/run.sh ~/bench/probe-a &
./scripts/run.sh ~/bench/probe-b &
wait

# Score and compare
./scripts/score.sh --compare ~/bench/probe-a ~/bench/probe-b
```

Total time: ~30-35 minutes (parallel) or ~60-70 minutes (sequential).

## n=3 Run Protocol (Recommended for Publication)

For publishable results, run each mode **3 times** and use **median** scoring.

```bash
cd benchmark/synthetic

# Mode A: 3 runs
for i in 1 2 3; do
  ./scripts/init.sh --mode a --target ~/bench/probe-a-$i
  ./scripts/run.sh ~/bench/probe-a-$i
done

# Mode B: 3 runs
for i in 1 2 3; do
  ./scripts/init.sh --mode b --target ~/bench/probe-b-$i
  ./scripts/run.sh ~/bench/probe-b-$i
done

# Score all runs
for i in 1 2 3; do
  echo "=== Mode A Run $i ==="
  ./scripts/score.sh ~/bench/probe-a-$i --json > ~/bench/score-a-$i.json
  ./scripts/score.sh ~/bench/probe-a-$i

  echo "=== Mode B Run $i ==="
  ./scripts/score.sh ~/bench/probe-b-$i --json > ~/bench/score-b-$i.json
  ./scripts/score.sh ~/bench/probe-b-$i
done

# Compare best median pair
./scripts/score.sh --compare ~/bench/probe-a-2 ~/bench/probe-b-2
```

**Median selection**: Sort each mode's 3 weighted scores. Use the middle run (run 2 after sorting) for the comparison.

Total time: ~3-3.5 hours (sequential). Can parallelize runs across terminals.

## Mode A: Baseline (No Memory)

```bash
./scripts/init.sh --mode a --target ~/bench/probe-a
./scripts/run.sh ~/bench/probe-a
./scripts/score.sh ~/bench/probe-a
```

What happens:
1. Bootstraps a clean project at `~/bench/probe-a`
2. Runs 5 Claude sessions (C01-C05), each in fresh context
3. Scores convention compliance on C03-C05

Expected weighted score: 40-65% (Category A passes + some B from code reading)

## Mode B: Full Memory (Save + Recall)

```bash
./scripts/init.sh --mode b --target ~/bench/probe-b
./scripts/run.sh ~/bench/probe-b
./scripts/score.sh ~/bench/probe-b
```

What happens:
1. Same as Mode A, but with `wt-memory` enabled
2. C01-C02 sessions save conventions to memory (C02 includes corrections)
3. C03-C05 sessions recall conventions before implementing

Expected weighted score: 85-100% (all categories, depends on save quality)

## Mode C: Pre-Seeded (Recall Only)

```bash
./scripts/init.sh --mode c --target ~/bench/probe-c
./scripts/run.sh ~/bench/probe-c --start 3 --end 5
./scripts/score.sh ~/bench/probe-c
```

What happens:
1. Bootstraps project with 10 convention memories pre-seeded (T1-T10)
2. Skips C01-C02 (conventions already in memory)
3. Runs only C03-C05 — tests pure recall

Expected weighted score: 90-100% (perfect memories, tests recall fidelity)

Time: ~15-20 minutes.

## Mode D: Rules (Deterministic Constraints)

```bash
./scripts/init.sh --mode d --target ~/bench/probe-d
./scripts/run.sh ~/bench/probe-d --start 3 --end 5
./scripts/score.sh ~/bench/probe-d
```

What happens:
1. Bootstraps project with `.claude/rules.yaml` containing all 10 conventions (T1-T10)
2. Deploys wt-memory hooks so rules are injected as `MANDATORY RULES` on every prompt
3. Skips C01-C02 (conventions already in rules)
4. Runs only C03-C05 — tests deterministic rule injection

The key difference from Mode C: rules are **always** injected when a topic keyword matches the prompt — no relevance filtering, no probabilistic recall. This tests whether deterministic rule delivery outperforms semantic memory recall.

Expected weighted score: 85-100% (deterministic injection; may miss rules whose topics don't match the prompt)

Time: ~15-20 minutes.

### Mode C vs Mode D Comparison

```bash
./scripts/init.sh --mode c --target ~/bench/probe-c
./scripts/init.sh --mode d --target ~/bench/probe-d

./scripts/run.sh ~/bench/probe-c --start 3 --end 5 &
./scripts/run.sh ~/bench/probe-d --start 3 --end 5 &
wait

./scripts/score.sh --compare ~/bench/probe-c ~/bench/probe-d
```

This comparison answers: **does deterministic rule injection outperform probabilistic memory recall?**

## Manual Run (Per-Session)

Instead of the automated runner, run each session manually:

```bash
cd ~/bench/probe-a

# Session 1
claude --dangerously-skip-permissions \
  -p "Implement docs/changes/01-event-crud.md. Read it first, then read docs/project-spec.md. Start server with: node src/server.js & — then run: bash tests/test-01.sh 3000. Fix any failures." \
  --max-turns 25

git add -A && git commit -m "Change 01 complete"

# Session 2 (fresh context!)
claude --dangerously-skip-permissions \
  -p "Implement docs/changes/02-tags-filtering.md. Read it and docs/project-spec.md first. Start server, run tests/test-02.sh 3000." \
  --max-turns 25

git add -A && git commit -m "Change 02 complete"

# ... repeat for sessions 3-5
```

## Scoring

### Automated

```bash
# Single run
./scripts/score.sh ~/bench/probe-a

# Compare two runs
./scripts/score.sh --compare ~/bench/probe-a ~/bench/probe-b

# JSON output (for scripts)
./scripts/score.sh ~/bench/probe-a --json
```

### What Gets Scored

24 convention probes across C03-C05, organized into 3 weighted categories:

| Category | Weight | Traps | Signal |
|----------|--------|-------|--------|
| A: Code-readable | x1 | T1, T3, T5 | Conventions visible in C01 code |
| B: Human override | x2 | T2, T4, T6, T7, T8, T10 | C02 corrections that override C01/spec |
| C: Forward-looking | x3 | T9 | Advice for features that don't exist yet |

| Change | Probes | Traps Tested |
|--------|--------|-------------|
| C03 | 6 | T1, T2, T5, T6, T7, T8 |
| C04 | 8 | T1, T2, T3, T4, T6, T7, T8, T10 |
| C05 | 10 | T1, T2, T3, T4, T5, T6, T7, T8, T9, T10 |

### Weighted Scoring

```
Raw    = Cat_A_pass * 1 + Cat_B_pass * 2 + Cat_C_pass * 3
Max    = Cat_A_total * 1 + Cat_B_total * 2 + Cat_C_total * 3
Score  = Raw / Max * 100%

Max = 7*1 + 16*2 + 1*3 = 42
```

### Expected Scores

| Mode | Cat A (x1) | Cat B (x2) | Cat C (x3) | Weighted |
|------|-----------|-----------|-----------|----------|
| A (no memory) | 5-7/7 | 6-10/16 | 0/1 | 40-65% |
| B (full memory) | 7/7 | 14-16/16 | 1/1 | 85-100% |
| C (pre-seeded) | 7/7 | 14-16/16 | 1/1 | 90-100% |
| D (rules) | 7/7 | 12-16/16 | 0-1/1 | 75-100% |

Category B provides the strongest signal (spec-vs-memory conflict). Category C provides a clean binary signal.

Mode D hypotheses:
- **Deterministic beats probabilistic**: D ≥ B for Cat B (rules always injected, no recall miss)
- **Topic matching limitation**: D may miss T9 (Category C) if "batch" topic doesn't appear in the prompt
- **Key comparison**: C vs D — same conventions, different delivery mechanism

## Troubleshooting

**Server won't start**: Check if port is in use: `lsof -i :3000`. Kill: `pkill -f "node src/server.js"`.

**Test script hangs**: Server may not be running. Start it manually: `node src/server.js &`

**Memory not working (Mode B)**: Check `wt-memory health`. Verify hooks: `ls .claude/hooks/`.

**Score is 0%**: Files may be named differently than expected. Check `ls src/routes/` — the scoring script uses flexible file discovery but needs at least partial name matches.

**Claude session times out**: Increase `--max-turns` in run.sh (default 25).

## Cleanup

```bash
rm -rf ~/bench/probe-a ~/bench/probe-b ~/bench/probe-c ~/bench/probe-d
# For n=3 runs:
rm -rf ~/bench/probe-a-{1,2,3} ~/bench/probe-b-{1,2,3} ~/bench/score-*.json
```
