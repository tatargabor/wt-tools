## Context

The Ralph loop executes one Claude Code session per iteration via `echo "$prompt" | claude -p`. Each iteration runs a single agent that works through OpenSpec tasks sequentially. The `build_prompt()` function in `lib/loop/prompt.sh` constructs the prompt, which either invokes `/opsx:ff` (artifact creation) or `/opsx:apply` (implementation).

Testing confirmed:
- **Parallel subagents (`Agent` tool) work in `-p` mode** — 2 agents completed in ~7s, stdout output parseable
- **Agent Teams (`TeamCreate`/`SendMessage`) do NOT work in `-p` mode** — 0 byte stdout, requires interactive terminal, session resume not supported with teammates
- The Ralph engine's claude invocation (`echo | claude -p --resume`) does not need to change — only the **prompt content** changes

## Goals / Non-Goals

**Goals:**
- Enable parallel task execution within a single Ralph iteration via Claude Code subagents
- Reduce iteration wall-clock time by 2-3x through parallelism
- Improve spec-compliance by adding a review subagent that verifies work against specs
- Make parallelism opt-in per loop (`--parallel`) and per orchestration config (`execution_mode`)
- Keep all existing Ralph infra unchanged (state machine, watchdog, budget, session mgmt)

**Non-Goals:**
- Replacing the Ralph loop with Agent Teams (tested — doesn't work in `-p` mode)
- Changing how the orchestrator dispatches or manages changes
- Modifying the `/opsx:apply` or `/opsx:ff` skills themselves
- Auto-detecting optimal parallelism level (fixed config, user decides)

## Decisions

### 1. Subagents via prompt instruction, not code change

The Ralph engine invokes `echo "$prompt" | claude -p`. In parallel mode, the prompt instructs the main Claude session to:
1. Read tasks.md and partition unchecked tasks into N groups
2. Spawn N parallel `Agent` tool calls, each implementing its task group
3. Spawn 1 review agent that reads the specs and verifies all changes
4. Commit results

**Why:** Zero change to engine.sh invocation. The parallelism is entirely prompt-driven — the main session orchestrates subagents natively.

**Alternative considered:** Modifying engine.sh to spawn multiple `claude -p` processes directly. Rejected because it requires custom coordination code, loses session context, and duplicates what the Agent tool already does.

### 2. Parallel mode only for `apply`, not `ff`

The `/opsx:ff` artifact creation phase is inherently sequential (proposal → design → specs → tasks). Parallelism only applies to the `apply` phase where independent implementation tasks can run concurrently.

**Why:** FF artifacts have dependency chains. Parallelizing them would require the main agent to understand artifact ordering — complexity with no benefit since FF is already fast (~2-5 min).

### 3. Task partitioning strategy: contiguous groups

Tasks are partitioned into contiguous groups from tasks.md rather than interleaved. E.g., with 9 tasks and 3 workers: worker 1 gets tasks 1-3, worker 2 gets 4-6, worker 3 gets 7-9.

**Why:** Contiguous tasks are more likely to touch related files, reducing merge conflicts between workers. OpenSpec tasks.md is already ordered by feature/module. Interleaving would increase the chance of workers editing the same files.

**Alternative considered:** Dependency-aware partitioning (parse task descriptions for file overlap). Rejected — too complex for v1, contiguous groups are a good heuristic.

### 4. Review agent as final step

After all worker agents complete, the prompt instructs the main session to spawn one more `Agent` tool call: a reviewer that reads the OpenSpec specs and verifies the implementation matches.

**Why:** This addresses the core spec-compliance problem. The reviewer has fresh context (no implementation bias), reads the specs directly, and reports gaps before the iteration ends. The main agent can fix minor issues or flag them for the next iteration.

### 5. Configuration: loop state field + CLI flag

New field in `loop-state.json`:
```json
{
  "execution_mode": "parallel",
  "parallel_workers": 3
}
```

CLI: `wt-loop start "task" --parallel [--workers N]`

Orchestrator config: `execution_mode: parallel` in `orchestration.yaml` per-change or global.

**Why:** Backward-compatible — default remains `single`. The orchestrator can override per-change for fine-grained control.

### 6. Worker subagent prompt template

Each worker subagent receives:
- The relevant task group (exact checkbox lines from tasks.md)
- The spec files for the capabilities being implemented
- Instruction to implement, commit, and report what was done
- Explicit instruction to NOT modify files outside its task scope

The review agent receives:
- All spec files for the change
- Instruction to `git diff` against the spec requirements
- Report format: list of gaps (missing implementations, deviations)

**Why:** Scoped context per worker reduces confusion and cross-contamination. The review agent has clean spec context without implementation bias.

## Risks / Trade-offs

**[Token cost ~2-3x per iteration]** → Each subagent builds its own context window. Mitigation: fewer iterations needed overall (parallel + review catches gaps early). Net cost may be neutral or slightly higher.

**[File conflicts between parallel workers]** → Two workers editing the same file can cause conflicts. Mitigation: contiguous task partitioning reduces overlap; the main agent resolves conflicts after workers complete; `--workers 2` is a safe default.

**[Subagent context is limited]** → Workers don't see the full project context, only their task group + specs. Mitigation: include CLAUDE.md in each worker prompt; the main agent can fix integration issues post-merge.

**[Subagent failures are silent]** → If a worker crashes or produces garbage, the main agent may not detect it. Mitigation: the review agent catches missing implementations; the main agent should verify each worker produced commits.

**[Session resume + parallel]** → On session resume, the continuation prompt ("Continue where you left off") may not re-invoke parallel mode. Mitigation: the resume prompt should detect parallel mode from state and re-apply the parallel instruction.

## Open Questions

- What's the optimal default worker count? 2 is safe, 3 is faster but higher conflict risk. Need empirical data from real runs.
- Should the review agent have edit permissions to fix trivial gaps, or only report? Starting with report-only is safer.
- How does token tracking work with subagents? The `wt-usage` API should capture all tokens in the session, but needs verification.
