## ADDED Requirements

### Requirement: Agent discovery saving during apply, continue, and ff
The apply, continue, and ff skills SHALL instruct the agent to save its own non-obvious discoveries immediately during implementation and artifact creation — not just user-shared knowledge. When the agent encounters unexpected errors, discovers non-obvious patterns, or finds environment quirks while working, it SHALL save BEFORE continuing. This uses the "Discover → Save → Tell" ordering.

#### Scenario: Agent discovers error workaround during apply
- **WHEN** the agent encounters an unexpected error during `/opsx:apply` and figures out a workaround
- **THEN** the agent saves the error + workaround as a Learning memory IMMEDIATELY (not deferred to step 7)
- **THEN** the agent continues with implementation

#### Scenario: Agent discovers codebase pattern during ff
- **WHEN** the agent researches the codebase during `/opsx:ff` artifact creation and finds a non-obvious convention
- **THEN** the agent saves a Learning memory BEFORE writing it into the artifact
