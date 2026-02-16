## ADDED Requirements

### Requirement: Immediate agent discovery saving during exploration
The explore skill SHALL instruct the agent to save its own non-obvious discoveries immediately during exploration — not just at session end via self-reflection. The "Discover → Save → Tell" ordering SHALL apply: when the agent finds something non-obvious (running commands, reading code, verifying behavior), it saves before summarizing. This supplements (not replaces) the existing session-end self-reflection.

#### Scenario: Agent discovers architecture finding during explore
- **WHEN** the agent investigates the codebase during `/opsx:explore` and discovers a non-obvious pattern (e.g., "the Stop hook only fires memory reminders when .memory marker exists")
- **THEN** the agent saves a Learning memory BEFORE presenting the finding to the user
- **THEN** the session-end self-reflection still runs as a safety net

#### Scenario: Agent verifies behavior and finds a gotcha
- **WHEN** the agent runs test commands during explore and discovers unexpected behavior
- **THEN** the agent saves immediately, does not defer to session-end reflection
