## Context

V5 benchmark ran two Claude Code Opus 4.6 instances building the same 12-change CraftBazaar marketplace:
- **Run A** (baseline): no memory system
- **Run B** (memory): shodh-memory integration with code map hooks

V5 added 4 new convention traps (TRAP-H/I/J/K) on top of v4's 5 traps (A/B/D/E/F/G). Both runs completed C01-C09 in 18 iterations each, then continued for C10-C12 after a glob bug fix. The analysis must score both runs, compare with v4, and identify actionable improvements.

**Key data sources:**
- `~/benchmark/run-a/craftbazaar/` — baseline codebase, git history, results JSONs
- `~/benchmark/run-b/craftbazaar/` — memory codebase, git history, results JSONs, shodh-memory store
- `benchmark/scoring-rubric.md` — scoring dimensions and trap definitions
- `benchmark/changes/*.md` — change definitions with evaluator notes
- `benchmark/v4-results.md` — previous version for comparison

## Goals / Non-Goals

**Goals:**
- Produce `benchmark/v5-results.md` with complete per-change scoring, trap analysis, memory quality audit
- Compare v4→v5 on all metrics (traps, iterations, tokens, memory quality)
- Score TRAP-H/I/J/K (new convention traps) across all changes
- Identify top 3-5 actionable improvements for memory system
- Determine if code map memories provided measurable value

**Non-Goals:**
- Transcript-level annotation (too time-intensive, save for focused deep-dives)
- Implementing fixes — this is analysis only
- Re-running the benchmark

## Decisions

### 1. Analysis structure: Follow v4-results.md format + add convention trap section

**Rationale**: Consistency with v4 allows direct comparison. Add a new "Convention Traps" section for the v5-specific H/I/J/K analysis.

### 2. Data extraction: automated code inspection over transcript review

**Rationale**: For trap compliance, inspecting the actual generated code (grep for formatPrice, errors.ts imports, deletedAt filters, pagination format) is faster and more reliable than reading transcripts. Reserve transcript review for ambiguous cases only.

### 3. Per-change iteration counting: use wt-loop history + git log timestamps

**Rationale**: `wt-loop history` gives per-iteration token counts. Git log gives commit timestamps per change. Together they map iterations to changes.

### 4. Memory quality: categorize by utility, not just type

Categories:
- **High value**: memories that demonstrably influenced agent behavior (visible in code output)
- **Medium value**: correct information that COULD help but no evidence it was recalled/used
- **Low value / noise**: proactive-context status updates, "no errors" reflections, duplicates

## Risks / Trade-offs

- **[Incomplete C10-C12 data]** → If runs haven't finished C11-C12 yet, document partial results and note what's missing. Can be updated later.
- **[Trap scoring subjectivity]** → Use binary PASS/FAIL where possible (code inspection). For partial cases, document exactly what passed and what failed.
- **[Memory recall attribution]** → Hard to prove a memory "caused" better code. Use counterfactual: "Run A did X, Run B did Y, Run B had memory Z about this topic."
