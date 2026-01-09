## Summary

Fix two bugs in the Control Center chat functionality:
1. All project chat buttons open the same project's chat (always the first worktree's project)
2. Messages may not be visible to the recipient (needs investigation)

## Problem

The chat button in each project header calls `show_chat_dialog()` without passing the project name. The function then uses `get_active_project()` which returns `worktrees[0].get("project")` - always the first project in the list, regardless of which chat button was clicked.

Additionally, there are reports that sent messages are not received by the other party, which could be due to git sync issues or encryption key problems.

## Proposed Solution

1. Pass project name from chat button to dialog via lambda
2. Update `show_chat_dialog()` to accept optional project parameter
3. Investigate and fix message delivery issues

## Scope

- `gui/control_center/mixins/table.py` - chat button click handler
- `gui/control_center/mixins/menus.py` - show_chat_dialog function
- `bin/wt-control-chat` - message send/receive (if needed)
- `gui/dialogs/chat.py` - ChatDialog (if needed)

## Out of Scope

- Adding new chat features
- Changing chat encryption scheme
- Multi-project chat view
