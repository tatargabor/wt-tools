## 1. Chat Storage Migration (per-sender outbox)

- [x] 1.1 Modify `bin/wt-control-chat` to write messages to `chat/outbox/{sender}.jsonl` instead of `chat/messages.jsonl`
- [x] 1.2 Modify `bin/wt-control-chat` read command to scan all files in `chat/outbox/` and merge/sort by timestamp
- [x] 1.3 Add migration logic: if `chat/messages.jsonl` exists and `chat/outbox/` doesn't, split into per-sender outbox files and rename original to `messages.jsonl.migrated`
- [x] 1.4 Update `bin/wt-control-chat` git commit to add `chat/outbox/` instead of `chat/messages.jsonl`
- [x] 1.5 Add stdin support for multiline messages: `wt-control-chat send <recipient> -` reads message from stdin

## 2. Batched Messaging (sync-piggybacked delivery)

- [x] 2.1 Modify `bin/wt-control-chat send` to support `--no-push` flag: append to outbox but skip git commit/push
- [x] 2.2 Verify `wt-control-sync` `git add -A` already picks up outbox file changes (it should — test this)
- [x] 2.3 Reduce default team sync interval from 30s to 15s in GUI settings defaults

## 3. Slash Command Namespace Rename

- [x] 3.1 Move `.claude/commands/context/broadcast.md` → `.claude/commands/wt/broadcast.md` (update content to reference `/wt:broadcast`)
- [x] 3.2 Move `.claude/commands/context/status.md` → `.claude/commands/wt/status.md` (update content to reference `/wt:status`)
- [x] 3.3 Remove `.claude/commands/context/` directory
- [x] 3.4 Update CLAUDE.md skill references from `context:*` to `wt:*`

## 4. New Slash Commands (msg, inbox)

- [x] 4.1 Create `.claude/commands/wt/msg.md` — directed messaging command that calls `wt-control-chat send --no-push`
- [x] 4.2 Create `.claude/commands/wt/inbox.md` — inbox reading command that reads local outbox files filtered to current worktree
- [x] 4.3 Update `/wt:status` to show unread message count and suggest `/wt:inbox`

## 5. MCP Tools (send_message, get_inbox)

- [x] 5.1 Add `send_message(recipient, message)` MCP tool to `mcp-server/wt_mcp_server.py` — appends to local outbox file only (no git ops)
- [x] 5.2 Add `get_inbox(since?)` MCP tool to `mcp-server/wt_mcp_server.py` — reads local outbox files and filters
- [x] 5.3 Update `get_team_status()` MCP tool to include broadcast messages from team_status.json cache

## 6. Control Branch History Compaction

- [x] 6.1 Add `--compact` flag to `bin/wt-control-sync`: squash all commits to root, force-push with `--force-with-lease`
- [x] 6.2 Add auto-compact: check commit count during `--full` sync, auto-trigger compaction when exceeding threshold (default 1000)
- [x] 6.3 Add configurable `compact_threshold` to team settings (for testing with low values like 50)
- [x] 6.4 Verify existing recovery mechanism (lines 529-543) handles post-compaction diverged history correctly

## 7. GUI: Team Status Cache Fix

- [x] 7.1 Fix `_write_team_status_cache()` in `gui/control_center/mixins/team.py` to include full `activity` object (not just broadcast field)
- [x] 7.2 Update `gui/dialogs/chat.py` to use per-sender outbox file structure when reading/sending

## 8. GUI: Communication Activity Indicators

- [x] 8.1 Add communication indicator column/area in team worktree rows in `gui/control_center/mixins/table.py`
- [x] 8.2 Show 📡 when team member has broadcast updated within 60 seconds, with tooltip showing broadcast text
- [x] 8.3 Show 💬 when directed message sent/received within 60 seconds, with tooltip showing sender info
- [x] 8.4 Hide indicators when no recent activity (clean default)

## 9. Tests

- [x] 9.1 Test per-sender outbox: write messages from two different senders, verify no file conflicts, verify merged read
- [x] 9.2 Test migration: create legacy messages.jsonl, trigger migration, verify split into outbox files
- [x] 9.3 Test batched delivery: send message with --no-push, verify file exists locally, verify sync picks it up
- [x] 9.4 Test multiline messages: send via stdin, verify preserved in outbox
- [x] 9.5 Test compaction: create N commits, run --compact, verify single commit remains, verify other machine recovery
- [x] 9.6 Test auto-compact threshold: set low threshold (e.g., 5), sync until exceeded, verify auto-compact triggers
- [x] 9.7 Test concurrent compaction: simulate two machines compacting, verify one succeeds and other recovers
- [x] 9.8 Add GUI tests for communication activity indicators in `tests/gui/test_XX_activity_indicators.py`
- [x] 9.9 Test broadcast indicator visibility and tooltip
- [x] 9.10 Test directed message indicator visibility and tooltip
- [x] 9.11 Test no-indicator state when activity is stale

## 10. Documentation

- [x] 10.1 Add use case examples to docs: cross-machine game development (UI on one machine, logic on another)
- [x] 10.2 Add use case: one machine codes, another tests UI, bug reports sent via /wt:msg
- [x] 10.3 Add use case: parallel branch development with Ralph loops coordinated via /wt:status
- [x] 10.4 Document the batch messaging architecture (why zero additional git load)
- [x] 10.5 Document compaction procedure and when to run it
