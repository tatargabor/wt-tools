# wt-tools Modularization Plan

Status: APPROVED (2026-03-07)
Context: Explore session analysis of all major source files

## Problem

Several core scripts are monolithic (1000-3700 lines), making them hard to maintain, test, and develop. The largest offenders:

| File | Lines | Issue |
|------|-------|-------|
| bin/wt-memory | 3,713 | 6 subsystems in 1 file |
| bin/wt-loop | 2,248 | cmd_run() is 759 lines |
| bin/wt-hook-memory | 1,817 | 5 layers in 1 file |
| lib/orchestration/state.sh | 1,597 | config+state+memory+utils grab-bag |
| lib/orchestration/dispatcher.sh | 1,456 | monitor_loop 450+ lines, BASE_BUILD cache duplicated |
| bin/wt-project | 1,224 | deploy_wt_tools() 276-line orchestrator |
| bin/wt-common.sh | 990 | editor subsystem (420 lines) is self-contained |

## Approach

- Extract logical modules into `lib/` subdirectories
- Main scripts become thin dispatchers that `source` lib files
- Backward compatible — no CLI changes, no behavior changes
- Each extracted module gets unit tests

## Extraction Plan

### Phase 1: wt-common.sh editor extract (LOW RISK)

Extract 19 editor functions (420 lines) to `lib/editor.sh`. Only 4 scripts use them (wt-config, wt-work, wt-new, wt-focus). wt-common.sh drops to ~570 lines.

### Phase 2: wt-memory split (MEDIUM RISK, HIGHEST IMPACT)

```
bin/wt-memory              (300)  infra + dispatcher + main()
lib/memory/core.sh         (800)  remember, recall, proactive, list, get, forget, export, import
lib/memory/maintenance.sh  (600)  stats, brain, cleanup, audit, dedup, verify, repair, health
lib/memory/rules.sh        (150)  rules YAML add/list/remove/match
lib/memory/todos.sh        (200)  todo add/list/done/clear
lib/memory/sync.sh         (280)  git-based sync push/pull/status
lib/memory/migrate.sh      (150)  migration framework
lib/memory/ui.sh           (400)  metrics, tui, dashboard, seed
```

Dependencies: All modules use infra functions (resolve_project, get_storage_path, run_with_lock) which stay in the main script.

### Phase 3: wt-hook-memory split (MEDIUM RISK)

```
bin/wt-hook-memory         (250)  dispatcher + setup
lib/hooks/util.sh          (170)  logging, timers, root resolution
lib/hooks/session.sh       (110)  session cache, dedup, context IDs
lib/hooks/memory-ops.sh    (290)  recall, proactive, output formatting
lib/hooks/events.sh        (590)  9 event handlers
lib/hooks/stop.sh          (110)  transcript extraction, metrics flush
```

### Phase 4: wt-loop split (LOW-MEDIUM RISK)

```
bin/wt-loop                (500)  CLI commands + main()
lib/loop/state.sh          (300)  state JSON, token accounting
lib/loop/tasks.sh          (200)  task detection engine (3 modes)
lib/loop/prompt.sh         (250)  prompt generation, change detection
lib/loop/engine.sh         (700)  cmd_run() refactored
```

### Phase 5: Orchestration refactor (MEDIUM RISK)

```
lib/orchestration/config.sh      ( 50)  config/path lookup (from state.sh)
lib/orchestration/state.sh       (400)  jq state operations (core, keep name)
lib/orchestration/orch-memory.sh (200)  orch_remember/recall (from state.sh)
lib/orchestration/utils.sh       (700)  duration, hashing, parsing (from state.sh)
lib/orchestration/builder.sh     (120)  BASE_BUILD health (from dispatcher.sh)
lib/orchestration/monitor.sh     (500)  monitor_loop (from dispatcher.sh)
lib/orchestration/dispatcher.sh  (350)  dispatch/resume/pause (keep name, shrink)
```

Key coupling fix: Extract builder.sh to deduplicate BASE_BUILD_* state between dispatcher and merger.

### Phase 6: wt-project deploy refactor (LOW RISK)

Split deploy_wt_tools() (276 lines) into 5 focused functions:
- deploy_hooks(), deploy_commands(), deploy_skills(), deploy_mcp(), deploy_memory()

## What NOT to touch

- **wt-sentinel** (390 lines) — already well-modularized, score 9/10
- **events.sh** (155 lines) — foundational, pure, zero coupling
- **gui/** — already uses mixins pattern, well-structured
- **MCP server** — keep as single file, simpler deployment

## Coupling hotspots to fix during refactor

1. **dispatcher <-> merger bidirectional** — extract builder.sh, use events for merge queue
2. **watchdog -> dispatcher direct calls** — use event-driven escalation instead
3. **merger -> verifier (5 direct calls)** — acceptable one-way dependency, keep

## Testing strategy

Each extracted lib/ module gets a corresponding test file:
- `tests/unit/test_memory_core.sh` — test remember/recall/forget flows
- `tests/unit/test_memory_sync.sh` — test sync state management
- `tests/unit/test_loop_state.sh` — test state JSON operations
- `tests/unit/test_loop_tasks.sh` — test task detection modes
- `tests/unit/test_hook_session.sh` — test dedup, context IDs
- `tests/unit/test_orch_state.sh` — test jq state operations
- etc.

Tests should source the lib file directly and test functions in isolation.

## Implementation rules

When working on any of the files listed above:
1. Check this plan for the target structure
2. Extract the relevant module FIRST, then make your feature/fix change
3. Keep the main script as a thin dispatcher
4. Add unit tests for the extracted module
5. Run existing integration tests to verify no regressions
