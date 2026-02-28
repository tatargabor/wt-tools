## ADDED Requirements

### Requirement: Conflict fingerprint deduplication
The orchestrator SHALL detect repeating identical merge conflicts and stop retrying early to avoid wasting merge attempts on unresolvable conflicts.

#### Scenario: Fingerprint computed on merge failure
- **WHEN** a merge attempt fails for a change
- **THEN** the orchestrator SHALL compute a conflict fingerprint by:
  1. Running `git merge-tree` between the merge base, origin/main, and the source branch
  2. Extracting conflicted file paths (`+++ b/` lines)
  3. Sorting and computing an md5 hash
- **AND** store the fingerprint as `last_conflict_fingerprint` in the change state

#### Scenario: Same fingerprint detected — stop retrying
- **WHEN** a merge retry produces a conflict fingerprint
- **AND** the fingerprint matches `last_conflict_fingerprint` from the previous attempt
- **THEN** the orchestrator SHALL stop retrying immediately
- **AND** set status to `merge-blocked`
- **AND** send a critical notification: "Merge permanently blocked: {name} (same conflict repeating)"

#### Scenario: Different fingerprint — continue retrying
- **WHEN** a merge retry produces a conflict fingerprint
- **AND** the fingerprint differs from the previous attempt
- **THEN** the orchestrator SHALL update `last_conflict_fingerprint`
- **AND** continue with the normal retry logic (up to MAX_MERGE_RETRIES)

### Requirement: Maximum merge retry limit
The orchestrator SHALL limit merge retry attempts per change to prevent infinite retry loops.

#### Scenario: Retry limit reached
- **WHEN** `merge_retry_count` reaches `MAX_MERGE_RETRIES` (default: 5)
- **THEN** the orchestrator SHALL stop retrying
- **AND** log an error: "Merge failed after {N} attempts for {name} — giving up"
- **AND** send a critical notification
- **AND** save a Decision memory noting the permanent failure

#### Scenario: Retry with main branch sync
- **WHEN** a merge retry is attempted
- **THEN** the orchestrator SHALL first fetch and merge origin/main into the change branch
- **AND** then attempt the merge again
