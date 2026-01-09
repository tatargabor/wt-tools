## MODIFIED Requirements

### Requirement: Row Visual Feedback
The system SHALL apply row background color across ALL columns of a worktree row, including columns that use cellWidgets (e.g., the Extra column with Ralph buttons).

#### Scenario: Running row pulse covers all columns
- **WHEN** a worktree row has a running agent and the pulse animation updates
- **THEN** the green pulse background SHALL be visible across every column, including the Extra column with cellWidgets

#### Scenario: Waiting row static color covers all columns
- **WHEN** a worktree row is in waiting state
- **THEN** the yellow/amber background SHALL be visible across every column, including the Extra column

#### Scenario: Attention blink covers all columns
- **WHEN** a worktree row needs attention and the blink timer fires
- **THEN** the blink background color SHALL toggle across every column, including the Extra column with cellWidgets

#### Scenario: Compacting row color covers all columns
- **WHEN** a worktree row is in compacting state
- **THEN** the purple background SHALL be visible across every column, including the Extra column
