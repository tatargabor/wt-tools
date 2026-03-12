## Why

Ralph loop iterációk lassúak és a spec-hűség gyenge — egyetlen agent dolgozik szekvenciálisan a taskokon, a verify gate utólag sem mindig kapja el a kimaradt implementációkat. A Claude Code párhuzamos subagent-ek (`Agent` tool) stabilan működnek `-p` mode-ban, tesztelve. Ez lehetővé teszi hogy egy iteráción belül 2-3 agent párhuzamosan dolgozzon, csökkentve az iteráció-időt és javítva a spec-hűséget beépített peer review-val.

## What Changes

- Ralph engine prompt-ot módosítjuk: az agent task-csoportokra bontja az OpenSpec task-okat és párhuzamos subagent-eket spawnol
- Új `execution_mode` config: `single` (mai viselkedés) vagy `parallel` (subagent-es)
- Prompt builder kiegészül a párhuzamos instrukcióval: task-partícionálás, subagent spawn, eredmény-összesítés, peer review
- A loop infra (state machine, watchdog, budget, token tracking, session mgmt) változatlan marad

## Capabilities

### New Capabilities
- `parallel-subagent-execution`: Ralph iteráción belüli párhuzamos subagent spawn — task partícionálás, subagent prompt generálás, eredmény összesítés, peer review instrukció

### Modified Capabilities
- `ralph-loop`: Új `execution_mode` field a loop state-ben, prompt builder módosítás parallel mode-hoz
- `dispatch-and-loop-control`: `wt-loop start` kap `--parallel` flag-et, orchestrator config-ból is olvasható

## Impact

- `lib/loop/engine.sh`: prompt építés módosítása (build_prompt)
- `lib/loop/prompt.sh`: új parallel prompt template
- `lib/loop/state.sh`: execution_mode field a state JSON-ben
- `bin/wt-loop`: --parallel CLI flag
- `lib/orchestration/dispatcher.sh`: parallel mode átadás a ralph loop-nak
- Token cost növekedés: ~2-3x per iteráció (de kevesebb iteráció szükséges)
