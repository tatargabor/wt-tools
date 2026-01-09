## 1. Activity Logging Script

- [x] 1.1 Create `bin/wt-activity` script skeleton
- [x] 1.2 Implement `log` subcommand (called by hook)
- [x] 1.3 Parse TOOL_INPUT JSON to extract file_path
- [x] 1.4 Detect project and change_id from CWD
- [x] 1.5 Write event to JSONL log file
- [x] 1.6 Add ignore patterns support

## 2. Hook Setup

- [x] 2.1 Implement `setup` subcommand
- [x] 2.2 Read existing ~/.claude/settings.json
- [x] 2.3 Add PostToolUse hook for Read/Edit/Write
- [x] 2.4 Write updated settings.json
- [x] 2.5 Add `remove` subcommand to uninstall hooks

## 3. Query Commands

- [x] 3.1 Implement `list` subcommand with date filtering
- [x] 3.2 Implement `files` subcommand for unique file summary
- [x] 3.3 Implement `stats` subcommand for daily statistics
- [x] 3.4 Add JSON output option

## 4. Reconstruct Integration

- [x] 4.1 Add `get_claude_activity_log_for_date` function to wt-jira
- [x] 4.2 Integrate with existing reconstruct mode sources
- [x] 4.3 Map activities to JIRA tickets
- [x] 4.4 Add "claude-activity" to available sources list

## 5. Documentation

- [ ] 5.1 Update README with activity tracking section
- [ ] 5.2 Add setup instructions
- [ ] 5.3 Document hook configuration
