# Benchmark Run Guide

Complete step-by-step guide for executing the shodh-memory benchmark v2.

## Prerequisites

- **wt-tools** installed and on PATH (`wt-loop`, `wt-deploy-hooks`, `wt-memory`, `wt-memory-hooks` all available)
- **Node.js 18+** (`node --version`)
- **Claude Code CLI** installed (`claude --version`)
- **openspec CLI** installed (`openspec --version`; install: `npm install -g @fission-ai/openspec`)
- Enough disk/RAM for two parallel Next.js projects

## 1. Bootstrap

Two init scripts handle all setup. Each creates a fresh CraftBazaar repo with the right CLAUDE.md, extracts agent-only change files (12 changes), copies test scripts, and commits.

### Run A (Baseline — No Memory)

```bash
./benchmark/init-baseline.sh [target-dir]
# Default: ~/benchmark/run-a/craftbazaar-baseline
```

What it does: `git init` → `npm init` → `openspec init --tools claude` → `wt-deploy-hooks` → copies `baseline.md` as CLAUDE.md (PORT=4000) → extracts 12 change files (agent-only, no evaluator notes) → copies test scripts to `tests/` → initial commit.

**No** `wt-memory-hooks install` — baseline has no memory.

### Run B (With Memory)

```bash
./benchmark/init-with-memory.sh [target-dir]
# Default: ~/benchmark/run-b/craftbazaar-memory
```

Same as Run A plus: `wt-memory-hooks install` → copies `with-memory.md` as CLAUDE.md (PORT=4001) → verifies `wt-memory health`.

### What the scripts check

Both scripts verify prerequisites before starting and will error if anything is missing. They also verify that evaluator notes didn't leak into the agent-visible change files.

## 2. Starting the Runs

### Option A: Interactive Claude sessions (recommended)

Open two terminals, each running Claude Code interactively:

**Terminal 1 (Run A):**
```bash
cd ~/benchmark/run-a/craftbazaar-baseline
claude --dangerously-skip-permissions
```

**Terminal 2 (Run B):**
```bash
cd ~/benchmark/run-b/craftbazaar-memory
claude --dangerously-skip-permissions
```

Then paste this prompt into **each** Claude session:

```
Read CLAUDE.md, then check openspec list --json and ls docs/benchmark/ to find the next
incomplete change. Read the project spec (if first change) and the change definition file.
Then implement it: run /opsx:ff <change-name> to create artifacts, then /opsx:apply <change-name>
to implement. Run bash tests/test-NN.sh <PORT> after each change and fix until pass.
Follow the Benchmark Task workflow in CLAUDE.md exactly — work through all 12 changes in order.
```

### Option B: wt-loop automation

```bash
# Terminal 1 (Run A)
cd ~/benchmark/run-a/craftbazaar-baseline
wt-loop start "Build CraftBazaar changes 01-12" --max 30 --stall-threshold 3 --done manual

# Terminal 2 (Run B)
cd ~/benchmark/run-b/craftbazaar-memory
wt-loop start "Build CraftBazaar changes 01-12" --max 30 --stall-threshold 3 --done manual
```

### Key flags

| Flag | Value | Purpose |
|------|-------|---------|
| `--max 30` | 30 iterations | Budget for 12 changes with test-fix cycles |
| `--stall-threshold 3` | 3 iterations | Stop if no commits for 3 consecutive iterations |
| `--done manual` | manual completion | Agent decides when done |

### First-run trust

Before starting the loop, open Claude interactively once in each directory to accept the trust prompt:

```bash
cd ~/benchmark/run-a/craftbazaar-baseline && claude --dangerously-skip-permissions
# Type "hello", wait for response, Ctrl+C to exit

cd ~/benchmark/run-b/craftbazaar-memory && claude --dangerously-skip-permissions
# Same — accept trust, then exit
```

### Monitoring

From a third terminal:
```bash
# Check status
cd ~/benchmark/run-a/craftbazaar-baseline && wt-loop status
cd ~/benchmark/run-b/craftbazaar-memory && wt-loop status
```

## 3. No-Intervention Policy

During execution:
- **Do NOT** provide hints, answers, or direction to the agent
- **Do NOT** fix errors, install packages, or modify files
- If the agent asks a yes/no question, wt-loop auto-continues (fresh iteration)
- If the loop stalls (3 iterations with no commits), let it stop — the stall is data
- If the loop hits max iterations (30), let it stop — record which changes completed

The only acceptable interventions:
- Restarting if the process crashes (machine reboot, OOM, etc.)
- Checking status with `wt-loop status` (read-only)

## 4. Running Acceptance Tests (post-run)

After both runs complete, run the test suite against each project:

```bash
# Start the dev server
cd ~/benchmark/run-a/craftbazaar-baseline
PORT=4000 npm run dev &
sleep 5

# Run all tests
for t in tests/test-*.sh; do
  echo "--- $t ---"
  bash "$t" 4000
  echo ""
done

# Repeat for Run B with PORT=4001
```

## 5. Running Evaluator Scripts (post-run)

The evaluator scripts in `benchmark/evaluator/` provide automated checks:

```bash
EVAL_DIR="/path/to/wt-tools/benchmark/evaluator"

# For each run:
cd ~/benchmark/run-a/craftbazaar-baseline

# Schema checks (Image table, Int money, CartReservation, indexes)
bash "$EVAL_DIR/eval-schema.sh" .

# API checks (response format, money format) — needs running server
bash "$EVAL_DIR/eval-api.sh" 4000

# Behavior checks (stock logic, transactions, payout formula)
bash "$EVAL_DIR/eval-behavior.sh" .

# Coherence checks (prisma validate, tsc, seed, build)
bash "$EVAL_DIR/eval-coherence.sh" .
```

### Collecting all results

```bash
bash "$EVAL_DIR/collect-results.sh" ~/benchmark/run-a/craftbazaar-baseline "Run A (baseline)"
bash "$EVAL_DIR/collect-results.sh" ~/benchmark/run-b/craftbazaar-memory "Run B (memory)"
```

### Generating comparison

```bash
bash "$EVAL_DIR/compare.sh" \
  ~/benchmark/run-a/craftbazaar-baseline/results-run-a--baseline-.json \
  ~/benchmark/run-b/craftbazaar-memory/results-run-b--memory-.json
```

## 6. Results Collection

After both runs complete, gather data:

### Automatic data

```bash
# For each run (run-a and run-b):
cd ~/benchmark/<run>/craftbazaar-<label>

# Iteration history
wt-loop history

# Git log with timestamps
git log --oneline --format="%h %ai %s"

# OpenSpec change completion
openspec list --json

# Agent-written status files
cat results/*.json

# Session transcript
cat .claude/ralph-loop.log
```

### Run B additional data

```bash
cd ~/benchmark/run-b/craftbazaar-memory

# All saved memories
wt-memory list --json

# Memory count and health
wt-memory status
```

## 7. Post-Run Annotation

For each change in each run:

1. Open the session transcript and find the relevant iterations
2. Review the agent's approach against the evaluator notes in `benchmark/changes/NN-*.md`
3. Fill out `benchmark/templates/session-annotation.md` (one per change per run)
4. Fill out `benchmark/templates/change-metrics.json` (one per change per run)

### Key areas to focus on (v2-specific)

| Changes | What to look for |
|---------|-----------------|
| C07-C09 | Did the agent find all affected code? How many iterations to search? |
| C10 | Did the agent add an "Update cart" button? Use confirm()? |
| C11 | Did the agent remove tabs or enhance them? |
| C12 | How many of the 12 bugs were fixed on first try? |

## 8. Comparison Report

After annotating all changes:

1. Run the automated comparison: `bash benchmark/evaluator/compare.sh run-a.json run-b.json`
2. Copy `benchmark/templates/comparison-report.md`
3. Fill in the per-change comparison sections with transcript evidence
4. For Run B, complete the diagnostic gap analysis using `benchmark/diagnostic-framework.md`

Alternatively, use `benchmark/collect-results.md` for agent-assisted evaluation.
