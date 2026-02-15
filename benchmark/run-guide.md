# Benchmark Run Guide

Complete step-by-step guide for executing the shodh-memory benchmark.

## Prerequisites

- **wt-tools** installed and on PATH (`wt-loop`, `wt-deploy-hooks`, `wt-memory`, `wt-memory-hooks` all available)
- **Node.js 18+** (`node --version`)
- **Claude Code CLI** installed (`claude --version`)
- **openspec CLI** installed (`openspec --version`; install: `npm install -g @fission-ai/openspec`)
- **jq** installed (for change file extraction)
- Enough disk/RAM for two parallel Next.js projects

## Directory Setup

```bash
mkdir -p ~/benchmark/run-a
mkdir -p ~/benchmark/run-b
```

## 1. Bootstrap Run A (Baseline — No Memory)

```bash
# Create project
cd ~/benchmark/run-a
mkdir craftbazaar && cd craftbazaar
git init

# Initialize Node.js project
npm init -y

# Initialize OpenSpec with Claude Code skills
openspec init --tools claude

# Deploy Claude Code hooks (UserPromptSubmit + Stop)
wt-deploy-hooks .

# Create docs/benchmark/ for agent-visible change definitions
mkdir -p docs/benchmark

# Copy CLAUDE.md (baseline — no memory)
cp <wt-tools-root>/benchmark/claude-md/baseline.md ./CLAUDE.md

# Extract agent-only sections from change definitions (see "Change File Extraction" below)
# ... (run extraction for each change)

# Create results directory
mkdir -p results

# Initial commit
git add -A
git commit -m "Initial CraftBazaar setup (baseline run)"
```

**Important**: Do NOT run `wt-memory-hooks install` for Run A. The baseline has no memory integration in skills.

## 2. Bootstrap Run B (With Memory)

```bash
# Create project
cd ~/benchmark/run-b
mkdir craftbazaar && cd craftbazaar
git init

# Initialize Node.js project
npm init -y

# Initialize OpenSpec with Claude Code skills
openspec init --tools claude

# Deploy Claude Code hooks (UserPromptSubmit + Stop)
wt-deploy-hooks .

# Install memory hooks into OpenSpec skills
wt-memory-hooks install

# Create docs/benchmark/ for agent-visible change definitions
mkdir -p docs/benchmark

# Copy CLAUDE.md (with memory)
cp <wt-tools-root>/benchmark/claude-md/with-memory.md ./CLAUDE.md

# Extract agent-only sections from change definitions (see "Change File Extraction" below)
# ... (run extraction for each change)

# Create results directory
mkdir -p results

# Verify memory is working
wt-memory health

# Initial commit
git add -A
git commit -m "Initial CraftBazaar setup (memory run)"
```

## 3. Change File Extraction

Each change definition in `<wt-tools-root>/benchmark/changes/` has two sections separated by:
```
<!-- EVALUATOR NOTES BELOW — NOT INCLUDED IN AGENT INPUT -->
```

Only the content ABOVE this marker goes into the project repo. Run this for each change:

```bash
# Set the wt-tools root (adjust to your path)
WT_ROOT=<path-to-wt-tools>

# Extract agent-only sections for all 6 changes
for f in "$WT_ROOT"/benchmark/changes/0*.md; do
  basename=$(basename "$f")
  # Extract everything before the EVALUATOR NOTES marker
  sed '/<!-- EVALUATOR NOTES BELOW/,$d' "$f" > docs/benchmark/"$basename"
done
```

Verify the extraction:
```bash
# Should show 6 files
ls docs/benchmark/

# None should contain "EVALUATOR NOTES" or "Evaluator Notes"
grep -l "Evaluator Notes" docs/benchmark/*.md
# (should return nothing)
```

Run the extraction in BOTH `~/benchmark/run-a/craftbazaar/` and `~/benchmark/run-b/craftbazaar/`.

## 4. Starting the Runs

### Option A: Sequential execution

```bash
# Run A first
cd ~/benchmark/run-a/craftbazaar
wt-loop start "Build CraftBazaar changes 01-06" --max 20 --stall-threshold 3 --done manual

# Wait for Run A to complete, then:
cd ~/benchmark/run-b/craftbazaar
wt-loop start "Build CraftBazaar changes 01-06" --max 20 --stall-threshold 3 --done manual
```

### Option B: Parallel execution (recommended)

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

### Monitoring

From a third terminal:
```bash
# Check Run A status
cd ~/benchmark/run-a/craftbazaar && wt-loop status

# Check Run B status
cd ~/benchmark/run-b/craftbazaar && wt-loop status

# Or monitor continuously
cd ~/benchmark/run-a/craftbazaar && wt-loop monitor --interval 60
```

### Key flags explained

| Flag | Value | Purpose |
|------|-------|---------|
| `--max 20` | 20 iterations | Enough for 6 changes + retries, bounded to prevent runaway |
| `--stall-threshold 3` | 3 iterations | Stop if no commits for 3 consecutive iterations (agent is stuck) |
| `--done manual` | manual completion | Agent decides when done (not based on tasks.md) |

## 5. No-Intervention Policy

During execution:
- **Do NOT** provide hints, answers, or direction to the agent
- **Do NOT** fix errors, install packages, or modify files
- If the agent asks a yes/no question, wt-loop auto-continues (fresh iteration)
- If the loop stalls (3 iterations with no commits), let it stop — the stall is data
- If the loop hits max iterations (20), let it stop — record which changes completed

The only acceptable interventions:
- Restarting if the process crashes (machine reboot, OOM, etc.)
- Checking status with `wt-loop status` (read-only)

## 6. Results Collection

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

## 7. Post-Run Annotation

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

## 8. Comparison Report

After annotating all changes:

1. Copy `benchmark/templates/comparison-report.md`
2. Fill in the aggregate metrics table from per-change data
3. Fill in the per-change comparison sections
4. Write narrative findings
5. For Run B, complete the diagnostic gap analysis using `benchmark/diagnostic-framework.md`

Alternatively, use `benchmark/collect-results.md` for agent-assisted evaluation.
