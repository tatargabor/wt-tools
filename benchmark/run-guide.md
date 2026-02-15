# Benchmark Run Guide

Complete step-by-step guide for executing the shodh-memory benchmark.

## Prerequisites

- **wt-tools** installed and on PATH (`wt-loop`, `wt-deploy-hooks`, `wt-memory`, `wt-memory-hooks` all available)
- **Node.js 18+** (`node --version`)
- **Claude Code CLI** installed (`claude --version`)
- **openspec CLI** installed (`openspec --version`; install: `npm install -g @fission-ai/openspec`)
- Enough disk/RAM for two parallel Next.js projects

## 1. Bootstrap

Two init scripts handle all setup. Each creates a fresh CraftBazaar repo with the right CLAUDE.md, extracts agent-only change files, and commits.

### Run A (Baseline — No Memory)

```bash
./benchmark/init-baseline.sh [target-dir]
# Default: ~/benchmark/run-a/craftbazaar
```

What it does: `git init` → `npm init` → `openspec init --tools claude` → `wt-deploy-hooks` → copies `baseline.md` as CLAUDE.md (PORT=3000) → extracts 6 change files (agent-only, no evaluator notes) → initial commit.

**No** `wt-memory-hooks install` — baseline has no memory.

### Run B (With Memory)

```bash
./benchmark/init-with-memory.sh [target-dir]
# Default: ~/benchmark/run-b/craftbazaar
```

Same as Run A plus: `wt-memory-hooks install` → copies `with-memory.md` as CLAUDE.md (PORT=3001) → verifies `wt-memory health`.

### What the scripts check

Both scripts verify prerequisites before starting and will error if anything is missing. They also verify that evaluator notes didn't leak into the agent-visible change files.

### Manual bootstrap

If you prefer manual setup, the scripts are short and readable — each is ~60 lines of bash. The key steps:

1. `git init` + `npm init -y`
2. `openspec init --tools claude`
3. `wt-deploy-hooks .`
4. (Run B only) `wt-memory-hooks install`
5. Copy the right CLAUDE.md from `benchmark/claude-md/`
6. Extract agent-only change sections:
   ```bash
   for f in benchmark/changes/0*.md; do
     sed '/<!-- EVALUATOR NOTES BELOW/,$d' "$f" > docs/benchmark/$(basename "$f")
   done
   ```
7. `git add -A && git commit`

## 2. Starting the Runs

### Option A: Parallel execution (recommended)

Open two terminals:

**Terminal 1 (Run A):**
```bash
cd ~/benchmark/run-a/craftbazaar
wt-loop start "Build CraftBazaar changes 01-06" --max 20 --stall-threshold 3 --done manual
```

**Terminal 2 (Run B):**
```bash
cd ~/benchmark/run-b/craftbazaar
wt-loop start "Build CraftBazaar changes 01-06" --max 20 --stall-threshold 3 --done manual
```

### Option B: Sequential execution

```bash
cd ~/benchmark/run-a/craftbazaar
wt-loop start "Build CraftBazaar changes 01-06" --max 20 --stall-threshold 3 --done manual

# Wait for Run A to complete, then:
cd ~/benchmark/run-b/craftbazaar
wt-loop start "Build CraftBazaar changes 01-06" --max 20 --stall-threshold 3 --done manual
```

### Key flags

| Flag | Value | Purpose |
|------|-------|---------|
| `--max 20` | 20 iterations | Enough for 6 changes + retries, bounded to prevent runaway |
| `--stall-threshold 3` | 3 iterations | Stop if no commits for 3 consecutive iterations (agent is stuck) |
| `--done manual` | manual completion | Agent decides when done (not based on tasks.md) |

### Monitoring

From a third terminal:
```bash
# Check status
cd ~/benchmark/run-a/craftbazaar && wt-loop status
cd ~/benchmark/run-b/craftbazaar && wt-loop status

# Or monitor continuously
cd ~/benchmark/run-a/craftbazaar && wt-loop monitor --interval 60
```

## 3. No-Intervention Policy

During execution:
- **Do NOT** provide hints, answers, or direction to the agent
- **Do NOT** fix errors, install packages, or modify files
- If the agent asks a yes/no question, wt-loop auto-continues (fresh iteration)
- If the loop stalls (3 iterations with no commits), let it stop — the stall is data
- If the loop hits max iterations (20), let it stop — record which changes completed

The only acceptable interventions:
- Restarting if the process crashes (machine reboot, OOM, etc.)
- Checking status with `wt-loop status` (read-only)

## 4. Results Collection

After both runs complete (or stall/hit max), gather data:

### Automatic data

```bash
# For each run (run-a and run-b):
cd ~/benchmark/<run>/craftbazaar

# Iteration history (time, tokens, commits per iteration)
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
cd ~/benchmark/run-b/craftbazaar

# All saved memories
wt-memory list --json

# Memory count and health
wt-memory status
```

### Copy data for annotation

```bash
mkdir -p ~/benchmark/results

# Copy transcripts
cp ~/benchmark/run-a/craftbazaar/.claude/ralph-loop.log ~/benchmark/results/run-a-transcript.log
cp ~/benchmark/run-b/craftbazaar/.claude/ralph-loop.log ~/benchmark/results/run-b-transcript.log

# Copy status files
cp -r ~/benchmark/run-a/craftbazaar/results/ ~/benchmark/results/run-a-status/
cp -r ~/benchmark/run-b/craftbazaar/results/ ~/benchmark/results/run-b-status/

# Export Run B memories
cd ~/benchmark/run-b/craftbazaar
wt-memory export --output ~/benchmark/results/run-b-memories.json
```

## 5. Post-Run Annotation

For each change in each run:

1. Open the session transcript and find the relevant iterations
2. Review the agent's approach against the evaluator notes in `benchmark/changes/0N-*.md`
3. Fill out `benchmark/templates/session-annotation.md` (one per change per run)
4. Fill out `benchmark/templates/change-metrics.json` (one per change per run)

### Finding change boundaries in transcripts

Look for these markers in the transcript:
- `openspec list` output (agent checking completion status)
- `/opsx:ff <change-name>` invocations (agent starting a new change)
- `results/change-0N.json` writes (agent completing a change)
- Commit messages mentioning change names

## 6. Comparison Report

After annotating all changes:

1. Copy `benchmark/templates/comparison-report.md`
2. Fill in the aggregate metrics table from per-change data
3. Fill in the per-change comparison sections
4. Write narrative findings
5. For Run B, complete the diagnostic gap analysis using `benchmark/diagnostic-framework.md`

Alternatively, use `benchmark/collect-results.md` for agent-assisted evaluation.
