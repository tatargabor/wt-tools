# Design: Team Sync

## Overview

Git-based team synchronization for the Control Center. Each project uses its own `wt-control` orphan branch, which lives as a hidden worktree in the project root.

## Architecture Decision: Git-based Sync

**Choice:** Dedicated orphan branch in the project repo (Option A from the proposal)

**Rationale:**
- No separate infrastructure (server, DB)
- Existing git access and workflow
- Offline-first: works without network too
- Simple conflict resolution: last-write-wins per member

**Rejected alternatives:**
- WebSocket server: extra infrastructure, complexity
- JIRA/Confluence: API rate limits, not real-time

## Branch & Worktree Structure

```
project-repo/
├── .git/
├── .wt-control/              # Hidden worktree (in gitignore)
│   ├── README.md
│   ├── members/
│   │   ├── john@workstation.json
│   │   └── peter@laptop.json
│   ├── queue/                # Future: shared task queue
│   │   └── .gitkeep
│   └── chat/                 # Future: encrypted messages
│       └── .gitkeep
├── .gitignore                # Contains ".wt-control/"
└── src/...
```

**Why orphan branch?**
- No shared history with code branches
- Doesn't pollute git log
- Separate push/pull from the main repo

**Why hidden worktree?**
- No need for a separate clone
- Automatically alongside the project
- `.gitignore` protects against accidental commits

## Member JSON Format

```json
{
  "name": "john@workstation",          // Unique ID (lowercase, sanitized)
  "display_name": "John@WorkStation",  // Human-readable
  "user": "john",                      // User part (for grouping)
  "hostname": "workstation",
  "status": "active|waiting|idle",     // Aggregated from changes
  "changes": [
    {
      "id": "add-feature",
      "agent_status": "running|waiting|idle",
      "last_activity": "2026-01-25T14:30:00Z"
    }
  ],
  "last_seen": "2026-01-25T14:30:00Z",
  "chat_public_key": "base64...",      // Optional: for encrypted chat
  "chat_key_fingerprint": "a1b2c3d4"   // Optional: first 8 hex of SHA256
}
```

## Sync Mechanism

### Full Sync Flow (--full)

```
1. git pull --rebase origin wt-control
2. Read wt-status --json for current project
3. Generate member JSON with changes
4. Write to members/{name}.json
5. git add -A && git commit (or --amend if same member)
6. git push (or --force-with-lease if amend)
```

### Conflict Detection

```
Input: All member JSONs
Output: [{change_id, members: []}]

Algorithm:
1. Collect all change_ids from all members
2. Group by change_id
3. Filter where count > 1
```

## GUI Integration

### TeamWorker (QThread)

```
Loop:
  if team.enabled:
    result = wt-control-sync --full --json
    emit team_updated(result)
  sleep(sync_interval_ms)
```

### Team Label Display

```
Team: ● Peter, ⚡ Anna | ! conflict-id
       ↑ running    ↑ waiting  ↑ conflict warning
```

### Settings Tab

| Setting | Type | Default |
|---------|------|---------|
| Enable team sync | checkbox | false |
| Auto-sync | checkbox | true |
| Sync interval | spinbox | 30000 ms |
| Initialize button | button | - |

## Security Considerations

### What IS synced (safe)

- Member names (can be aliases)
- Change-IDs (not full branch names)
- Agent status (running/waiting/idle)
- Timestamps
- Chat public keys (if enabled)

### What is NOT synced

- File paths or code content
- API keys or credentials
- JIRA details (story IDs only in change-id)
- Private keys

### Git Access Control

- Same access as project repo
- Branch protection can be applied
- Force-push-with-lease for safety

## File Changes

| File | Purpose |
|------|---------|
| `bin/wt-control-init` | Create orphan branch + hidden worktree |
| `bin/wt-control-sync` | Member status sync + conflict detection |
| `bin/wt-control-chat` | Read/send encrypted chat messages CLI |
| `gui/main.py` | TeamWorker, team_label, settings tab, table rendering |
| `gui/chat_crypto.py` | NaCl encryption/decryption for chat |

## Implementation Notes

### Config Merge Fix

The `Config._merge()` function originally only updated existing keys. This caused `team.projects` not to load from the config file, because it wasn't in DEFAULT_CONFIG. Fix: add new keys from the override.

### Table Re-rendering

With Qt tables, `setSpan()` and `setCellWidget()` are not automatically cleared by `setRowCount()`. Solution: explicit `removeCellWidget()` and `setSpan(r, 0, 1, 1)` on every row before rendering.

### Team Data Triggers Table Refresh

When TeamWorker sends new data, `update_team()` now also calls `refresh_table_display()`, so team buttons and rows appear in project headers.
