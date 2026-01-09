# Tasks: Ralph Loop Integration

## Phase 1: Core Loop (MVP)

- [x] Create wt-loop bash script
  - [x] Argument parsing (change-id, task, options)
  - [x] Loop logic (while iteration < max && !done)
  - [x] Claude invocation with prompt
  - [x] State file updates between iterations
  - [x] Exit handling (done, stuck, stopped, cost_limit)

- [x] Implement loop state file (.claude/loop-state.json)
  - [x] Initial state creation
  - [x] Iteration tracking
  - [x] Status updates
  - [x] Capacity tracking per iteration (use wt-usage helper)

- [x] Implement tasks.md done detection
  - [x] Find tasks.md in worktree
  - [x] Parse `- [ ]` and `- [x]` patterns
  - [x] Return true when all checked

- [x] Terminal spawning
  - [x] gnome-terminal support
  - [x] Write PID to ralph-terminal.pid
  - [x] Window title with change-id
  - [x] Terminal output logging to .claude/ralph-loop.log
  - [x] Fullscreen option (--fullscreen flag + config)

- [x] Basic CLI commands
  - [x] `wt-loop start` - Start new loop
  - [x] `wt-loop stop` - Stop running loop
  - [x] `wt-loop status` - Show loop status
  - [x] `wt-loop list` - List all active loops

## Phase 2: GUI Integration

- [x] Support multiple icons in integrations column (J, R)
  - [x] Color coding per icon type
  - [x] Side-by-side layout

- [x] Add Ralph icon states
  - [x] R (green) = running
  - [x] R (red) = stuck
  - [x] R (blue) = done
  - [x] R (gray) = stopped
  - [x] Process liveness check (detect closed terminal)

- [x] Extend row context menu
  - [x] "Start Ralph Loop..." menu item with dialog
  - [x] "View Terminal" menu item (when running)
  - [x] "View Log" menu item (when finished)
  - [x] "Stop Loop" menu item
  - [x] Status display in menu

- [x] Implement focus terminal action
  - [x] Read PID from ralph-terminal.pid
  - [x] Use xdotool to find and activate window
  - [x] Fallback to View Log if terminal closed

- [x] Add Ralph settings tab in Settings dialog
  - [x] Terminal fullscreen checkbox
  - [x] Default max iterations spinbox

- [x] Add Ralph status tooltip
  - [x] Show iteration, status, task
  - [x] Hover on R icon triggers tooltip

## Phase 3: Skill Integration

- [x] Create /wt:loop skill command
  - [x] Command file created (.claude/commands/wt/loop.md)
  - [x] Documentation for options
  - [x] Usage examples

- [x] Status display in initiating terminal
  - [x] Periodic state file reading
  - [x] Output iteration updates
  - [x] Show final status (done/stuck)

- [x] Start Ralph Loop dialog (GUI)
  - [x] Task description text area
  - [x] Done criteria dropdown
  - [x] Max iterations spinner
  - [x] Cost limit input
  - [ ] Auto-PR checkbox (future)
  - [ ] Auto-JIRA checkbox (future)
  - [ ] Cost estimation display (future)

## Phase 4: Capacity Tracking (NOT IMPLEMENTED)

> **Note:** Capacity limit is stored in loop-state.json but NOT enforced yet.
> The `--capacity-limit` option is accepted but has no effect currently.

- [ ] Per-iteration capacity tracking
  - [ ] Read capacity from GUI Usage API after each iteration
  - [ ] Store capacity % in loop-state.json
  - [ ] Calculate running total

- [ ] Capacity limit enforcement
  - [ ] Check block capacity % after each iteration
  - [ ] Stop loop if limit exceeded (e.g., >80%)
  - [ ] Set status to "capacity_limit"

- [ ] Usage display integration
  - [ ] Show current 5h block usage before starting
  - [ ] Estimate capacity usage after loop
  - [ ] Warn if will exceed limits

## Future Enhancements (Out of Scope v1)

- [ ] Additional done criteria (tests, no-todos, custom script)
- [ ] Stuck detection (same error 3x)
- [ ] Auto-PR creation when done
- [ ] Auto-JIRA time logging
- [ ] Prompt templates directory
- [ ] Resume with modified prompt
- [ ] Multi-loop orchestration
