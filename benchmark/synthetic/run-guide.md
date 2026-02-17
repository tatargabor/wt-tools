# MemoryProbe Run Guide

## Prerequisites

- Node.js v18+
- Claude Code CLI (`claude`)
- `wt-memory` (for modes B and C)
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

Expected score: ~20-35% (3-5/15 probes pass)

## Mode B: Full Memory (Save + Recall)

```bash
./scripts/init.sh --mode b --target ~/bench/probe-b
./scripts/run.sh ~/bench/probe-b
./scripts/score.sh ~/bench/probe-b
```

What happens:
1. Same as Mode A, but with `wt-memory` enabled
2. C01-C02 sessions save conventions to memory
3. C03-C05 sessions recall conventions before implementing

Expected score: ~80-93% (12-14/15 probes pass)

## Mode C: Pre-Seeded (Recall Only)

```bash
./scripts/init.sh --mode c --target ~/bench/probe-c
./scripts/run.sh ~/bench/probe-c --start 3 --end 5
./scripts/score.sh ~/bench/probe-c
```

What happens:
1. Bootstraps project with 6 convention memories pre-seeded
2. Skips C01-C02 (conventions already in memory)
3. Runs only C03-C05 — tests pure recall

Expected score: ~87-95% (13-14/15 probes pass)

Time: ~15-20 minutes.

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

15 convention probes across C03-C05:

| Change | Probes | Traps Tested |
|--------|--------|-------------|
| C03 | 4 | T1, T2, T5, T6 |
| C04 | 5 | T1, T2, T3, T4, T6 |
| C05 | 6 | T1, T2, T3, T4, T5, T6 |

Each probe checks:
1. **Project convention present** (e.g., `"paging"` in response handler)
2. **Standard pattern absent** (e.g., no `"total"` or `"limit"` in response)

Both conditions must be true for PASS.

## Troubleshooting

**Server won't start**: Check if port is in use: `lsof -i :3000`. Kill: `pkill -f "node src/server.js"`.

**Test script hangs**: Server may not be running. Start it manually: `node src/server.js &`

**Memory not working (Mode B)**: Check `wt-memory health`. Verify hooks: `ls .claude/hooks/`.

**Score is 0%**: Files may be named differently than expected. Check `ls src/routes/` — the scoring script uses flexible file discovery but needs at least partial name matches.

**Claude session times out**: Increase `--max-turns` in run.sh (default 25).

## Cleanup

```bash
rm -rf ~/bench/probe-a ~/bench/probe-b ~/bench/probe-c
```
