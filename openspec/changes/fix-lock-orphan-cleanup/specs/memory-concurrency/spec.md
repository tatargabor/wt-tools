## MODIFIED Requirements

### Requirement: Lock timeout
The lock timeout scenario now includes stale-lock recovery as a fallback before failing.

#### Scenario: Lock timeout
- **WHEN** a lock cannot be acquired within 10 seconds
- **THEN** the command SHALL check for stale locks (dead PID or age > 60s) before failing
- **AND** if a stale lock is found, remove it and retry acquisition once
- **AND** if retry also fails, the command SHALL fail with a non-zero exit code
- **AND** an error message SHALL be logged
