### Requirement: Memory helper functions
The orchestrator SHALL provide helper functions for saving and recalling memories with consistent tagging.

#### Scenario: orch_remember saves with orchestrator tag
- **WHEN** `orch_remember "content" [type] [extra,tags]` is called
- **THEN** the orchestrator SHALL invoke `wt-memory remember` with tags `source:orchestrator,{extra_tags}`
- **AND** return 0 regardless of wt-memory success/failure (graceful degradation)
- **AND** track operation timing for performance stats

#### Scenario: orch_recall retrieves memories
- **WHEN** `orch_recall "query" [limit] [tag_filter]` is called
- **THEN** the orchestrator SHALL invoke `wt-memory recall` in hybrid mode
- **AND** return plain text (max 2000 chars) or empty string if wt-memory unavailable

### Requirement: Merge outcome memories
The orchestrator SHALL save memories for merge events.

#### Scenario: Successful merge
- **WHEN** a change is merged successfully
- **THEN** the orchestrator SHALL save a Context memory with tags `phase:merge,change:{name}` containing change name and iteration count

#### Scenario: Merge conflict
- **WHEN** a merge conflict occurs (first time)
- **THEN** the orchestrator SHALL save a Decision memory with tags `phase:merge,change:{name}` noting the conflict

#### Scenario: Permanent merge failure
- **WHEN** a merge fails after MAX_MERGE_RETRIES attempts
- **THEN** the orchestrator SHALL save a Decision memory noting the permanent failure

### Requirement: Test and review outcome memories
The orchestrator SHALL save memories for quality gate results.

#### Scenario: Test pass
- **WHEN** tests pass for a change
- **THEN** the orchestrator SHALL save a Context memory with tags `phase:test,change:{name}`

#### Scenario: Test failure
- **WHEN** tests fail for a change
- **THEN** the orchestrator SHALL save a Learning memory with tags `phase:test,change:{name}` including the first 500 chars of test output

#### Scenario: Review pass
- **WHEN** code review passes with no critical issues
- **THEN** the orchestrator SHALL save a Context memory with tags `phase:review,change:{name}`

#### Scenario: Review critical issues
- **WHEN** code review finds CRITICAL issues
- **THEN** the orchestrator SHALL save a Learning memory with tags `phase:review,change:{name}` including the first 500 chars of review output

### Requirement: Stall and failure event memories
The orchestrator SHALL save memories when changes stall or fail permanently.

#### Scenario: Change stall (give-up)
- **WHEN** a change's stall_count exceeds 3 and is marked `failed`
- **THEN** the orchestrator SHALL save a Learning memory with tags `phase:monitor,change:{name}`

#### Scenario: Terminal process death
- **WHEN** a terminal process dies without producing loop-state
- **THEN** the orchestrator SHALL save a Learning memory noting the failure

### Requirement: Per-roadmap-item recall during planning
The orchestrator SHALL recall relevant memories for each roadmap item during plan decomposition.

#### Scenario: Brief mode planning recall
- **WHEN** generating a plan in brief mode
- **THEN** the orchestrator SHALL recall memories for each Next item's scope text (limit 2, no tag filter)
- **AND** additionally recall orchestrator operational history with tags `source:orchestrator` (limit 3)
- **AND** inject combined results as `## Project Memory` section (max 2000 chars)

#### Scenario: Spec mode planning recall
- **WHEN** generating a plan in spec mode
- **THEN** the orchestrator SHALL recall using the phase hint or general query (limit 3)
- **AND** additionally recall orchestrator operational history

### Requirement: Replan recalls operational history
The auto-replan cycle SHALL inject past orchestrator experience into the replanning prompt.

#### Scenario: Replan memory injection
- **WHEN** `auto_replan_cycle()` re-runs planning
- **THEN** the orchestrator SHALL recall "orchestration merge conflict test failure review" with tags `source:orchestrator` (limit 5)
- **AND** inject as `## Orchestration History` section

### Requirement: Dispatch enriches proposal with memories
The dispatch step SHALL append relevant memories to the pre-created proposal.

#### Scenario: Memory-enriched proposal
- **WHEN** dispatching a change
- **THEN** the orchestrator SHALL recall memories for the change scope (limit 3, no tag filter)
- **AND** if non-empty, append a `## Context from Memory` section to proposal.md (max 1000 chars)

### Requirement: Gate timing and cost tracking
The verify gate SHALL track timing and token costs for each quality check step.

#### Scenario: Per-gate timing
- **WHEN** a verify gate step runs (test, build, review, verify)
- **THEN** the orchestrator SHALL record elapsed milliseconds: `gate_test_ms`, `gate_build_ms`, `gate_review_ms`, `gate_verify_ms`, `gate_total_ms`

#### Scenario: Retry token cost tracking
- **WHEN** a verify retry is initiated
- **THEN** the orchestrator SHALL snapshot current `total_tokens` as `retry_tokens_start`
- **AND** after retry completes, compute diff and accumulate in `gate_retry_tokens`
- **AND** increment `gate_retry_count`

### Requirement: Periodic memory audit
The orchestrator SHALL periodically check memory system health during monitoring.

#### Scenario: Memory audit every ~10 polls
- **WHEN** the monitor loop has completed a multiple of 10 poll cycles
- **THEN** the orchestrator SHALL check wt-memory health, log orchestrator memory count
- **AND** run gate cost stats summary
- **AND** log warnings if memory system is unhealthy (non-blocking)
