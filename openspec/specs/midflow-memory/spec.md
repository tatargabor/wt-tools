# midflow-memory Specification

## Purpose
TBD - created by archiving change proactive-memory. Update Purpose after archive.
## Requirements
### Requirement: Mid-flow remember during apply
During `/opsx:apply` execution, the agent SHALL recognize when the user provides corrections, warnings, or contextual knowledge between tasks and save them immediately — not waiting for step 7. The step 7 remember block SHALL remain for implementation-level learnings (errors, patterns, completion events). Mid-flow saves cover user-provided knowledge.

#### Scenario: User corrects approach during implementation
- **WHEN** user says "ne csináld így, használd inkább X-et" or "don't do it that way, use X instead" during apply
- **THEN** the agent saves a Decision or Observation memory immediately, then adjusts implementation

#### Scenario: User shares context about a dependency
- **WHEN** user says "az a library 2.0-ban breaking change volt" or "that library had a breaking change in v2.0"
- **THEN** the agent saves a Learning memory immediately with the library name as tag

#### Scenario: User doesn't interrupt — no unnecessary saves
- **WHEN** user says "ok" or "jó, folytasd" or "looks good, continue"
- **THEN** the agent does NOT save anything, just continues implementing

### Requirement: Mid-flow remember during continue and ff
The `/opsx:continue` and `/opsx:ff` skills SHALL also recognize and save user-provided knowledge mid-flow, using the same recognition logic as apply.

#### Scenario: User corrects during artifact creation
- **WHEN** user says "ne vegyél fel breaking change-et a proposal-ba" during continue/ff
- **THEN** the agent saves a Decision memory and adjusts the artifact being created

### Requirement: Language-independent recognition
All mid-flow recognition SHALL work regardless of the user's language. The agent SHALL recognize intent patterns (negation of past approach, expression of constraint, sharing of technical fact) rather than matching specific keywords in any language.

#### Scenario: Hungarian user shares learning
- **WHEN** user says "a Qt plugin path-ot mindig exportálni kell Linux-on"
- **THEN** the agent recognizes this as a Learning about Qt/Linux setup and saves it

#### Scenario: Mixed-language conversation
- **WHEN** user mixes languages (e.g., "a Redis-t ne, az too slow volt last time")
- **THEN** the agent still recognizes and saves the learning correctly

