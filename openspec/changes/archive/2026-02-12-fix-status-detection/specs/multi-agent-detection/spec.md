## MODIFIED Requirements

### Requirement: Multi-Agent Detection
The system SHALL detect ALL Claude agent processes associated with a worktree, not just the first one found.

#### Scenario: Single agent on worktree
- **WHEN** one Claude process has its CWD in a worktree directory
- **THEN** `wt-status --json` returns an `agents` array with one entry containing `pid`, `status`, and `skill`

#### Scenario: Multiple agents on worktree
- **WHEN** two or more Claude processes have their CWD in the same worktree directory
- **THEN** `wt-status --json` returns an `agents` array with one entry per process, each with its own `pid`, `status`, and `skill`

#### Scenario: No agents on worktree
- **WHEN** no Claude process has its CWD in a worktree directory
- **THEN** `wt-status --json` returns an empty `agents` array `[]`

#### Scenario: Per-agent status determination
- **WHEN** multiple agents exist on a worktree
- **THEN** each agent's status (running/waiting) is determined independently using the N most recently modified session files matched to PIDs by mtime order

### Requirement: Multi-Agent JSON Format
The `wt-status --json` output SHALL use an `agents` array instead of a single `agent` object.

#### Scenario: JSON format with agents array
- **WHEN** `wt-status --json` is called
- **THEN** each worktree object contains `"agents": [{"pid": <int>, "status": "<status>", "skill": <string|null>}, ...]` instead of `"agent": {"status": "<status>", "skill": <string|null>}`

#### Scenario: Summary counts reflect agent count
- **WHEN** `wt-status --json` produces the summary object
- **THEN** the `running`, `waiting`, and `idle` counts reflect the total number of agents in each state across all worktrees (not worktree count)
- **AND** the summary SHALL include `compacting: 0` for backward compatibility

## REMOVED Requirements

### Requirement: Compacting status detection
**Reason**: Compacting detection used unreliable text pattern matching on session JSONL files, causing false positives. The compacting state is transient (2-5 seconds) and functionally equivalent to "running" from the user's perspective. Agents that are compacting context now report as "running".
**Migration**: Any consumers checking for `status == "compacting"` should treat it as `"running"`. The JSON summary field `compacting` will always be `0`.
