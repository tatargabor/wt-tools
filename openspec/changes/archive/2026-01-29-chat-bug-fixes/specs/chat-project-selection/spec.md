## ADDED Requirements

### Requirement: Chat button opens correct project
When clicking the chat button in a project header, the chat dialog SHALL open for that specific project.

#### Scenario: Click chat in project A header
- **GIVEN** projects "wt-tools" and "mediapipe" are displayed
- **WHEN** user clicks the chat button in "mediapipe" project header
- **THEN** ChatDialog opens with project="mediapipe"
- **AND** messages shown are from mediapipe's .wt-control/chat/messages.jsonl

#### Scenario: Click chat in project B header
- **GIVEN** projects "wt-tools" and "mediapipe" are displayed
- **WHEN** user clicks the chat button in "wt-tools" project header
- **THEN** ChatDialog opens with project="wt-tools"
- **AND** messages shown are from wt-tools's .wt-control/chat/messages.jsonl

### Requirement: Menu chat uses active project
When opening chat from the menu (not project header), the chat SHALL use the active project.

#### Scenario: Open chat from menu
- **WHEN** user opens chat from Project menu
- **THEN** ChatDialog opens with the active project (first worktree's project)
