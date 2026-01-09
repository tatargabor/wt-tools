## Why

Cross-machine ping-pong testing between gep1-mac and gep2-linux revealed that agents can only broadcast (one-way announcements) but cannot send directed messages to each other. The existing team-chat infrastructure (E2E encrypted, wt-control-chat CLI) already supports 1:1 messaging but is only accessible from the GUI — agents have no way to use it. Additionally, the single `chat/messages.jsonl` file causes git merge conflicts when multiple machines write simultaneously, the `/context:*` namespace is inconsistent with the `wt:` convention, and there's no visual feedback in the GUI for agent communication activity.

## What Changes

- **Add agent-to-agent directed messaging**: New `/wt:msg <target> <message>` and `/wt:inbox` slash commands that use the existing `wt-control-chat` infrastructure, giving agents the ability to send and receive targeted messages
- **Add MCP tools for messaging**: `send_message()` and `get_inbox()` MCP tools so agents can message programmatically without relying on LLM file parsing — **BREAKING** for `mcp-server` spec (read-only constraint relaxed for messaging)
- **Rename `/context:*` → `/wt:*`**: Move broadcast and status commands to the `wt:` namespace for consistency (`/wt:broadcast`, `/wt:status`)
- **Fix chat storage to prevent git conflicts**: Replace single `chat/messages.jsonl` with per-sender outbox files (`chat/outbox/{sender}.jsonl`) so each machine only writes to its own file
- **Add GUI activity indicators**: Subtle visual indicators on team worktree rows showing recent communication — distinguishing broadcast from directed messages

## Capabilities

### New Capabilities
- `agent-messaging`: Agent-to-agent directed messaging via slash commands and MCP tools. Covers `/wt:msg`, `/wt:inbox`, and MCP `send_message()`/`get_inbox()` tools.

### Modified Capabilities
- `activity-tracking`: Rename `/context:broadcast` → `/wt:broadcast` and `/context:status` → `/wt:status`
- `team-chat`: Fix chat storage from single `messages.jsonl` to per-sender outbox files; add agent-accessible messaging
- `cross-context-visibility`: Add `send_message()` and `get_inbox()` MCP tools (relaxes read-only constraint for messaging)
- `team-sync`: Include broadcast field propagation in team_status.json cache (fix discovered during testing)

## Impact

- **Slash commands**: 4 new/renamed commands in `.claude/commands/wt/` (broadcast.md, status.md, msg.md, inbox.md); remove `.claude/commands/context/`
- **MCP server**: Add `send_message()` and `get_inbox()` tools to `mcp-server/wt_mcp_server.py`
- **Chat CLI**: Modify `bin/wt-control-chat` to support per-sender outbox file structure
- **GUI**: Modify `gui/control_center/mixins/table.py` to show activity indicators on team rows
- **GUI team worker**: Fix broadcast propagation in `gui/control_center/mixins/team.py` `_write_team_status_cache()`
- **Hooks**: Update `.claude/hooks/activity-track.sh` if command names change
- **CLAUDE.md**: Update skill references from context:* to wt:*
- **Migration**: Existing `chat/messages.jsonl` needs one-time migration to outbox structure
