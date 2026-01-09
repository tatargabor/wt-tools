## MODIFIED Requirements

### Requirement: Cross-Platform Support
The system SHALL work on Linux, macOS, and Windows. All shell scripts SHALL use platform-appropriate system calls for process inspection and file metadata queries.

#### Scenario: Platform detection
- **WHEN** any tool script is executed
- **THEN** the current platform is detected
- **AND** platform-specific paths and commands are used

#### Scenario: Windows Git Bash
- **WHEN** tools are used from Git Bash on Windows
- **THEN** POSIX shell scripts work correctly

#### Scenario: Agent status detection on macOS
- **WHEN** `wt-status` runs on macOS (Darwin)
- **AND** a Claude process is running in a worktree
- **THEN** the process working directory SHALL be resolved using `lsof`
- **AND** the file modification time SHALL be resolved using BSD `stat -f`
- **AND** the correct agent status (running, waiting, compacting) SHALL be returned

#### Scenario: Agent status detection on Linux
- **WHEN** `wt-status` runs on Linux
- **AND** a Claude process is running in a worktree
- **THEN** the process working directory SHALL be resolved using `/proc/$pid/cwd`
- **AND** the file modification time SHALL be resolved using GNU `stat -c`
- **AND** the correct agent status (running, waiting, compacting) SHALL be returned

#### Scenario: No Claude processes running
- **WHEN** `wt-status` runs on any supported platform
- **AND** no Claude processes are found
- **THEN** the agent status SHALL be "idle"

#### Scenario: Cross-platform helper functions
- **WHEN** shell scripts need process working directory or file modification time
- **THEN** they SHALL use shared helper functions from `wt-common.sh`
- **AND** the helpers SHALL abstract platform differences internally
