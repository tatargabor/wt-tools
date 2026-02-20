## Requirements

### Requirement: Serialized RocksDB Access
All `wt-memory` operations that open the RocksDB storage SHALL be serialized through a per-project file lock, preventing concurrent access failures.

#### Scenario: Concurrent remember and status calls
- **WHEN** the GUI FeatureWorker polls `wt-memory status --json` while an agent session calls `wt-memory remember`
- **THEN** the second call waits for the first to release the lock before proceeding
- **AND** both calls complete successfully

#### Scenario: Lock file per project
- **WHEN** `wt-memory` is invoked for project "wt-tools"
- **THEN** it acquires a file lock at `/tmp/wt-memory-wt-tools.lock`
- **AND** operations on different projects do NOT contend with each other

#### Scenario: Lock timeout
- **WHEN** a lock cannot be acquired within 10 seconds
- **THEN** the command SHALL check for stale locks (dead PID or age > 60s) before failing
- **AND** if a stale lock is found, remove it and retry acquisition once
- **AND** if retry also fails, the command SHALL fail with a non-zero exit code
- **AND** an error message SHALL be logged

### Requirement: Visible Error Reporting
The `wt-memory` script SHALL log Python errors to a file instead of discarding them, so failures can be diagnosed.

#### Scenario: Python exception during remember
- **WHEN** the shodh-memory `remember()` call raises an exception
- **THEN** the error SHALL be appended to `<storage_path>/wt-memory.log`
- **AND** the command SHALL return a non-zero exit code (unless graceful degradation applies)

#### Scenario: Shodh-memory not installed (graceful degradation)
- **WHEN** shodh-memory is not installed
- **THEN** `remember` SHALL exit 0 silently (no-op)
- **AND** `recall` and `list` SHALL return empty JSON arrays
- **AND** no error SHALL be logged

### Requirement: Banner Suppression Without Grep
The shodh-memory import banner SHALL be suppressed at the Python level, not via shell pipe filtering.

#### Scenario: No banner on stdout
- **WHEN** any `wt-memory` command runs
- **THEN** the `⭐ Love shodh-memory?` banner SHALL NOT appear on stdout or stderr

#### Scenario: Python exit code preserved
- **WHEN** a `wt-memory` command invokes Python internally
- **THEN** the Python process exit code SHALL propagate to the calling shell
- **AND** the exit code SHALL NOT be masked by pipe components
