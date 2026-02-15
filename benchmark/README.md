# shodh-memory Benchmark Protocol

A reproducible benchmark for measuring the impact of persistent developer memory (shodh-memory) on AI agent effectiveness across independent sessions.

## Overview

Two autonomous agents implement the same multi-change project (CraftBazaar — a multi-vendor artisan marketplace). One agent runs without memory (baseline), the other with shodh-memory enabled. Both use identical tooling (wt-tools, OpenSpec, wt-loop) and receive the same task descriptions.

The project is designed with 6 sequential changes where early decisions cascade into later ones, creating natural traps that cross-session memory can help avoid.

## What's in this directory

| File/Directory | Purpose |
|---|---|
| `project-spec.md` | CraftBazaar domain specification (agent input) |
| `changes/01-*.md` through `06-*.md` | Per-change definitions with agent input + evaluator notes |
| `claude-md/baseline.md` | CLAUDE.md for Run A (no memory) |
| `claude-md/with-memory.md` | CLAUDE.md for Run B (with memory) |
| `run-guide.md` | Step-by-step execution instructions |
| `scoring-rubric.md` | Evaluation criteria and scoring methodology |
| `diagnostic-framework.md` | Memory gap analysis methodology |
| `templates/` | Annotation, metrics, and report templates |
| `collect-results.md` | Post-run results collection guide |

## Quick Start

1. Read `run-guide.md` for prerequisites and full setup
2. Bootstrap two repos (Run A: baseline, Run B: with-memory)
3. Start `wt-loop` in each repo
4. After both complete, collect results and generate comparison report

See `run-guide.md` for detailed, copy-pasteable commands.
