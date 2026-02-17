## Why

MemoryProbe v7 showed +20% convention adherence for memory-enabled runs, but the signal is weak because all 6 conventions are explicitly documented in `project-spec.md` — both modes read the same spec. The benchmark needs trap categories that isolate what memory uniquely provides: human corrections, forward-looking advice, and stale-spec overrides. These simulate real development scenarios where a team lead's feedback is the only source of truth.

## What Changes

- **C02 becomes a "correction" change** — instead of an empty gap, it delivers human feedback that changes conventions mid-project (e.g., error code format switches from SCREAMING_SNAKE to dot.notation)
- **New trap categories** added alongside existing ones:
  - **Human override traps** (convention changes in C02 that conflict with C01 code and project-spec.md)
  - **Forward-looking traps** (advice given in C02 for features that don't exist yet — only memory carries it)
  - **Stale-spec traps** (project-spec.md says X, C02 overrides to Y — tests whether agent follows latest human input or outdated doc)
- **project-spec.md conventions section** becomes partially outdated (reflects C01 state, not C02 corrections)
- **score.sh updated** with weighted scoring: code-readable traps x1, human-override traps x2, forward-looking traps x3
- **Test scripts updated** with probes for new trap categories
- **run-guide.md updated** to recommend n=3 runs with median scoring

## Capabilities

### New Capabilities
- `correction-traps`: Human override and forward-looking trap definitions, C02 change file redesign, probe patterns for new trap categories
- `weighted-scoring`: Trap category weights, updated score.sh comparison output, n=3 run protocol

### Modified Capabilities

## Impact

- `benchmark/synthetic/changes/02-tags-filtering.md` — major rewrite (adds Developer Notes section)
- `benchmark/synthetic/project-spec.md` — conventions section stays but becomes intentionally stale after C02
- `benchmark/synthetic/tests/test-03.sh` through `test-05.sh` — new probes for correction traps
- `benchmark/synthetic/scripts/score.sh` — weighted scoring, new probe patterns
- `benchmark/synthetic/scoring-rubric.md` — new trap documentation
- `benchmark/synthetic/run-guide.md` — n=3 protocol
