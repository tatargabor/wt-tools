## REMOVED Requirements

### Requirement: PreToolUse hook for hot-topic Bash commands
**Reason**: The proxy architecture surfaces memory on ALL tool calls unconditionally. Hot-topic pattern matching (regex gating) is no longer needed — every PreToolUse and PostToolUse call gets memory recall regardless of the command content.
**Migration**: The unified handler fires for all supported tools without pattern matching. The `.claude/hot-topics.json` cache and discovery logic are removed.

### Requirement: Hot-topic pattern matching is fast
**Reason**: No pattern matching exists in the proxy architecture. All tool calls get memory.
**Migration**: N/A — replaced by unconditional recall with session-level dedup for performance.

### Requirement: Project-specific hot-topic discovery
**Reason**: Hot-topic discovery was an optimization for selective recall. With unconditional recall, there is nothing to select — all calls get memory.
**Migration**: The SessionStart handler no longer writes `.claude/hot-topics.json`. The `discover_hot_topics()` function is removed.

### Requirement: Generic base patterns are always active
**Reason**: Base patterns were part of the selective recall system. With unconditional recall, there are no patterns to match.
**Migration**: N/A — all commands get memory regardless of content.

## MODIFIED Requirements

### Requirement: Hook deployment includes PreToolUse
The `wt-deploy-hooks` script SHALL include `wt-hook-memory` in PreToolUse hook events with matchers for Read, Edit, Write, Bash, Task, and Grep tools. It SHALL also include PostToolUse matchers for the same tools, plus SubagentStop.

#### Scenario: Deploy adds full proxy hooks
- **WHEN** `wt-deploy-hooks /path/to/project` is called
- **THEN** settings.json SHALL contain PreToolUse entries matching Read, Edit, Write, Bash, Task, Grep
- **AND** SHALL contain PostToolUse entries matching Read, Edit, Write, Bash, Task, Grep
- **AND** SHALL contain a SubagentStop entry
- **AND** all hooks SHALL reference `wt-hook-memory` with the appropriate event argument
- **AND** the timeout SHALL be 5 seconds for all tool hooks
