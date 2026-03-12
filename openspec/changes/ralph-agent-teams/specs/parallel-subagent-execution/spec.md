## ADDED Requirements

### Requirement: Parallel prompt template
The system SHALL provide a prompt template that instructs Claude to partition tasks and spawn parallel subagents when `execution_mode` is `parallel`.

#### Scenario: Prompt instructs task partitioning
- **WHEN** `build_prompt()` is called with `execution_mode=parallel`
- **AND** `detect_next_change_action()` returns `apply:*`
- **THEN** the prompt SHALL instruct the main Claude session to:
  1. Read the unchecked tasks from tasks.md
  2. Partition them into N contiguous groups (N = `parallel_workers`)
  3. Spawn N parallel `Agent` tool calls, one per group
  4. Wait for all agents to complete
  5. Spawn a review agent to verify spec compliance
  6. Fix trivial gaps and commit

#### Scenario: Worker subagent prompt content
- **WHEN** the main session spawns a worker subagent
- **THEN** the worker prompt SHALL include:
  - The exact task checkbox lines assigned to this worker
  - The relevant spec files for the capabilities being implemented
  - Instruction to read CLAUDE.md first
  - Instruction to implement and commit changes
  - Instruction to NOT modify files outside the assigned task scope
  - The `mode` parameter set to `"bypassPermissions"` or matching the loop's permission mode

#### Scenario: Review subagent prompt content
- **WHEN** all worker subagents complete
- **THEN** the main session SHALL spawn one review agent with:
  - All spec files for the change (from `openspec/changes/<name>/specs/`)
  - Instruction to run `git diff` and compare against spec requirements
  - Instruction to list gaps as a structured report (requirement name, status, gap description)
  - Read-only tools only (`Read`, `Grep`, `Glob`, `Bash`)

#### Scenario: Parallel mode only applies to apply phase
- **WHEN** `detect_next_change_action()` returns `ff:*`
- **AND** `execution_mode` is `parallel`
- **THEN** the prompt SHALL use the standard single-agent ff prompt
- **AND** parallel subagents SHALL NOT be spawned for artifact creation

### Requirement: Task partitioning strategy
The system SHALL partition unchecked tasks into contiguous groups to minimize file conflicts between workers.

#### Scenario: Even partition
- **WHEN** there are 9 unchecked tasks and 3 workers
- **THEN** worker 1 receives tasks 1-3, worker 2 receives tasks 4-6, worker 3 receives tasks 7-9

#### Scenario: Uneven partition
- **WHEN** there are 10 unchecked tasks and 3 workers
- **THEN** worker 1 receives tasks 1-4, worker 2 receives tasks 5-7, worker 3 receives tasks 8-10
- **AND** extra tasks SHALL be distributed to earlier workers

#### Scenario: Fewer tasks than workers
- **WHEN** there are 2 unchecked tasks and 3 workers
- **THEN** only 2 subagents SHALL be spawned (one per task)
- **AND** the third worker SHALL NOT be spawned

### Requirement: Review agent gap detection
The review agent SHALL compare implementation against spec requirements and report gaps.

#### Scenario: All requirements implemented
- **WHEN** the review agent finds all spec requirements have corresponding implementation
- **THEN** it SHALL report "All requirements satisfied" with no gaps

#### Scenario: Missing implementation detected
- **WHEN** the review agent finds a spec requirement without corresponding implementation
- **THEN** it SHALL report the gap with: requirement name, spec file path, and description of what is missing

#### Scenario: Review agent is read-only
- **WHEN** the review agent is spawned
- **THEN** it SHALL NOT have Edit or Write tool access
- **AND** it SHALL only report findings, not fix them
