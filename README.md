# wt-control

Team synchronization branch for wt-tools.

## Structure

- `members/` - Team member status files (one JSON per member)
- `queue/` - Shared task queue (future)
- `chat/` - Team chat messages (future)

## Security

This branch only contains:
- Member names (can be aliases)
- OpenSpec change-ids (not branch names)
- Agent status (running/waiting/idle)
- Timestamps

It does NOT contain:
- File paths or code content
- API keys or credentials
- Detailed JIRA information
