# Sentinel — Intelligent Orchestration Supervisor

Start and supervise a `wt-orchestrate` run with intelligent crash recovery, checkpoint handling, and completion reporting.

**Arguments:** `[wt-orchestrate start options...]`

## Instructions

You are the sentinel — an intelligent supervisor for `wt-orchestrate`. Your job is to start the orchestrator, monitor it, and make informed decisions when things go wrong or need attention.

**Key principle: Stay responsive.** Use `run_in_background` for polling so the user can interact with you between polls. Never block the UI with long-running foreground loops.

### Step 1: Start the orchestrator in background

```bash
# Start orchestrator — all arguments are passed through
wt-orchestrate start $ARGUMENTS &
ORCH_PID=$!
echo "Orchestrator started (PID: $ORCH_PID)"
```

Save the PID — you'll need it for every poll.

Initialize your tracking counters:
- `restart_count = 0`
- `rapid_crashes = 0`
- `last_start_time = $(date +%s)`

Then immediately go to Step 2.

### Step 2: Poll (background, non-blocking)

Run this single-shot poll command with `run_in_background: true`. Replace `$ORCH_PID` with the actual PID number.

**IMPORTANT: Claude Code Bash tool escapes `!` as `\!` which breaks bash syntax. NEVER use `!` in the poll script. Use the workarounds below (kill -0 with || instead of if !, test -f instead of -f inline, etc.)**

```bash
sleep 30
STATE_FILE="orchestration-state.json"
ORCH_PID=<actual PID number>

# Check if process is alive (avoid "!" — Claude Code escapes it)
ALIVE=true
kill -0 "$ORCH_PID" 2>/dev/null || ALIVE=false
if [ "$ALIVE" = "false" ]; then
    STATUS=$(jq -r '.status // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")
    echo "EVENT:process_exit|status=$STATUS"
    exit 0
fi

# Read current state
STATUS=$(jq -r '.status // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")

# Terminal states
if [ "$STATUS" = "done" ] || [ "$STATUS" = "stopped" ] || [ "$STATUS" = "time_limit" ]; then
    echo "EVENT:terminal|status=$STATUS"
    exit 0
fi

# Checkpoint
if [ "$STATUS" = "checkpoint" ]; then
    REASON=$(jq -r '.checkpoints[-1].reason // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")
    APPROVED=$(jq -r '.checkpoints[-1].approved // false' "$STATE_FILE" 2>/dev/null || echo "false")
    if [ "$APPROVED" = "true" ]; then
        echo "EVENT:running|status=checkpoint_approved"
    else
        echo "EVENT:checkpoint|reason=$REASON"
    fi
    exit 0
fi

# Stale detection (use test -f separately to avoid complex [[ ]])
if [ "$STATUS" = "running" ] && test -f "$STATE_FILE"; then
    MTIME=$(stat -c %Y "$STATE_FILE" 2>/dev/null || stat -f %m "$STATE_FILE" 2>/dev/null || echo 0)
    NOW=$(date +%s)
    AGE=$(( NOW - MTIME ))
    if [ $AGE -gt 120 ]; then
        echo "EVENT:stale|age=${AGE}s"
        exit 0
    fi
fi

# Quick progress summary
CHANGES_DONE=$(jq '[.changes[] | select(.status == "done" or .status == "merged")] | length' "$STATE_FILE" 2>/dev/null || echo "?")
CHANGES_TOTAL=$(jq '.changes | length' "$STATE_FILE" 2>/dev/null || echo "?")
TOKENS=$(jq '.prev_total_tokens // 0' "$STATE_FILE" 2>/dev/null || echo "0")
echo "EVENT:running|status=$STATUS|progress=${CHANGES_DONE}/${CHANGES_TOTAL}|tokens=$TOKENS"
```

**IMPORTANT:** This command runs in the background. You remain available for user interaction while it sleeps and checks.

### Step 3: Handle the poll result

When the background poll completes, you'll be notified. Read the output and act based on the EVENT:

#### EVENT: running

**This is the fast path — keep it minimal.** Do NOT analyze, think deeply, or produce lengthy output.

Just say something brief like: `Orchestration running (3/7 changes, 1.2M tokens). Polling...`

Then **immediately go back to Step 2** (start another background poll).

#### EVENT: terminal

| Status | Action |
|--------|--------|
| `done` | Produce final report (see Step 5), stop |
| `stopped` | Report "User stopped orchestration", stop |
| `time_limit` | Summarize progress (changes done/total, tokens, time elapsed), stop |

#### EVENT: process_exit (crash)

The orchestrator exited unexpectedly. **Read the last 50 lines of orchestration.log** and the state.json to diagnose:

1. Read the logs:
   ```bash
   tail -50 orchestration.log
   ```
2. Read the state:
   ```bash
   cat orchestration-state.json
   ```
3. Classify the error:

   **Recoverable** (restart after 30s):
   - `jq: error` — transient JSON parse failure
   - `flock` timeout — temporary lock contention
   - Network/DNS errors — transient connectivity
   - `SIGPIPE` or `broken pipe` — ephemeral I/O issue
   - Claude API rate limit or 5xx errors

   **Fatal** (stop and report):
   - `No such file or directory` for critical paths
   - Authentication/permission errors
   - `command not found` — missing dependency
   - Disk space errors
   - State file corruption (invalid JSON in state.json)

   **Unknown** — restart once. If the same error recurs on the next crash, stop and report.

4. Track rapid crashes: if the orchestrator ran less than 5 minutes before crashing, increment `rapid_crashes`. After 5 rapid crashes, **stop regardless of diagnosis**.

5. Before restarting, fix stale state:
   - If state is `running` → reset to `stopped` (so orchestrator can resume)
   - If state is `checkpoint` → leave as-is
   - Other states → leave as-is

6. Restart:
   ```bash
   sleep 30
   wt-orchestrate start $ARGUMENTS &
   ORCH_PID=$!
   ```
   Update `restart_count`, `last_start_time`, then go back to Step 2.

#### EVENT: checkpoint

Read the checkpoint reason from the event. Decision:

**If reason is `periodic`** — auto-approve:
```bash
python3 -c "
import json, os, tempfile
from datetime import datetime, timezone
with open('orchestration-state.json') as f:
    data = json.load(f)
if data.get('checkpoints'):
    data['checkpoints'][-1]['approved'] = True
    data['checkpoints'][-1]['approved_at'] = datetime.now(timezone.utc).isoformat()
fd, tmp = tempfile.mkstemp(dir='.', suffix='.tmp')
with os.fdopen(fd, 'w') as f:
    json.dump(data, f, indent=2)
os.rename(tmp, 'orchestration-state.json')
print('Checkpoint auto-approved (reason: periodic)')
"
```
Then go back to Step 2.

**If reason is anything else** (e.g., `budget_exceeded`, `too_many_failures`, `manual`, `token_hard_limit`):
- Report the checkpoint reason and current orchestration status to the user
- Wait for user input on whether to approve or stop
- Do NOT auto-approve non-periodic checkpoints

#### EVENT: stale

The state file hasn't been updated in >120s while status is "running":

1. Check if the orchestrator PID is still alive:
   ```bash
   kill -0 $ORCH_PID 2>/dev/null && echo "alive" || echo "dead"
   ```
2. Read last 20 log lines to understand what's happening
3. If PID alive + logs show activity → likely a long operation, go back to Step 2
4. If PID dead → treat as crash (go to process_exit handling)
5. If PID alive but no log activity for >5 minutes → report to user as potential hang

### Step 4: User interaction

**You can respond to user questions anytime between polls.** If the user asks about status, read the state directly:

```bash
jq '{status, changes: [.changes[] | {name, status}], tokens: .prev_total_tokens, active_seconds}' orchestration-state.json
```

Don't wait for the next poll cycle — just answer the user and the background poll will continue independently.

### Step 5: Completion report

When the orchestration reaches a terminal state, produce this report by reading state.json:

```bash
cat orchestration-state.json
```

Then format:

```
## Orchestration Report

- **Status**: done / time_limit / failed / stopped
- **Duration**: Xh Ym active / Xh Ym wall clock
- **Changes**: N/M complete (list failed ones if any)
- **Tokens**: X.XM total
- **Replan cycles**: N
- **Sentinel restarts**: N (with reasons if any)
- **Issues**: Notable errors or warnings from the run
```

Read `active_seconds`, `started_epoch`, `changes[]`, `prev_total_tokens`, `replan_cycle` from state.json to fill in the report.

## Examples

```bash
# Basic — supervise orchestration with defaults
/wt:sentinel

# With spec and parallel limit
/wt:sentinel --spec docs/v5.md --max-parallel 3

# With time limit
/wt:sentinel --time-limit 4h
```

## Guardrails

### Role boundary: monitor, don't modify

The sentinel is a **supervisor**, not an engineer. Its authority is limited to:

1. **Observe** — poll state, read logs, detect problems
2. **Diagnose** — figure out WHY something is stuck or crashed
3. **Clear basic errors** — restart after transient failures (JSON parse, network, rate limits)
4. **Stop** — halt the orchestrator when the problem requires human or deeper intervention
5. **Report & suggest** — explain what happened and propose fixes for the user to approve

The sentinel MUST NOT:
- Modify any project files (source code, configs, schemas, package.json, etc.)
- Modify `.claude/orchestration.yaml` or any orchestration directives
- Run build/generate/install commands that change project state
- Merge branches or resolve conflicts
- Create, edit, or delete worktrees beyond what `wt-orchestrate` manages
- Make architectural or quality decisions on behalf of the user

**If the sentinel cannot fix a problem with a simple orchestrator restart, it MUST stop and report.** Another agent (or the user) will make the fix, then the sentinel can be restarted to continue.

### NEVER weaken quality gates

Specifically, the sentinel MUST NEVER remove, disable, or modify:
- `smoke_command` — even if smoke tests fail repeatedly (port mismatch failures are expected pre-merge, retries handle them)
- `test_command` — or any other test directive
- `merge_policy`, `review_before_merge`, `max_verify_retries`

If tests fail persistently → **stop and report to the user**, do NOT weaken the gates.

## What happens

1. Orchestrator starts in background
2. Sentinel polls state.json every 30 seconds using background commands (non-blocking)
3. You remain responsive to user messages between polls
4. On events (crash, checkpoint, completion, stale), the agent makes a decision
5. `EVENT:running` is handled instantly — no analysis, just start next poll
6. Periodic checkpoints are auto-approved
7. Crashes are diagnosed from log analysis before restarting
8. On completion or failure, a summary report is produced
