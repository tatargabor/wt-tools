# worktree-tools Specification

## ADDED Requirements

### Requirement: Ralph Loop Management

The system SHALL provide CLI commands for managing autonomous Claude Code loops (Ralph loops).

#### Scenario: Start a new loop

- **GIVEN** a worktree with a change-id exists
- **WHEN** user runs `wt-loop start <change-id> "task description"`
- **THEN** a new terminal window opens running the Ralph loop
- **AND** loop state is created in `.claude/loop-state.json`
- **AND** the terminal PID is saved to `.claude/ralph-terminal.pid`

#### Scenario: Start with options

- **GIVEN** a worktree exists
- **WHEN** user runs `wt-loop start <change-id> "task" --max 10 --done tasks`
- **THEN** the loop runs for maximum 10 iterations
- **AND** uses tasks.md completion as done criteria

#### Scenario: Start with fullscreen terminal

- **GIVEN** fullscreen is enabled in config or via flag
- **WHEN** user runs `wt-loop start <change-id> "task" --fullscreen`
- **THEN** the terminal opens in fullscreen mode

#### Scenario: Check loop status

- **GIVEN** a loop is running or has completed
- **WHEN** user runs `wt-loop status [change-id]`
- **THEN** current status is displayed (running/done/stuck/stopped)
- **AND** iteration count and capacity info are shown

#### Scenario: Stop a running loop

- **GIVEN** a loop is running
- **WHEN** user runs `wt-loop stop <change-id>`
- **THEN** the loop process is terminated gracefully
- **AND** loop state is updated to "stopped"

#### Scenario: List all active loops

- **GIVEN** one or more loops are active across projects
- **WHEN** user runs `wt-loop list`
- **THEN** all active loops are listed with project, change-id, status, and iteration

### Requirement: Loop State File

The system SHALL maintain loop state in a JSON file.

#### Scenario: State file structure

- **GIVEN** a loop is started
- **WHEN** the loop runs
- **THEN** `.claude/loop-state.json` contains:
  - change_id, task, done_criteria
  - max_iterations, current_iteration
  - status (running/done/stuck/stopped)
  - terminal_pid, started_at
  - iterations array with per-iteration details

#### Scenario: Iteration tracking

- **GIVEN** a loop completes an iteration
- **WHEN** the iteration ends
- **THEN** the iterations array is updated with:
  - iteration number, start/end time
  - exit_reason, commits made
  - done_check result

### Requirement: Done Detection

The system SHALL support multiple methods to detect loop completion.

#### Scenario: Tasks.md completion

- **GIVEN** done criteria is "tasks"
- **WHEN** checking if done
- **THEN** loop is done when all `- [ ]` in tasks.md become `- [x]`

#### Scenario: Manual done

- **GIVEN** done criteria is "manual"
- **WHEN** checking if done
- **THEN** loop continues until user stops it manually

### Requirement: Loop Output Logging

The system SHALL log all loop output.

#### Scenario: Log file creation

- **GIVEN** a loop is started
- **WHEN** the loop runs
- **THEN** all output is logged to `.claude/ralph-loop.log`

#### Scenario: View log after completion

- **GIVEN** a loop has finished
- **WHEN** user wants to review the session
- **THEN** the log file contains full terminal output for all iterations
