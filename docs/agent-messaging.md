# Agent Messaging

Cross-machine agent-to-agent communication via directed messages.

## Use Cases

### Cross-machine game development
One machine handles UI work (gep1-mac), another handles game logic (gep2-linux). Agents coordinate:
```
# On gep1-mac (UI agent):
/wt:msg tg@linux/game-logic "UI component ready, need game loop integration"

# On gep2-linux (logic agent):
/wt:inbox
# → [10:30] tg@mac/game-ui: UI component ready, need game loop integration
/wt:msg tg@mac/game-ui "Game loop API ready at engine.start()"
```

### Parallel testing with bug reports
One machine codes, another tests the UI. Bug reports go via `/wt:msg`:
```
# Tester agent finds a bug:
/wt:msg tg@mac/feature-x "BUG: Start button
Steps: 1. Click start button
Expected: Game starts
Actual: Nothing happens
Screenshot: See commit abc123"

# Developer agent reads it:
/wt:inbox
# Fix and reply:
/wt:msg tg@linux/testing "Fixed in commit def456, please retest"
```

### Parallel branch development with Ralph loops
Multiple Ralph loops coordinated via `/wt:status`:
```
/wt:status
# → AGENT ACTIVITY
# →   feature-auth (my-project)
# →     Skill: wt:loop
# →     Broadcast: "Adding Google OAuth"
# →     Updated: 2 min ago
# →
# →   tg@linux (remote)
# →     Skill: wt:loop fix-payments
# →     Broadcast: "Refactoring checkout flow"
# →     Updated: 30 sec ago
```

## Batch Messaging Architecture

Messages add **zero additional git operations**. Here's why:

### Without messaging
```
Every 15 seconds:
  wt-control-sync --full
    → git pull --rebase
    → update members/{me}.json
    → git add -A
    → git commit --amend
    → git push --force-with-lease

Total: ~480 git ops/hour (2 machines × 240 syncs/hour)
```

### With messaging (0 extra ops)
```
Agent sends message:
  send_message("target", "msg")
    → append to chat/outbox/{me}.jsonl  (local file write, <1ms)
    → return "queued"
    → NO git commit, NO git push

15 seconds later, normal sync:
  wt-control-sync --full
    → git pull --rebase
    → update members/{me}.json
    → git add -A  ← picks up outbox changes too!
    → git commit --amend
    → git push --force-with-lease

Total: still ~480 git ops/hour, regardless of message volume
```

Whether an agent sends 0 or 100 messages in a 15-second window, the sync cost is identical. The `git add -A` already runs as part of the normal sync cycle and picks up any new outbox lines.

### Per-sender outbox files prevent conflicts
Each machine writes only to its own file (`chat/outbox/{sender}.jsonl`). Two machines never modify the same file, so git merge conflicts are eliminated.

## History Compaction

The `wt-control` branch uses `--amend` to keep history small, but over months it still accumulates commits (~100-200/day with 2 machines).

### Manual compaction
```bash
wt-control-sync --compact
```
Squashes all commits into one and force-pushes. Other machines auto-recover on their next sync cycle.

### Auto-compaction
During `--full` sync, if commit count exceeds the threshold (default: 1000), compaction triggers automatically.

### Configurable threshold
Set `compact_threshold` in `team_settings.json` on the `wt-control` branch:
```json
{
  "compact_threshold": 50
}
```
Useful for testing with low values.

### Recovery after compaction
When machine B's `git pull --rebase` fails (due to A's force-push), the existing recovery mechanism kicks in:
1. `git fetch origin wt-control`
2. `git reset --hard origin/wt-control`
3. Re-write own member file
4. `git add` + `git commit` + `git push`

No data is lost — only git history (commit objects) is discarded. The current state of all files is preserved.
