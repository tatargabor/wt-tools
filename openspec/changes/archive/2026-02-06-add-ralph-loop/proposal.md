# Proposal: Ralph Loop Integration

JIRA Key: TBD
Story: TBD

## Summary

Ralph Wiggum-style autonomous loop integration into the wt skill. The agent automatically iterates on a task until a "done" criterion is met or max iteration limit is reached.

## Motivation

Currently, when an agent finishes a step and exits, it needs to be manually restarted with context. This interrupts the flow and requires developer intervention.

The Ralph approach:
- Agent automatically restarts on exit
- Sees previous changes
- Iterates until task is complete

Geoffrey Huntley built an entire programming language this way in 3 months, with $297 in API costs.

## Architecture Decision: Wrapper Script

**Chosen approach:** Wrapper script in a separate terminal window (not nohup).

```
┌─────────────────────────────────────────────────────────────────┐
│  ZED Editor                                                      │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  Claude Code (initiating) - Terminal Tab                    │ │
│  │  > /wt:loop add-auth "Implement auth" --max 10              │ │
│  │                                                              │ │
│  │  🔄 Ralph loop started in separate terminal                 │ │
│  │  Status: Running | Iteration: 3/10 | Capacity: 45%          │ │
│  │  Terminal PID: 12345                                         │ │
│  │                                                              │ │
│  │  [View Terminal] [Stop Loop]                                │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  Ralph Terminal (spawned) - Separate Window                 │ │
│  │  === Iteration 3/10 ===                                     │ │
│  │  Running Claude Code...                                      │ │
│  │  [claude output here]                                        │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

**Why wrapper instead of hook:**
- Full control over the loop
- Visible in separate terminal what's happening
- Easy debug and manual intervention
- No hook infinite loop risk

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│  1. User runs /wt:loop from Zed terminal (initiating Claude) │
├─────────────────────────────────────────────────────────────┤
│  2. Skill spawns new terminal window with wt-loop script     │
│     - gnome-terminal / xterm / kitty                         │
│     - Writes PID to loop-state.json                          │
│     - Initiating Claude shows status in output               │
├─────────────────────────────────────────────────────────────┤
│  3. wt-loop runs Claude in a loop:                           │
│     while iteration < max && !done:                          │
│       - Build prompt with context                            │
│       - Run claude --dangerously-skip-permissions            │
│       - Wait for exit                                        │
│       - Check done criteria                                  │
│       - Update state file                                    │
│       - iteration++                                          │
├─────────────────────────────────────────────────────────────┤
│  4. Loop ends when:                                          │
│     - Done criteria met → status: done                       │
│     - Max iterations reached → status: stuck                 │
│     - User stops manually → status: stopped                  │
│     - Capacity limit exceeded → status: capacity_limit       │
├─────────────────────────────────────────────────────────────┤
│  5. Notification sent to user                                │
│     - Desktop notification                                   │
│     - Control Center GUI update                              │
│     - Initiating Claude status update (if still running)     │
└─────────────────────────────────────────────────────────────┘
```

## UI Integration

### 1. Integrations Column (J/R/C)

Instead of JIRA column, an "Integrations" column with different icons:

```
┌──────────────────────────────────────────────────────────────────┐
│ Project   │ Change      │ Status    │ PID    │ Ctx% │ Int │     │
│ aitools   │ add-auth    │ ● running │ 414720 │ 17%  │ JR  │     │
│ aitools   │ fix-bug     │ ⚡ waiting│ 501501 │ 47%  │ J   │     │
│ other     │ refactor    │ ○ idle    │        │      │ JC  │     │
└──────────────────────────────────────────────────────────────────┘

Int (Integrations) column:
  J = JIRA ticket linked (blue)
  R = Ralph loop active (green=running, yellow=waiting, red=stuck)
  C = Confluence page linked (orange) [future]
```

### 2. Ralph Icon States

| State | Icon | Color | Meaning |
|-------|------|-------|---------|
| Running | R | Green (#22c55e) | Loop actively running |
| Between iterations | R | Yellow (#f59e0b) | Pause between iterations |
| Stuck | R | Red (#ef4444) | Max reached, not done |
| Done | ✓ | Green | Loop completed successfully |

### 3. Row Context Menu Extensions

```
Right-click on worktree row:
├── Open in Zed
├── Open Claude Terminal
├── ─────────────────
├── Start Ralph Loop...     → Dialog for task/options
├── View Ralph Terminal     → Focus the loop terminal (if running)
├── Stop Ralph Loop         → Stop loop, keep work
├── Ralph History...        → Show iteration history dialog
├── ─────────────────
├── Close Worktree
└── Merge to master
```

### 4. Ralph Status Tooltip

Hover on R icon:
```
┌────────────────────────────────┐
│ Ralph Loop: Running            │
│ Iteration: 3/10                │
│ Started: 12:30                 │
│ Capacity used: 15%             │
│ Task: "Implement auth..."      │
│ Done criteria: tasks.md        │
└────────────────────────────────┘
```

### 5. Start Ralph Loop Dialog

Loop can be started from GUI:
```
┌─────────────────────────────────────────────────────────────┐
│  Start Ralph Loop                                     [X]   │
├─────────────────────────────────────────────────────────────┤
│  Worktree: aitools / add-auth                               │
│                                                             │
│  Task Description:                                          │
│  ┌─────────────────────────────────────────────────────────┐│
│  │ Implement authentication based on the spec in          ││
│  │ openspec/changes/add-auth/specs/auth/spec.md           ││
│  └─────────────────────────────────────────────────────────┘│
│                                                             │
│  Done Criteria: [tasks.md complete ▼]                       │
│  Max Iterations: [10]                                       │
│  Capacity Limit: [80%]                                      │
│                                                             │
│  ☐ Auto-create PR when done                                │
│  ☐ Auto-log time to JIRA                                   │
│                                                             │
│  📊 Current capacity: 45% | Available: 35%                 │
│                                                             │
│              [Cancel]  [Start Loop]                         │
└─────────────────────────────────────────────────────────────┘
```

## Terminal Management

### Spawning Terminal

```bash
# Linux (gnome-terminal)
gnome-terminal --title="Ralph: $change_id" -- bash -c "wt-loop run $change_id; exec bash"

# Alternative (xterm)
xterm -title "Ralph: $change_id" -e "wt-loop run $change_id"

# Track the terminal
echo "$TERMINAL_PID" > "$wt_path/.claude/ralph-terminal.pid"
```

### Focusing Terminal from GUI

```python
def focus_ralph_terminal(self, wt_path):
    pid_file = os.path.join(wt_path, ".claude", "ralph-terminal.pid")
    if os.path.exists(pid_file):
        with open(pid_file) as f:
            pid = f.read().strip()
        # Find window by PID and focus
        subprocess.run(["xdotool", "search", "--pid", pid, "windowactivate"])
```

### Initiating Claude Status Display

When `/wt:loop` runs in the Zed terminal, the skill:
1. Spawns the separate terminal
2. Periodically reads loop-state.json
3. Writes status updates to the original terminal

```
> /wt:loop add-auth "Implement auth" --max 10

🔄 Ralph loop started
   Terminal: gnome-terminal (PID 12345)
   Task: Implement auth
   Max iterations: 10

   Status updates:
   [12:30:15] Iteration 1 started
   [12:35:22] Iteration 1 complete, not done yet
   [12:35:25] Iteration 2 started
   [12:42:18] Iteration 2 complete, not done yet
   [12:42:21] Iteration 3 started...

   Use 'wt-loop status add-auth' to check progress
   Use 'wt-loop stop add-auth' to stop the loop
```

## Capacity Tracking

### Usage Tracking via Built-in GUI

The GUI has its own Usage display implementation that reads usage from the Claude Settings API in percentage form. The Ralph loop uses the same mechanism.

**Advantages over external tools (e.g., ccusage):**
- No external dependency
- Already implemented in the GUI
- Percentage-based, not USD
- Real-time updates

### Usage Estimation

Two limits from subscription:
- **5h block** - short-term burst limit (rolling window)
- **Weekly** - long-term weekly limit

```
┌─────────────────────────────────────────────────────────────┐
│  Capacity Check for Ralph Loop                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  5h block usage: 45%     Weekly usage: 30%                  │
│  Capacity limit: 80%                                        │
│  Available (5h): 35%                                        │
│                                                             │
│  Estimated per iteration: ~5-8%                             │
│  Max iterations: 10                                         │
│  Worst case usage: ~80%                                     │
│                                                             │
│  ⚠ May hit 5h block limit before completing                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Tracking Per-Iteration Capacity

```json
// loop-state.json
{
  "iterations": [
    {
      "n": 1,
      "capacity_before": 45,
      "capacity_after": 52
    },
    {
      "n": 2,
      "capacity_before": 52,
      "capacity_after": 58
    }
  ],
  "capacity_limit_pct": 80
}
```

## Loop State File

```
.claude/loop-state.json
{
  "change_id": "add-auth",
  "task": "Implement authentication based on spec",
  "done_criteria": "tasks",
  "max_iterations": 10,
  "current_iteration": 3,
  "status": "running",
  "terminal_pid": 12345,
  "started_at": "2026-01-25T13:00:00Z",
  "iterations": [
    {
      "n": 1,
      "started": "2026-01-25T13:00:00Z",
      "ended": "2026-01-25T13:15:00Z",
      "exit_reason": "natural",
      "commits": ["abc123"],
      "done_check": false,
      "capacity_before_pct": 45,
      "capacity_after_pct": 52
    }
  ],
  "capacity_limit_pct": 80
}
```

## Done Detection Methods

| Method | Syntax | Description | Complexity |
|--------|--------|-------------|------------|
| **tasks-complete** | `--done tasks` | All `- [ ]` → `- [x]` in tasks.md | Simple |
| **tests-pass** | `--done tests` | `npm test` / `pytest` exits 0 | Medium |
| **file-exists** | `--done file:path` | Specific file exists | Simple |
| **grep-match** | `--done grep:pattern:file` | Pattern found in file | Simple |
| **no-todos** | `--done no-todos` | No TODO/FIXME in code | Medium |
| **custom-script** | `--done script:path` | Script exits 0 | Flexible |
| **manual** | `--done manual` | User marks done in GUI | Manual |

**Recommended for V1:** tasks-complete and manual

## wt:loop Skill Command

```bash
/wt:loop <change-id> "<task description>" [options]

Options:
  --done <criteria>       Done detection (default: tasks)
  --max <n>               Max iterations (default: 10)
  --capacity-limit <pct>  Stop if capacity exceeds (default: 80)
  --prompt-file <path>    Use prompt from file
  --auto-pr               Create PR when done
  --auto-jira             Log time to JIRA per iteration
```

## CLI Commands

```bash
# Start a loop (from terminal, not skill)
wt-loop start <change-id> "task description" --max 10 --done tasks

# Check status
wt-loop status [change-id]

# Stop a running loop
wt-loop stop <change-id>

# View iteration history
wt-loop history <change-id>

# Resume with modified prompt
wt-loop resume <change-id> --prompt "Try approach X"

# List all active loops
wt-loop list
```

## Configuration

```json
// ~/.config/wt-tools/gui-config.json
{
  "ralph": {
    "default_max_iterations": 10,
    "default_done_criteria": "tasks",
    "default_capacity_limit_pct": 80,
    "auto_notify": true,
    "terminal_command": "gnome-terminal --title=\"Ralph: {change_id}\" --",
    "prompts_dir": "~/.config/wt-tools/ralph-prompts/"
  }
}
```

## Safety Features

1. **Max iterations** - Hard limit, default 10
2. **Capacity limit** - Stop if capacity exceeds threshold (default 80%)
3. **Stuck detection** - Same error pattern 3x → auto-stop
4. **Manual stop** - GUI button, CLI, or Ctrl+C in terminal
5. **Notification** - Desktop notify on done/stuck
6. **Commit history** - Every iteration's work committed
7. **Terminal visible** - User can see what's happening

## Implementation Phases

### Phase 1: Core Loop (MVP)
- [ ] wt-loop bash script
- [ ] Loop state file management
- [ ] tasks.md done detection
- [ ] Terminal spawning
- [ ] Basic CLI commands (start, stop, status)

### Phase 2: GUI Integration
- [ ] Integrations column (J/R/C)
- [ ] Ralph icon with states
- [ ] Row context menu items
- [ ] Focus terminal action
- [ ] Status tooltip

### Phase 3: Skill Integration
- [ ] /wt:loop skill command
- [ ] Status display in initiating terminal
- [ ] Start Loop dialog in GUI

### Phase 4: Capacity Tracking
- [ ] Per-iteration capacity tracking (via GUI Usage API)
- [ ] Capacity limit enforcement
- [ ] Usage display integration

## Open Questions

1. **Done criteria default:** Is tasks.md parsing general enough?
2. ~~**Cost tracking:** ccusage vs token count estimate?~~ → **Resolved:** Custom GUI Usage display, capacity %
3. **Stuck detection:** What counts as "same error"?
4. **Terminal preference:** gnome-terminal vs configurable?

## References

- [Ralph Claude Code GitHub](https://github.com/frankbria/ralph-claude-code)
- [Ralph Wiggum Explained](https://blog.devgenius.io/ralph-wiggum-explained-the-claude-code-loop-that-keeps-going-3250dcc30809)
- [Claude Code Hooks Docs](https://docs.claude.com/en/docs/claude-code/hooks)
