[< Back to README](../README.md)

# Team Sync & Messaging

Cross-machine collaboration **without a central server** — using a `wt-control` git branch for team and machine-level coordination. Each machine syncs agent status automatically. Includes encrypted chat and directed agent-to-agent messaging.

> **Status:** Experimental. Usable but expect rough edges.

> **Note:** Claude Code's Teams feature does not replace this — wt-tools team sync operates at the agent level, enabling different remote machines, users, or local agents to coordinate at a higher level.

## Setup

```bash
# On each machine (one-time)
wt-control-init
wt-control-sync --full
```

Now the Control Center on each machine shows what the other is doing:

```
│  tg@linux/add-api     │ running │ opsx:apply │ 32%  │
│  tg@mac/add-frontend  │ waiting │ opsx:apply │ 55%  │
```

## Agent Messaging

Agents can send direct messages to each other across machines:

```
# Send a message
/wt:msg tg@mac/add-frontend "API endpoints ready, schema at docs/api.md"

# Read incoming messages
/wt:inbox
# → [10:30] tg@linux/add-api: API endpoints ready, schema at docs/api.md

# Broadcast what you're working on
/wt:broadcast "Refactoring checkout flow"

# See all agent activity
/wt:status
```

### CLI Commands

| Command | Description |
|---------|-------------|
| `wt-control-init` | Initialize wt-control team sync branch |
| `wt-control-sync` | Sync member status (pull/push/compact) |
| `wt-control-chat send <to> <msg>` | Send encrypted message |
| `wt-control-chat read` | Read received messages |

### Skills

| Skill | Description |
|-------|-------------|
| `/wt:msg <target> <msg>` | Send message to another agent |
| `/wt:inbox` | Read incoming messages |
| `/wt:broadcast <msg>` | Broadcast what you're working on |
| `/wt:status` | Show agent activity |

## Use Cases

### Cross-machine development

One machine handles backend, another handles frontend:

```
# On linux (backend agent):
/wt:msg tg@mac/game-ui "Game loop API ready at engine.start()"

# On mac (frontend agent):
/wt:inbox
# → [10:30] tg@linux/game-logic: Game loop API ready at engine.start()
```

### Parallel testing with bug reports

One machine codes, another tests. Bug reports go via `/wt:msg`:

```
# Tester agent finds a bug:
/wt:msg tg@mac/feature-x "BUG: Start button unresponsive.
Steps: 1. Click start button
Expected: Game starts
Actual: Nothing happens"

# Developer agent reads and fixes:
/wt:inbox
/wt:msg tg@linux/testing "Fixed in commit def456, please retest"
```

## Batch Messaging Architecture

Messages add **zero additional git operations**. Messages are written to local outbox files and picked up by the next normal sync cycle:

```
Agent sends message:
  send_message("target", "msg")
    → append to chat/outbox/{me}.jsonl  (local file write, <1ms)
    → NO git commit, NO git push

Next sync cycle (every 2 minutes):
  wt-control-sync --full
    → git pull --rebase
    → git add -A  ← picks up outbox changes too
    → git commit --amend
    → git push --force-with-lease
```

Whether an agent sends 0 or 100 messages in a sync window, the sync cost is identical. Per-sender outbox files prevent git merge conflicts — each machine writes only to its own file.

> **Traffic note:** `wt-control-sync` runs git fetch+push on every sync cycle. The default interval is 2 minutes. Lower intervals increase GitHub API traffic — at 15 seconds, that's ~480 git operations/hour per machine. Adjust in Settings > Team Sync interval.

## History Compaction

The `wt-control` branch uses `--amend` to keep history small.

```bash
# Manual compaction
wt-control-sync --compact

# Auto-compaction triggers when commit count exceeds threshold (default: 1000)
# Configure in team_settings.json on the wt-control branch:
# { "compact_threshold": 50 }
```

Recovery after compaction is automatic — when a machine's `git pull --rebase` fails due to force-push, the existing recovery mechanism resets and re-syncs.

## Encrypted Chat

`wt-control-chat` uses NaCl Box (libsodium) for end-to-end encrypted messages between team members.

---

*See also: [Control Center GUI](gui.md) · [MCP Server](mcp-server.md) · [Architecture](architecture.md)*
